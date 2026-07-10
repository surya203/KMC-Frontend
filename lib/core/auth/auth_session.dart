import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/auth_service.dart';
import 'auth_token_storage.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _draftIdKey = 'registration_draft_id';

  final AuthService _authService = AuthService();
  bool _initialized = false;

  bool get isAuthenticated => AuthService.isAuthenticated;
  AuthUser? get currentUser => AuthService.currentUser;

  Future<void> initialize() async {
    if (_initialized) return;
    final stored = await AuthTokenStorage.load();
    if (stored != null) {
      AuthService.restoreTokens(
        accessToken: stored.accessToken,
        refreshToken: stored.refreshToken,
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
    await AuthTokenStorage.save(tokens);
    notifyListeners();
  }

  Future<void> clearSession() async {
    _authService.logout();
    await AuthTokenStorage.clear();
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
