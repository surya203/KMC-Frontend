import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'runtime_env.dart';

class AppConfig {
  AppConfig._();

  static String _env(String key, String fallback) {
    // Prefer `.env` for local Flutter so stale web/env-config.js (e.g. :8004)
    // cannot override. Docker/prod usually has empty dotenv and uses window.__ENV__.
    final fromFile = dotenv.env[key];
    if (fromFile != null && fromFile.trim().isNotEmpty) {
      return fromFile.trim();
    }
    return runtimeEnv(key) ?? fallback;
  }

  static String get env => _env('ENV', 'development');

  static bool get isDevelopment => env == 'development';

  static String get apiBaseUrl =>
      _env('API_BASE_URL', 'http://localhost:8005');

  static String get apiPrefix => _env('API_PREFIX', '/api/v1');

  static String get apiV1Url => '$apiBaseUrl$apiPrefix';

  static String get supabaseUrl => _env('SUPABASE_URL', '');

  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY', '');

  static String get razorpayKeyId => _env('RAZORPAY_KEY_ID', '');

  static String get storageBucket =>
      _env('SUPABASE_STORAGE_BUCKET', 'verification-documents');
}
