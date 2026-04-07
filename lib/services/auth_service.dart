import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'api_service.dart';

/// Manages authentication state — login, register, token storage, and refresh.
/// JWT tokens are stored in FlutterSecureStorage (hardware-backed keystore on
/// Android, Keychain on iOS) to protect them from extraction.
class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // Secure storage for sensitive tokens — uses Android Keystore / iOS Keychain
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _cachedToken;
  String? _cachedRefreshToken;
  Map<String, dynamic>? _cachedUser;
  bool _isGuest = false;
  bool _isRefreshing = false;

  /// Whether the current session is a guest (restricted) session.
  bool get isGuest => _isGuest;

  /// Start a guest session — no backend call, just sets the flag.
  void loginAsGuest() {
    _isGuest = true;
  }

  /// Get stored JWT token from secure storage.
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      _cachedToken = await _secureStorage.read(key: _tokenKey);
    } catch (_) {
      // Fallback to SharedPreferences if secure storage fails (e.g. emulator)
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);
    }
    return _cachedToken;
  }

  /// Get stored refresh token from secure storage.
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    try {
      _cachedRefreshToken = await _secureStorage.read(key: _refreshTokenKey);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      _cachedRefreshToken = prefs.getString(_refreshTokenKey);
    }
    return _cachedRefreshToken;
  }

  /// Check if user is logged in.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Register a new user.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? department,
    String? year,
    String? semester,
    String? rollNumber,
  }) async {
    final response = await ApiService().post('/auth/register', body: {
      'email': email,
      'password': password,
      'full_name': fullName,
      if (department != null && department.isNotEmpty) 'department': department,
      if (year != null && year.isNotEmpty) 'year': year,
      if (semester != null && semester.isNotEmpty) 'semester': semester,
      if (rollNumber != null && rollNumber.isNotEmpty) 'roll_number': rollNumber,
    });

    await _saveSession(response['token'], response['refresh_token'], response['user']);
    return response;
  }

  /// Login with email and password.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService().post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    await _saveSession(response['token'], response['refresh_token'], response['user']);
    return response;
  }

  /// Refresh expired JWT token using refresh token.
  Future<bool> refreshAccessToken() async {
    // Prevent multiple refresh attempts simultane ously
    if (_isRefreshing) {
      return false;
    }

    try {
      _isRefreshing = true;
      final refreshToken = await getRefreshToken();

      if (refreshToken == null) {
        await logout();
        return false;
      }

      final response = await ApiService().post(
        '/auth/refresh-token',
        body: {'refreshToken': refreshToken},
        skipAuthHeader: true, // Don't include Authorization header
      );

      final newAccessToken = response['token'];
      final newRefreshToken = response['refresh_token'];
      if (newAccessToken != null) {
        _cachedToken = newAccessToken;
        _cachedRefreshToken = newRefreshToken;
        try {
          await _secureStorage.write(key: _tokenKey, value: newAccessToken);
          if (newRefreshToken != null) {
            await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);
          }
        } catch (_) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, newAccessToken);
          if (newRefreshToken != null) {
            await prefs.setString(_refreshTokenKey, newRefreshToken);
          }
        }
        return true;
      }

      await logout();
      return false;
    } catch (e) {
      // If refresh fails, force logout
      await logout();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Get current user profile from backend.
  Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiService().get('/auth/profile');
    _cachedUser = response['user'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_cachedUser));
    return response;
  }

  /// Update user profile.
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> updates) async {
    final response = await ApiService().put('/auth/profile', body: updates);
    _cachedUser = response['user'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_cachedUser));
    return response;
  }

  /// Load cached user data stored on the device.
  Future<Map<String, dynamic>?> getCachedUser() async {
    if (_cachedUser != null) return _cachedUser;

    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString(_userKey);
    if (cachedUser == null || cachedUser.isEmpty) {
      return null;
    }

    try {
      _cachedUser = Map<String, dynamic>.from(jsonDecode(cachedUser));
      return _cachedUser;
    } catch (_) {
      return null;
    }
  }

  /// Change password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiService().put('/auth/change-password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  /// Delete user account.
  Future<void> deleteAccount() async {
    await ApiService().delete('/auth/account');
    await logout();
  }

  /// Get cached user data.
  Map<String, dynamic>? get currentUser => _cachedUser;

  /// Logout — clear stored token and guest flag.
  Future<void> logout() async {
    try {
      // Try to notify backend about logout
      await ApiService().post('/auth/logout', body: {});
    } catch (e) {
      // Continue logout even if backend call fails
      debugPrint('Error notifying backend of logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (_) {}
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
    _isGuest = false;
  }

  /// Save token and user — tokens in secure storage, profile in SharedPreferences.
  Future<void> _saveSession(
    String token,
    String refreshToken,
    Map<String, dynamic> user,
  ) async {
    _cachedToken = token;
    _cachedRefreshToken = refreshToken;
    _cachedUser = user;
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      // Fallback for environments where secure storage is unavailable
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    // Non-sensitive user profile goes in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }
}
