/// ─── API Constants ──────────────────────────────────────────
/// Centralized API configuration. Update [prodBaseUrl] for deployment.
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static const bool isProduction = false;
  static const String prodBaseUrl = 'https://punova-api.onrender.com/api/v1';

  /// Auto-detect base URL based on platform
  static const String _envIp = String.fromEnvironment('BACKEND_IP');

  static String get baseUrl {
    if (isProduction) return prodBaseUrl;
    
    // If a global IP was dynamically injected (e.g., via our custom run script)
    if (_envIp.isNotEmpty) {
      return 'http://$_envIp:3000/api/v1';
    }

    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1'; // Default Android Emulator
    return 'http://localhost:3000/api/v1'; // Default iOS Simulator / Desktop
  }

  // ── Timeouts ────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // ── Endpoints ───────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String fcmToken = '/auth/fcm-token';

  static const String alerts = '/alerts';
  static const String events = '/events';
  static const String circulars = '/circulars';
  static const String forum = '/forum';
  static const String lostFound = '/lost-found';
  static const String timetable = '/timetable';
  static const String services = '/services';
  static const String upload = '/upload';
}
