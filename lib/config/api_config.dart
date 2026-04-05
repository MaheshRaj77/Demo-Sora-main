/**
 * API Configuration
 *
 * Manages API endpoints based on environment (dev/production)
 * Supports multiple platforms with automatic URL selection
 *
 * For local development:
 *   - Run backend: cd PUnova-backend-main && npm run dev
 *   - Default: http://localhost:3000/api/v1
 *   - Custom IP: flutter run --dart-define=BACKEND_IP=192.168.x.x
 */

import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Environment type
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Custom backend IP (pass via --dart-define=BACKEND_IP=192.168.x.x)
  static const String _customIp = String.fromEnvironment('BACKEND_IP');

  /// API Base URL
  static late String baseUrl;

  /// Initialize API configuration based on platform and environment
  static void initialize() {
    // Production environment (explicit opt-in)
    if (environment == 'production' && !kDebugMode) {
      baseUrl = _getProdBaseUrl();
    }
    // Development (default)
    else {
      baseUrl = _getDevBaseUrl();
    }

    debugPrint('🌐 API Base URL initialized: $baseUrl');
  }

  /// Get development Base URL — connects to local backend
  static String _getDevBaseUrl() {
    // If custom IP was passed via --dart-define
    if (_customIp.isNotEmpty) {
      return 'http://$_customIp:3000/api/v1';
    }

    // Default: use the live Render backend instead of local IP
    // This allows the app to work uniformly everywhere (and on your friend's phone)
    return 'https://punova-backend-main.onrender.com/api/v1';
  }

  /// Get production Base URL from environment or hardcoded
  static String _getProdBaseUrl() {
    const prodUrl = String.fromEnvironment('PROD_API_URL');
    if (prodUrl.isNotEmpty) {
      return prodUrl;
    }
    return 'https://punova-backend-main.onrender.com/api/v1';
  }

  /// API Endpoints
  static const Map<String, String> endpoints = {
    // Auth
    'register': '/auth/register',
    'login': '/auth/login',
    'logout': '/auth/logout',
    'refresh_token': '/auth/refresh-token',
    'profile': '/auth/profile',
    'change_password': '/auth/change-password',
    'delete_account': '/auth/account',

    // Resources
    'circulars': '/circulars',
    'events': '/events',
    'forum': '/forum',
    'alerts': '/alerts',
    'results': '/results',
    'timetable': '/timetable',
    'services': '/services',
    'lost_found': '/lost-found',
    'reports': '/reports',
  };

  /// Get full endpoint URL
  static String getUrl(String endpoint) {
    final path = endpoints[endpoint] ?? endpoint;
    return '$baseUrl$path';
  }

  /// Request timeout duration — 60s to handle Render free tier cold starts
  static const Duration requestTimeout = Duration(seconds: 60);

  /// Maximum retries
  static const int maxRetries = 3;

  /// Retry delay multiplier (exponential backoff)
  static const double retryDelayMultiplier = 1.5;
}
