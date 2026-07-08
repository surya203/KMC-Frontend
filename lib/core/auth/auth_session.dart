import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/auth_service.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _draftIdKey = 'registration_draft_id';

  final AuthService _authService = AuthService();
  bool _initialized = false;

  bool get isAuthenticated => AuthService.isAuthenticated;
  AuthUser? get currentUser => AuthService.currentUser;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_accessTokenKey);
    final refresh = prefs.getString(_refreshTokenKey);
    if (access != null && refresh != null) {
      AuthService.restoreTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      try {
        await _authService.fetchMe();
      } catch (_) {
        await clearSession();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveLogin(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, tokens.accessToken);
    await prefs.setString(_refreshTokenKey, tokens.refreshToken);
    notifyListeners();
  }

  Future<void> clearSession() async {
    _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    notifyListeners();
  }

  Future<String?> getDraftId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_draftIdKey);
  }

  Future<void> saveDraftId(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftIdKey, draftId);
  }

  Future<void> clearDraftId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftIdKey);
  }

  AuthService get authService => _authService;
}
