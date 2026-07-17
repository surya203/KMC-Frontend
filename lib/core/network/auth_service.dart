import 'package:dio/dio.dart';

import '../auth/auth_refresh.dart';
import '../config/app_config.dart';

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
    this.isEcMember = false,
    this.fullName,
    this.batchYear,
    this.membershipNumber,
  });

  final String id;
  final String email;
  final String role;
  /// True for Executive Committee accounts (independent of [role]).
  final bool isEcMember;
  final String? fullName;
  final int? batchYear;
  final String? membershipNumber;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final membership = json['membership'];
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isEcMember: json['is_ec_member'] as bool? ?? false,
      fullName: profile is Map<String, dynamic>
          ? profile['full_name'] as String?
          : null,
      batchYear: profile is Map<String, dynamic>
          ? profile['batch_year'] as int?
          : null,
      membershipNumber: membership is Map<String, dynamic>
          ? membership['membership_number'] as String?
          : null,
    );
  }
}

class AuthException implements Exception {
  AuthException(this.message, {this.retryAfterSeconds});

  final String message;
  final int? retryAfterSeconds;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

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
    String? email,
    String? password,
    String? phone,
    String? phoneCountryCode,
    String? membershipNumber,
  }) async {
    final Map<String, dynamic> data;
    if (email != null && email.isNotEmpty) {
      data = {'email': email, 'password': password};
    } else if (phone != null && phone.isNotEmpty) {
      data = {
        'phone': phone,
        'phone_country_code': phoneCountryCode ?? '+91',
        'password': password,
      };
    } else {
      data = {
        'membership_number': membershipNumber,
        'password': password,
      };
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/login',
        data: data,
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
      final response = await _dio.get<Map<String, dynamic>>(
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
        try {
          await refresh();
        } on AuthException {
          rethrow;
        }
        return fetchMe(allowRefresh: false);
      }
      final detail = e.response?.data;
      if (detail is Map && detail['detail'] != null) {
        throw AuthException('${detail['detail']}');
      }
      throw AuthException(
        e.response?.statusMessage ?? 'Unable to load profile.',
      );
    }
  }

  Future<AuthTokens> refresh() async {
    final tokens = await AuthRefresh.refreshIfNeeded();
    if (tokens != null) return tokens;
    throw AuthException('Session expired. Please sign in again.');
  }

  void logout() {
    _tokens = null;
    _currentUser = null;
  }

  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/forgot-password',
        data: {'email': email},
      );
      final data = response.data;
      if (data == null) {
        throw AuthException('Could not send reset instructions.');
      }
      return ForgotPasswordResult(
        message: data['message'] as String? ??
            'Check your email for the 6-digit reset code.',
      );
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map) {
        final nested = detail['detail'];
        if (nested is Map) {
          final message = nested['message'] as String? ??
              'Unable to send reset code.';
          final retry = nested['retry_after_seconds'];
          throw AuthException(
            message,
            retryAfterSeconds: retry is int ? retry : int.tryParse('$retry'),
          );
        }
        if (nested != null) {
          throw AuthException('$nested');
        }
      }
      throw AuthException(
        e.response?.statusMessage ?? 'Unable to reach the backend.',
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map && detail['detail'] != null) {
        throw AuthException('${detail['detail']}');
      }
      throw AuthException(
        e.response?.statusMessage ?? 'Unable to reset password.',
      );
    }
  }
}

class ForgotPasswordResult {
  const ForgotPasswordResult({required this.message});

  final String message;
}
