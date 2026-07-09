import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_exception.dart';
import '../network/auth_service.dart';
import 'token_storage.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({
    TokenStorage? tokenStorage,
    AuthService? authService,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _authService = authService ?? AuthService();

  static AuthSession get instance => authSession;

  static const _draftIdKey = 'registration_draft_id';

  final TokenStorage _tokenStorage;
  final AuthService _authService;

  bool _bootstrapped = false;
  bool _loading = false;
  UserMe? _user;

  bool get bootstrapped => _bootstrapped;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  UserMe? get user => _user;

  AuthUser? get currentUser => _user == null
      ? AuthService.currentUser
      : AuthUser(
          id: _user!.id,
          email: _user!.email,
          role: _user!.role,
        );

  String get memberDestination => isAuthenticated ? '/dashboard' : '/auth';

  AuthService get authService => _authService;

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _loading = true;
    notifyListeners();

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (accessToken != null &&
          accessToken.isNotEmpty &&
          refreshToken != null &&
          refreshToken.isNotEmpty) {
        AuthService.restoreTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        _user = await _authService.fetchMe();
      }
    } catch (_) {
      await _tokenStorage.clear();
      AuthService.clearStaticSession();
      _user = null;
    } finally {
      _bootstrapped = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> initialize() => bootstrap();

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final tokens = await _authService.login(email: email, password: password);
      await saveLogin(tokens);
    } catch (error) {
      _loading = false;
      notifyListeners();
      if (error is ApiException) rethrow;
      throw ApiException('$error');
    }
  }

  Future<void> saveLogin(AuthTokens tokens) async {
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    AuthService.restoreTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    _user = await _authService.fetchMe();
    _loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.logout();
    AuthService.clearStaticSession();
    _user = null;
    notifyListeners();
  }

  Future<void> clearSession() => signOut();

  Future<void> refreshUser() async {
    if (!isAuthenticated) return;
    try {
      _user = await _authService.fetchMe();
      notifyListeners();
    } catch (_) {
      await signOut();
    }
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
}

final AuthSession authSession = AuthSession();
