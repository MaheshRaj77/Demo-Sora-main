/// ─── Auth Interceptor ───────────────────────────────────────
/// Dio interceptor that:
/// 1. Injects access token into every request header
/// 2. Catches 401 responses
/// 3. Automatically refreshes expired access tokens
/// 4. Retries the failed request with the new token
/// 5. Queues concurrent requests while refreshing (no race conditions)
import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;

  // Queue management for concurrent 401s
  bool _isRefreshing = false;
  final List<_RequestRetry> _pendingRequests = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip token injection for auth endpoints
    final path = options.path;
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh-token')) {
      return handler.next(options);
    }

    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't retry refresh-token endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh-token')) {
      await TokenStorage.clearTokens();
      return handler.next(err);
    }

    // If already refreshing, queue this request
    if (_isRefreshing) {
      final completer = Completer<Response>();
      _pendingRequests.add(_RequestRetry(
        requestOptions: err.requestOptions,
        completer: completer,
      ));

      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    // Start refresh flow
    _isRefreshing = true;

    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await TokenStorage.clearTokens();
        return handler.next(err);
      }

      // Call refresh endpoint with a fresh Dio instance (no interceptors)
      final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final newAccessToken = response.data['data']['accessToken'] as String;
        final newRefreshToken = response.data['data']['refreshToken'] as String;

        await TokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry the original failed request
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);

        // Resolve all queued requests
        for (final pending in _pendingRequests) {
          final opts = pending.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            final resp = await _dio.fetch(opts);
            pending.completer.complete(resp);
          } catch (e) {
            pending.completer.completeError(e);
          }
        }

        _pendingRequests.clear();
        _isRefreshing = false;

        return handler.resolve(retryResponse);
      } else {
        throw DioException(requestOptions: err.requestOptions);
      }
    } catch (e) {
      // Refresh failed — clear tokens and reject all pending
      await TokenStorage.clearTokens();

      for (final pending in _pendingRequests) {
        pending.completer.completeError(err);
      }
      _pendingRequests.clear();
      _isRefreshing = false;

      return handler.next(err);
    }
  }
}

class _RequestRetry {
  final RequestOptions requestOptions;
  final Completer<Response> completer;

  _RequestRetry({
    required this.requestOptions,
    required this.completer,
  });
}
