import 'package:shared_preferences/shared_preferences.dart';

import '../network/auth_service.dart';

class AuthTokenStorage {
  AuthTokenStorage._();

  static const accessTokenKey = 'auth_access_token';
  static const refreshTokenKey = 'auth_refresh_token';

  static Future<void> save(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, tokens.accessToken);
    await prefs.setString(refreshTokenKey, tokens.refreshToken);
  }

  static Future<AuthTokens?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(accessTokenKey);
    final refresh = prefs.getString(refreshTokenKey);
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
  }
}
