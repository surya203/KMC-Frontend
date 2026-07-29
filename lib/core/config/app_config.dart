import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'runtime_env.dart';

class AppConfig {
  AppConfig._();

  /// Optional local override: `flutter run --dart-define=API_BASE_URL=...`
  /// Does not require editing sir's `.env` / `.env.production`.
  static String _define(String key) {
    return switch (key) {
      'API_BASE_URL' => const String.fromEnvironment('API_BASE_URL'),
      'API_PREFIX' => const String.fromEnvironment('API_PREFIX'),
      'ENV' => const String.fromEnvironment('ENV'),
      'RAZORPAY_KEY_ID' => const String.fromEnvironment('RAZORPAY_KEY_ID'),
      _ => '',
    };
  }

  static String _env(String key, String fallback) {
    final fromDefine = _define(key).trim();
    if (fromDefine.isNotEmpty) return fromDefine;

    // Web: prefer window.__ENV__ (web/env-config.js) so Docker/runtime can
    // update API_BASE_URL without a full rebuild — .env is baked into assets.
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
      _env('API_BASE_URL', 'http://200.141.2.90:8001');

  static String get apiPrefix => _env('API_PREFIX', '/api/v1');

  static String get apiV1Url => '$apiBaseUrl$apiPrefix';

  static String get supabaseUrl => _env('SUPABASE_URL', '');

  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY', '');

  static String get razorpayKeyId => _env('RAZORPAY_KEY_ID', '');

  static String get storageBucket {
    final preferred = _env('STORAGE_BUCKET', '');
    if (preferred.isNotEmpty) return preferred;
    return _env('SUPABASE_STORAGE_BUCKET', 'verification-documents');
  }
}
