import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AnnouncementCategory {
  const AnnouncementCategory({required this.slug, required this.label});

  final String slug;
  final String label;

  factory AnnouncementCategory.fromJson(Map<String, dynamic> json) {
    return AnnouncementCategory(
      slug: '${json['slug']}',
      label: '${json['label']}',
    );
  }
}

class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryLabel,
    required this.authorRole,
    required this.authorRoleLabel,
    required this.authorId,
    required this.authorName,
    required this.publishedAt,
    required this.isRead,
    this.body,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String category;
  final String categoryLabel;
  final String authorRole;
  final String authorRoleLabel;
  final String authorId;
  final String authorName;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final bool isRead;
  final String? body;

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: '${json['id']}',
      title: '${json['title']}',
      category: '${json['category'] ?? 'alumni_updates'}',
      categoryLabel: '${json['category_label'] ?? 'Alumni Updates'}',
      authorRole: '${json['author_role']}',
      authorRoleLabel: '${json['author_role_label'] ?? json['author_role']}',
      authorId: '${json['author_id']}',
      authorName: '${json['author_name'] ?? 'KMC Alumni'}',
      publishedAt: DateTime.parse('${json['published_at']}'),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse('${json['expires_at']}')
          : null,
      isRead: json['is_read'] == true,
      body: json['body'] as String?,
    );
  }
}

class AnnouncementDetail {
  const AnnouncementDetail({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.categoryLabel,
    required this.authorRole,
    required this.authorRoleLabel,
    required this.authorId,
    required this.isRead,
    this.publishedAt,
    this.expiresAt,
    this.contactEnabled = true,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final String categoryLabel;
  final String authorRole;
  final String authorRoleLabel;
  final String authorId;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool isRead;
  final bool contactEnabled;

  factory AnnouncementDetail.fromJson(Map<String, dynamic> json) {
    return AnnouncementDetail(
      id: '${json['id']}',
      title: '${json['title']}',
      body: '${json['body']}',
      category: '${json['category'] ?? 'alumni_updates'}',
      categoryLabel: '${json['category_label'] ?? 'Alumni Updates'}',
      authorRole: '${json['author_role']}',
      authorRoleLabel: '${json['author_role_label'] ?? json['author_role']}',
      authorId: '${json['author_id']}',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse('${json['published_at']}')
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse('${json['expires_at']}')
          : null,
      isRead: json['is_read'] == true,
      contactEnabled: json['contact_enabled'] != false,
    );
  }
}

class AnnouncementsApiService {
  AnnouncementsApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Options? get _authOptions {
    final header = AuthService.authorizationHeader;
    if (header == null) return null;
    return Options(headers: {'Authorization': header});
  }

  Future<List<AnnouncementCategory>> fetchCategories() async {
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view announcements.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/categories',
        options: options,
      );
      final items = response.data?['categories'] as List<dynamic>? ?? [];
      return items
          .map((e) => AnnouncementCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<AnnouncementItem>> fetchAnnouncements({String? category}) async {
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view announcements.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements',
        queryParameters: category == null ? null : {'category': category},
        options: options,
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
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view announcements.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$id',
        options: options,
      );
      if (response.data == null) throw Exception('Announcement not found.');
      return AnnouncementDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> createAnnouncement({
    required String title,
    required String body,
    required String category,
    bool publish = true,
  }) async {
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to publish announcements.');
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements',
        data: {
          'title': title,
          'body': body,
          'category': category,
          'publish': publish,
        },
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> updateAnnouncement({
    required String id,
    String? title,
    String? body,
    String? category,
    bool? publish,
  }) async {
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to edit announcements.');
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$id',
        data: {
          if (title != null) 'title': title,
          if (body != null) 'body': body,
          if (category != null) 'category': category,
          if (publish != null) 'publish': publish,
        },
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to unpublish announcements.');
    try {
      await _apiClient.delete<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$id',
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<String> submitContact({
    required String announcementId,
    required String fullName,
    required String membershipNumber,
    required String contactDetails,
  }) async {
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to contact the publisher.');
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$announcementId/contact',
        data: {
          'full_name': fullName,
          'membership_number': membershipNumber,
          'contact_details': contactDetails,
        },
        options: options,
      );
      if (response.data?['message'] != null) {
        return '${response.data!['message']}';
      }
      return 'Your message was sent.';
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
          final loc = first['loc'];
          final field = loc is List && loc.isNotEmpty ? '${loc.last}' : 'request';
          return '${first['msg']} ($field)';
        }
      }
      return '$raw';
    }
    if (detail is String && detail.isNotEmpty) return detail;
    return e.response?.statusMessage ?? 'Announcements request failed.';
  }
}
