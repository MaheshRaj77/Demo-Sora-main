import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// Central API service for all backend HTTP calls with token refresh support.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Wrap low-level http calls to convert SocketException / TimeoutException
  /// into friendly [ApiException]s before they reach the UI.
  Future<http.Response> _safeRequest(Future<http.Response> Function() fn) async {
    try {
      return await fn();
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'The server is taking too long to respond. '
            'It may be waking up — please try again in a moment.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'No internet connection or server unreachable. '
            'Check your connection and try again. (${e.message})',
      );
    }
  }

  /// GET request with optional auth token injection.
  Future<Map<String, dynamic>> get(String endpoint) async {
    final headers = await _headers();
    final response = await _safeRequest(() => http
        .get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers)
        .timeout(ApiConfig.requestTimeout));
    return _handleResponse(response, endpoint, 'GET');
  }

  /// POST request with JSON body.
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool skipAuthHeader = false,
  }) async {
    final headers = await _headers(skipAuthHeader: skipAuthHeader);
    final response = await _safeRequest(() => http
        .post(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.requestTimeout));
    return _handleResponse(response, endpoint, 'POST', body: body, skipAuthHeader: skipAuthHeader);
  }

  /// PUT request with JSON body.
  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await _safeRequest(() => http
        .put(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.requestTimeout));
    return _handleResponse(response, endpoint, 'PUT', body: body);
  }

  /// DELETE request.
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = await _headers();
    final response = await _safeRequest(() => http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: headers,
        )
        .timeout(ApiConfig.requestTimeout));
    return _handleResponse(response, endpoint, 'DELETE');
  }

  /// Multipart POST for file uploads.
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String fieldName,
    File file, {
    Map<String, String>? fields,
  }) async {
    final token = await AuthService().getToken();
    final request =
        http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$endpoint'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await _safeRequest(() async {
      final sr = await request.send().timeout(const Duration(seconds: 60));
      return http.Response.fromStream(sr);
    });
    return _handleResponse(streamedResponse, endpoint, 'MULTIPART');
  }

  /// Build headers with content-type and optional auth token.
  Future<Map<String, String>> _headers({bool skipAuthHeader = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (!skipAuthHeader) {
      final token = await AuthService().getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  /// Parse response and handle errors (including token refresh on 401).
  Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    bool skipAuthHeader = false,
  }) async {
    // Try to parse response
    late Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      responseBody = {'error': 'Failed to parse response'};
    }

    // Success response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    // Handle 401 Unauthorized — try to refresh token
    if (response.statusCode == 401 && !skipAuthHeader) {
      final authService = AuthService();
      final refreshed = await authService.refreshAccessToken();

      if (refreshed) {
        // Retry the original request with new token
        return _retryRequest(endpoint, method, body);
      } else {
        // Token refresh failed, force logout
        await authService.logout();
        throw ApiException(
          statusCode: 401,
          message: 'Session expired. Please log in again.',
        );
      }
    }

    // Handle other errors
    String errorMessage = responseBody['error'] ?? responseBody['message'] ?? 'Unknown error';
    
    if (responseBody['details'] != null && responseBody['details'] is Map) {
      final details = responseBody['details'] as Map;
      final errorList = <String>[];
      for (final value in details.values) {
        if (value is List) {
          errorList.addAll(value.map((e) => e.toString()));
        } else {
          errorList.add(value.toString());
        }
      }
      if (errorList.isNotEmpty) {
        errorMessage += ': ${errorList.join(', ')}';
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
    );
  }

  /// Retry the original request with refreshed token.
  Future<Map<String, dynamic>> _retryRequest(
    String endpoint,
    String method,
    Map<String, dynamic>? body,
  ) async {
    final headers = await _headers();

    http.Response response;

    if (method == 'GET') {
      response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers)
          .timeout(ApiConfig.requestTimeout);
    } else if (method == 'POST') {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.requestTimeout);
    } else if (method == 'PUT') {
      response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.requestTimeout);
    } else if (method == 'DELETE') {
      response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
          )
          .timeout(ApiConfig.requestTimeout);
    } else {
      throw ApiException(statusCode: -1, message: 'Unsupported method: $method');
    }

    // Don't retry again to prevent infinite loops
    late Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      responseBody = {'error': 'Failed to parse response'};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    String errorMessage = responseBody['error'] ?? responseBody['message'] ?? 'Request failed after token refresh';
    
    if (responseBody['details'] != null && responseBody['details'] is Map) {
      final details = responseBody['details'] as Map;
      final errorList = <String>[];
      for (final value in details.values) {
        if (value is List) {
          errorList.addAll(value.map((e) => e.toString()));
        } else {
          errorList.add(value.toString());
        }
      }
      if (errorList.isNotEmpty) {
        errorMessage += ': ${errorList.join(', ')}';
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
    );
  }
}

/// Exception thrown by API calls.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
