import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.authorRole,
    required this.publishedAt,
    required this.isRead,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String authorRole;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final bool isRead;

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id'] as String,
      title: json['title'] as String,
      authorRole: json['author_role'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

class AnnouncementDetail {
  const AnnouncementDetail({
    required this.id,
    required this.title,
    required this.body,
    required this.authorRole,
    required this.isRead,
    this.publishedAt,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String body;
  final String authorRole;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool isRead;

  factory AnnouncementDetail.fromJson(Map<String, dynamic> json) {
    return AnnouncementDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      authorRole: json['author_role'] as String,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

class AnnouncementsApiService {
  AnnouncementsApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AnnouncementItem>> fetchAnnouncements() async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in to view announcements.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements',
        options: Options(headers: {'Authorization': header}),
      );
      final items = response.data?['announcements'] as List<dynamic>? ?? [];
      return items
          .map((e) => AnnouncementItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<AnnouncementDetail> fetchAnnouncementById(String id) async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in to view announcements.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$id',
        options: Options(headers: {'Authorization': header}),
      );
      if (response.data == null) throw Exception('Announcement not found.');
      return AnnouncementDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      return '${detail['detail']}';
    }
    return e.response?.statusMessage ?? 'Announcements request failed.';
  }
}
