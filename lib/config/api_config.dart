/**
 * API Configuration
 *
 * Manages API endpoints based on environment (dev/production)
 * Supports multiple platforms with automatic URL selection
 */

import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  /// Environment type
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  /// API Base URL
  static late String baseUrl;

  /// Initialize API configuration based on platform and environment
  static void initialize() {
    // Development environment
    if (kDebugMode || environment == 'development') {
      baseUrl = _getDevBaseUrl();
    }
    // Production environment
    else {
      baseUrl = _getProdBaseUrl();
    }

    debugPrint('🌐 API Base URL initialized: $baseUrl');
  }

  /// Get development Base URL
  static String _getDevBaseUrl() {
    // Android emulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1'; // Default: localhost
    }

    // iOS simulator
    if (Platform.isIOS) {
      return 'http://localhost:3000/api/v1';
    }

    // Physical device (must be on same network)
    // ⚠️  IMPORTANT: Change this to your actual development server IP
    // Example: 'http://192.168.1.100:3000/api/v1'
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api/v1',
    );
  }

  /// Get production Base URL from environment or hardcoded
  static String _getProdBaseUrl() {
    // Use environment variable if available
    const prodUrl = String.fromEnvironment('PROD_API_URL');
    if (prodUrl.isNotEmpty) {
      return prodUrl;
    }

    // Fallback to your production API
    return 'https://api.punova.com/api/v1';
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

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Maximum retries
  static const int maxRetries = 3;

  /// Retry delay multiplier (exponential backoff)
  static const double retryDelayMultiplier = 1.5;
}
