import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

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

class AnnouncementSummary {
  const AnnouncementSummary({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryLabel,
    required this.authorRole,
    required this.authorRoleLabel,
    required this.authorId,
    required this.publishedAt,
    required this.isRead,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String category;
  final String categoryLabel;
  final String authorRole;
  final String authorRoleLabel;
  final String authorId;
  final String publishedAt;
  final bool isRead;
  final String? expiresAt;

  factory AnnouncementSummary.fromJson(Map<String, dynamic> json) {
    return AnnouncementSummary(
      id: '${json['id']}',
      title: '${json['title']}',
      category: '${json['category']}',
      categoryLabel: '${json['category_label']}',
      authorRole: '${json['author_role']}',
      authorRoleLabel: '${json['author_role_label']}',
      authorId: '${json['author_id']}',
      publishedAt: '${json['published_at']}',
      isRead: json['is_read'] == true,
      expiresAt: json['expires_at'] as String?,
    );
  }
}

class AnnouncementDetail extends AnnouncementSummary {
  const AnnouncementDetail({
    required super.id,
    required super.title,
    required super.category,
    required super.categoryLabel,
    required super.authorRole,
    required super.authorRoleLabel,
    required super.authorId,
    required super.publishedAt,
    required super.isRead,
    super.expiresAt,
    required this.body,
    this.contactEnabled = true,
  });

  final String body;
  final bool contactEnabled;

  factory AnnouncementDetail.fromJson(Map<String, dynamic> json) {
    return AnnouncementDetail(
      id: '${json['id']}',
      title: '${json['title']}',
      category: '${json['category']}',
      categoryLabel: '${json['category_label']}',
      authorRole: '${json['author_role']}',
      authorRoleLabel: '${json['author_role_label']}',
      authorId: '${json['author_id']}',
      publishedAt: '${json['published_at']}',
      isRead: json['is_read'] == true,
      expiresAt: json['expires_at'] as String?,
      body: '${json['body']}',
      contactEnabled: json['contact_enabled'] != false,
    );
  }
}

class AnnouncementsService {
  AnnouncementsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<AnnouncementCategory>> fetchCategories() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/categories',
      );
      final items = response.data?['categories'];
      if (response.statusCode == 200 && items is List) {
        return [
          for (final item in items)
            if (item is Map<String, dynamic>)
              AnnouncementCategory.fromJson(item),
        ];
      }
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
    return const [];
  }

  Future<List<AnnouncementSummary>> fetchAnnouncements({
    String? category,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements',
        queryParameters: category == null ? null : {'category': category},
      );
      final items = response.data?['announcements'];
      if (response.statusCode == 200 && items is List) {
        return [
          for (final item in items)
            if (item is Map<String, dynamic>)
              AnnouncementSummary.fromJson(item),
        ];
      }
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
    return const [];
  }

  Future<AnnouncementDetail> fetchById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$id',
      );
      if (response.statusCode == 200 && response.data != null) {
        return AnnouncementDetail.fromJson(response.data!);
      }
      throw const ApiException('Announcement not found.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> createAnnouncement({
    required String title,
    required String body,
    required String category,
    bool publish = true,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements',
        data: {
          'title': title,
          'body': body,
          'category': category,
          'publish': publish,
        },
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> updateAnnouncement({
    required String id,
    String? title,
    String? body,
    String? category,
    bool? publish,
  }) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$id',
        data: {
          'title': ?title,
          'body': ?body,
          'category': ?category,
          'publish': ?publish,
        },
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _apiClient.dio.delete(
        '${AppConfig.apiPrefix}/announcements/$id',
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<String> submitContact({
    required String announcementId,
    required String fullName,
    required String membershipNumber,
    required String contactDetails,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$announcementId/contact',
        data: {
          'full_name': fullName,
          'membership_number': membershipNumber,
          'contact_details': contactDetails,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return '${response.data!['message']}';
      }
      throw const ApiException('Could not send your message.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }
}
