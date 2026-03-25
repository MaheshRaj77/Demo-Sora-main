/// ─── Dio API Client ─────────────────────────────────────────
/// Singleton Dio instance configured with:
/// - Base URL auto-detection
/// - Auth interceptor (token injection + refresh)
/// - Logging (debug only)
/// - Timeouts
/// - Error transformation
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Auth interceptor — injects token, handles 401 + refresh
    dio.interceptors.add(AuthInterceptor(dio));

    // Logging interceptor (debug builds only)
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  /// Reset instance (useful for logout/testing)
  static void reset() {
    _instance = null;
  }
}
