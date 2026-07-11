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
  bool get isInitialized => _initialized;
  AuthUser? get currentUser => AuthService.currentUser;

  /// Restores tokens and user from storage. Safe to call on every app start.
  Future<void> initialize() async {
    if (_initialized) return;
    final stored = await AuthTokenStorage.load();
    if (stored != null) {
      AuthService.restoreTokens(
        accessToken: stored.accessToken,
        refreshToken: stored.refreshToken,
      );
      await _restoreSession();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _authService.fetchMe(allowRefresh: true);
        return;
      } on AuthException {
        try {
          await _authService.refresh();
          await _authService.fetchMe(allowRefresh: false);
          return;
        } on AuthException {
          await clearSession();
          return;
        } catch (_) {
          if (attempt == 2) return;
        }
      } catch (_) {
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 350 * (attempt + 1)),
          );
          continue;
        }
        // Keep stored tokens on transient network errors; screens can retry.
        return;
      }
    }
  }

  /// Ensures startup auth restore has finished before protected API calls.
  Future<void> ensureReady() async {
    if (!_initialized) {
      await initialize();
    }
    if (!AuthService.isAuthenticated) return;

    if (AuthService.currentUser != null) return;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _authService.fetchMe(allowRefresh: true);
        notifyListeners();
        return;
      } on AuthException {
        try {
          await _authService.refresh();
          await _authService.fetchMe(allowRefresh: false);
          notifyListeners();
          return;
        } on AuthException {
          await clearSession();
          return;
        } catch (_) {
          if (attempt == 2) return;
        }
      } catch (_) {
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 350 * (attempt + 1)),
          );
        }
      }
    }
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
