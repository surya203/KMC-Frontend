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
  Future<void>? _restoreInFlight;

  bool get isAuthenticated => AuthService.isAuthenticated;
  bool get isInitialized => _initialized;
  AuthUser? get currentUser => AuthService.currentUser;

  /// Restores tokens from local storage and starts /auth/me in the background.
  /// Safe to call on every app start. Does not wait on the network.
  Future<void> initialize() async {
    if (_initialized) return;
    final stored = await AuthTokenStorage.load();
    if (stored != null) {
      AuthService.restoreTokens(
        accessToken: stored.accessToken,
        refreshToken: stored.refreshToken,
      );
      _restoreInFlight = _restoreSession();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _restoreSession() async {
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
          continue;
        }
        // Keep stored tokens on transient network errors; screens can retry.
        notifyListeners();
        return;
      }
    }
    notifyListeners();
  }

  /// Ensures startup auth restore has finished before protected API calls.
  /// A down API must not freeze the splash: wait at most a few seconds.
  Future<void> ensureReady() async {
    if (!_initialized) {
      await initialize();
    }
    if (!AuthService.isAuthenticated) return;

    if (AuthService.currentUser != null) return;

    final pending = _restoreInFlight;
    if (pending != null) {
      try {
        await pending.timeout(const Duration(seconds: 4));
      } catch (_) {}
      if (AuthService.currentUser != null || !AuthService.isAuthenticated) {
        return;
      }
    }

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

  Future<void> deleteAccount({required String password}) async {
    await _authService.deleteAccount(password: password);
  }

  /// Loads `/auth/me` into memory and notifies listeners (role-gated UI).
  Future<AuthUser?> refreshCurrentUser() async {
    if (!AuthService.isAuthenticated) return null;
    try {
      final user = await _authService.fetchMe(allowRefresh: true);
      notifyListeners();
      return user;
    } on AuthException {
      return AuthService.currentUser;
    }
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
