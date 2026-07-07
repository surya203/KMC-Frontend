import 'package:flutter/foundation.dart';

import '../auth/token_storage.dart';
import '../network/auth_service.dart';
import '../network/api_exception.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({
    TokenStorage? tokenStorage,
    AuthService? authService,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _authService = authService ?? AuthService();

  final TokenStorage _tokenStorage;
  final AuthService _authService;

  bool _bootstrapped = false;
  bool _loading = false;
  UserMe? _user;

  bool get bootstrapped => _bootstrapped;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  UserMe? get user => _user;

  String get memberDestination => isAuthenticated ? '/dashboard' : '/auth';

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _loading = true;
    notifyListeners();

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        _user = await _authService.fetchMe();
      }
    } catch (_) {
      await _tokenStorage.clear();
      _user = null;
    } finally {
      _bootstrapped = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final tokens = await _authService.login(email: email, password: password);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      _user = await _authService.fetchMe();
    } catch (error) {
      _loading = false;
      notifyListeners();
      if (error is ApiException) rethrow;
      throw ApiException('$error');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (!isAuthenticated) return;
    try {
      _user = await _authService.fetchMe();
      notifyListeners();
    } catch (_) {
      await signOut();
    }
  }
}

final AuthSession authSession = AuthSession();
