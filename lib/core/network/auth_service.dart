import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

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
      accessToken: '${json['access_token']}',
      refreshToken: '${json['refresh_token']}',
      tokenType: '${json['token_type'] ?? 'bearer'}',
    );
  }
}

class UserProfileSummary {
  const UserProfileSummary({
    required this.id,
    required this.fullName,
    required this.batchYear,
    this.verificationStatus,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final int batchYear;
  final String? verificationStatus;
  final String? photoUrl;

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) {
    return UserProfileSummary(
      id: '${json['id']}',
      fullName: '${json['full_name']}',
      batchYear: json['batch_year'] is int
          ? json['batch_year'] as int
          : int.tryParse('${json['batch_year']}') ?? 0,
      verificationStatus: json['verification_status'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class MembershipSummary {
  const MembershipSummary({
    required this.status,
    required this.planName,
    required this.planSlug,
    required this.votingRights,
    this.membershipNumber,
  });

  final String status;
  final String planName;
  final String planSlug;
  final bool votingRights;
  final String? membershipNumber;

  factory MembershipSummary.fromJson(Map<String, dynamic> json) {
    return MembershipSummary(
      status: '${json['status']}',
      planName: '${json['plan_name']}',
      planSlug: '${json['plan_slug']}',
      votingRights: json['voting_rights'] == true,
      membershipNumber: json['membership_number'] as String?,
    );
  }
}

class UserMe {
  const UserMe({
    required this.id,
    required this.email,
    required this.role,
    this.profile,
    this.membership,
  });

  final String id;
  final String email;
  final String role;
  final UserProfileSummary? profile;
  final MembershipSummary? membership;

  factory UserMe.fromJson(Map<String, dynamic> json) {
    return UserMe(
      id: '${json['id']}',
      email: '${json['email']}',
      role: '${json['role']}',
      profile: json['profile'] is Map<String, dynamic>
          ? UserProfileSummary.fromJson(
              json['profile'] as Map<String, dynamic>,
            )
          : null,
      membership: json['membership'] is Map<String, dynamic>
          ? MembershipSummary.fromJson(
              json['membership'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ForgotPasswordResult {
  const ForgotPasswordResult({required this.message, this.debugResetToken});

  final String message;
  final String? debugResetToken;
}

class AuthService {
  AuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      if (response.statusCode == 200 && response.data != null) {
        return AuthTokens.fromJson(response.data!);
      }
      throw const ApiException('Sign in failed. Please try again.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<UserMe> fetchMe() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/me',
      );
      if (response.statusCode == 200 && response.data != null) {
        return UserMe.fromJson(response.data!);
      }
      throw const ApiException('Could not load your profile.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _apiClient.tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiClient.post<Map<String, dynamic>>(
          '${AppConfig.apiPrefix}/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // Clear local session even if revoke fails.
      }
    }
    await _apiClient.tokenStorage.clear();
  }

  Future<ForgotPasswordResult> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/forgot-password',
        data: {'email': email.trim().toLowerCase()},
      );
      if (response.statusCode == 200 && response.data != null) {
        return ForgotPasswordResult(
          message: '${response.data!['message']}',
          debugResetToken: response.data!['debug_reset_token'] as String?,
        );
      }
      throw const ApiException('Could not send reset instructions.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/reset-password',
        data: {'token': token, 'new_password': newPassword},
      );
      if (response.statusCode == 200 && response.data != null) {
        return '${response.data!['message']}';
      }
      throw const ApiException('Could not reset password.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }
}
