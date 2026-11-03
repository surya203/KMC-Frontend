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

  /// On local/LAN web, always call the API on the same host as the page.
  /// Stops login breaking when Wi‑Fi DHCP changes the machine IP.
  static String? _sameHostApiBaseUrl() {
    if (!kIsWeb) return null;
    final host = Uri.base.host;
    if (host.isEmpty) return null;
    final isLocalName = host == 'localhost' || host == '127.0.0.1';
    final isIpv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
    if (!isLocalName && !isIpv4) return null;
    return 'http://$host:8001';
  }

  static String get env => _env('ENV', 'development');

  static bool get isDevelopment => env == 'development';

  static String get apiBaseUrl {
    final sameHost = _sameHostApiBaseUrl();
    if (sameHost != null) return sameHost;
    return _env('API_BASE_URL', 'http://192.168.0.10:8001');
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
