import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _accessTokenKey = 'kmc_access_token';
  static const _refreshTokenKey = 'kmc_refresh_token';

  Future<SharedPreferences> get _store async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getAccessToken() async {
    return (await _store).getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return (await _store).getString(_refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final store = await _store;
    await store.setString(_accessTokenKey, accessToken);
    await store.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clear() async {
    final store = await _store;
    await store.remove(_accessTokenKey);
    await store.remove(_refreshTokenKey);
  }
}
