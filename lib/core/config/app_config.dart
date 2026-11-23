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

  static final RegExp _ipv4 = RegExp(
    r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
  );

  static bool _isLocalOrPrivateHost(String host) {
    if (host.isEmpty) return false;
    if (host == 'localhost' || host == '127.0.0.1') return true;
    final match = _ipv4.firstMatch(host);
    if (match == null) return false;
    final a = int.parse(match.group(1)!);
    final b = int.parse(match.group(2)!);
    if (a == 10) return true;
    if (a == 192 && b == 168) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    return false;
  }

  static String get env => _env('ENV', 'development');

  static bool get isDevelopment => env == 'development';

  static bool _isPrivateApiUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return false;
    return _isLocalOrPrivateHost(uri.host);
  }

  static String get apiBaseUrl {
    final configured = _env('API_BASE_URL', '');
    if (!kIsWeb) {
      return configured.isNotEmpty ? configured : 'http://127.0.0.1:8001';
    }
    final host = Uri.base.host;
    if (_isLocalOrPrivateHost(host)) return 'http://$host:8001';
    if (configured.isNotEmpty && !_isPrivateApiUrl(configured)) {
      return configured;
    }
    final origin = Uri.base.origin;
    if (origin.isNotEmpty) return origin;
    return 'http://127.0.0.1:8001';
  }

  static String get apiPrefix => _env('API_PREFIX', '/api/v1');

  static String get apiV1Url => '$apiBaseUrl$apiPrefix';

  static String get supabaseUrl => _env('SUPABASE_URL', '');

  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY', '');

  static String get storageBucket {
    final preferred = _env('STORAGE_BUCKET', '');
    if (preferred.isNotEmpty) return preferred;
    return _env('SUPABASE_STORAGE_BUCKET', 'verification-documents');
  }
}
