import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
  });

  final String id;
  final String email;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static AuthTokens? _tokens;
  static AuthUser? _currentUser;

  static AuthTokens? get tokens => _tokens;
  static AuthUser? get currentUser => _currentUser;
  static bool get isAuthenticated => _tokens != null;

  static void restoreTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _tokens = AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static String? get authorizationHeader {
    final token = _tokens?.accessToken;
    if (token == null) return null;
    return 'Bearer $token';
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200 && response.data != null) {
        _tokens = AuthTokens.fromJson(response.data!);
        return _tokens!;
      }
      throw AuthException('Login failed (${response.statusCode}).');
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map && detail['detail'] != null) {
        throw AuthException('${detail['detail']}');
      }
      throw AuthException(
        e.response?.statusMessage ?? 'Unable to reach the backend.',
      );
    }
  }

  Future<AuthUser> fetchMe({bool allowRefresh = true}) async {
    final header = authorizationHeader;
    if (header == null) {
      throw AuthException('Not signed in.');
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/me',
        options: Options(headers: {'Authorization': header}),
      );
      if (response.statusCode == 200 && response.data != null) {
        _currentUser = AuthUser.fromJson(response.data!);
        return _currentUser!;
      }
      throw AuthException('Could not load profile (${response.statusCode}).');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && allowRefresh) {
        await refresh();
        return fetchMe(allowRefresh: false);
      }
      throw AuthException(
        e.response?.statusMessage ?? 'Unable to load profile.',
      );
    }
  }

  Future<AuthTokens> refresh() async {
    final refreshToken = _tokens?.refreshToken;
    if (refreshToken == null) {
      throw AuthException('No refresh token available.');
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200 && response.data != null) {
        _tokens = AuthTokens.fromJson(response.data!);
        return _tokens!;
      }
      throw AuthException('Session refresh failed (${response.statusCode}).');
    } on DioException catch (e) {
      logout();
      throw AuthException(
        e.response?.statusMessage ?? 'Session expired. Please sign in again.',
      );
    }
  }

  void logout() {
    _tokens = null;
    _currentUser = null;
  }
}
