import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'runtime_env.dart';

class AppConfig {
  AppConfig._();

  static String _env(String key, String fallback) {
    // Web: prefer window.__ENV__ (web/env-config.js) so API_BASE_URL updates
    // without a full rebuild — .env is baked into assets and goes stale.
    // Mobile/desktop: prefer .env; Docker/prod sets window.__ENV__ at runtime.
    if (kIsWeb) {
      final fromRuntime = runtimeEnv(key);
      if (fromRuntime != null && fromRuntime.trim().isNotEmpty) {
        return fromRuntime.trim();
      }
    }
    final fromFile = dotenv.env[key];
    if (fromFile != null && fromFile.trim().isNotEmpty) {
      return fromFile.trim();
    }
    if (!kIsWeb) {
      final fromRuntime = runtimeEnv(key);
      if (fromRuntime != null && fromRuntime.trim().isNotEmpty) {
        return fromRuntime.trim();
      }
    }
    return fallback;
  }

  static String get env => _env('ENV', 'development');

  static bool get isDevelopment => env == 'development';

  static String get apiBaseUrl =>
      _env('API_BASE_URL', 'http://localhost:8001');

  static String get apiPrefix => _env('API_PREFIX', '/api/v1');

  static String get apiV1Url => '$apiBaseUrl$apiPrefix';

  static String get supabaseUrl => _env('SUPABASE_URL', '');

  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY', '');

  static String get razorpayKeyId => _env('RAZORPAY_KEY_ID', '');

  static String get storageBucket =>
      _env('SUPABASE_STORAGE_BUCKET', 'verification-documents');
}
