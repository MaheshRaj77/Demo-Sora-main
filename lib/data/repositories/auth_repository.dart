/// ─── Auth Repository ────────────────────────────────────────
/// Data layer for authentication — calls Dio API client and
/// manages token storage. The single source of truth for auth state.
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? department,
    int? year,
    int? semester,
    String? rollNumber,
  }) async {
    final response = await _dio.post(ApiConstants.register, data: {
      'email': email,
      'password': password,
      'fullName': fullName,
      if (department != null) 'department': department,
      if (year != null) 'year': year,
      if (semester != null) 'semester': semester,
      if (rollNumber != null) 'rollNumber': rollNumber,
    });

    return _handleAuthResponse(response);
  }

  /// Login with email + password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });

    return _handleAuthResponse(response);
  }

  /// Refresh access token using stored refresh token
  Future<AuthResult> refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await _dio.post(ApiConstants.refreshToken, data: {
      'refreshToken': refreshToken,
    });

    return _handleAuthResponse(response);
  }

  /// Get current user profile
  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.profile);
    final data = response.data['data'];
    return UserModel.fromJson(data['user']);
  }

  /// Update user profile
  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    final response = await _dio.patch(ApiConstants.profile, data: updates);
    final data = response.data['data'];
    return UserModel.fromJson(data['user']);
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch(ApiConstants.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Logout — blacklist refresh token on server, clear local storage
  Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(ApiConstants.logout, data: {
          'refreshToken': refreshToken,
        });
      }
    } catch (_) {
      // Ignore network errors during logout — always clear local
    } finally {
      await TokenStorage.clearTokens();
      ApiClient.reset(); // Reset Dio instance
    }
  }

  /// Check if user has stored tokens
  Future<bool> isAuthenticated() async {
    return TokenStorage.hasTokens();
  }

  /// Handle auth response — save tokens and return user
  Future<AuthResult> _handleAuthResponse(Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] as Map<String, dynamic>;

      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return AuthResult(user: user, accessToken: accessToken);
    }

    final error = response.data['error'] as Map<String, dynamic>?;
    throw AuthException(
      message: error?['message'] ?? 'Authentication failed',
      code: error?['code'] ?? 'AUTH_ERROR',
    );
  }
}

/// Result of a successful auth operation
class AuthResult {
  final UserModel user;
  final String accessToken;

  const AuthResult({required this.user, required this.accessToken});
}

/// Auth-specific exception
class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException({required this.message, required this.code});

  @override
  String toString() => 'AuthException($code): $message';
}
