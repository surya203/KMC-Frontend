import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../network/auth_service.dart';
import 'auth_session.dart';
import 'auth_token_storage.dart';

/// Refreshes the access token using a standalone Dio client (no auth interceptors).
class AuthRefresh {
  AuthRefresh._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Future<AuthTokens?>? _inFlight;

  static Future<AuthTokens?> refreshIfNeeded() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _refresh();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  static Future<AuthTokens?> _refresh() async {
    final refreshToken = AuthService.tokens?.refreshToken;
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200 && response.data != null) {
        final tokens = AuthTokens.fromJson(response.data!);
        AuthService.restoreTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        await AuthTokenStorage.save(tokens);
        return tokens;
      }
    } on DioException {
      await AuthSession.instance.clearSession();
    }
    return null;
  }
}
