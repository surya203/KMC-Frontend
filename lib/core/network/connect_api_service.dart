import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import '../config/app_config.dart';
import 'announcements_api_service.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ConnectOfficer {
  const ConnectOfficer({
    required this.userId,
    required this.email,
    required this.role,
    required this.roleLabel,
    required this.initials,
    this.fullName,
  });

  final String userId;
  final String email;
  final String role;
  final String roleLabel;
  final String initials;
  final String? fullName;

  String get displayName => fullName ?? email.split('@').first;

  factory ConnectOfficer.fromJson(Map<String, dynamic> json) {
    return ConnectOfficer(
      userId: '${json['user_id']}',
      email: '${json['email']}',
      role: '${json['role']}',
      roleLabel: '${json['role_label']}',
      initials: '${json['initials']}',
      fullName: json['full_name'] as String?,
    );
  }
}

class ConnectApiService {
  ConnectApiService({
    ApiClient? apiClient,
    AnnouncementsApiService? announcementsApi,
  })  : _apiClient = apiClient ?? ApiClient(),
        _announcementsApi = announcementsApi ?? AnnouncementsApiService();

  final ApiClient _apiClient;
  final AnnouncementsApiService _announcementsApi;

  static const generalGroupCategory = 'general_group';

  Options? get _authOptions {
    final header = AuthService.authorizationHeader;
    if (header == null) return null;
    return Options(headers: {'Authorization': header});
  }

  Future<List<AnnouncementItem>> fetchGeneralGroupPosts() async {
    await AuthSession.instance.ensureReady();
    return _announcementsApi.fetchAnnouncements(category: generalGroupCategory);
  }

  Future<void> postGeneralGroupMessage(String body) async {
    await AuthSession.instance.ensureReady();
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final title = trimmed.length > 80 ? '${trimmed.substring(0, 77)}...' : trimmed;
    await _announcementsApi.createAnnouncement(
      title: title,
      body: trimmed,
      category: generalGroupCategory,
      publish: true,
    );
  }

  Future<List<ConnectOfficer>> fetchOfficers() async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view officers.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/officers',
        options: options,
      );
      final items = response.data?['officers'] as List<dynamic>? ?? [];
      return items
          .map((e) => ConnectOfficer.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      final raw = detail['detail'];
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first is Map && first['msg'] != null) {
          return '${first['msg']}';
        }
      }
      return '$raw';
    }
    if (detail is String && detail.isNotEmpty) return detail;
    final status = e.response?.statusCode;
    if (status == 404) {
      return 'Connect API not found. Restart the backend on port 8001 with the latest code.';
    }
    return e.response?.statusMessage ?? 'Connect request failed.';
  }
}
