import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AnnouncementSummary {
  const AnnouncementSummary({
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
  final String publishedAt;
  final bool isRead;
  final String? expiresAt;

  factory AnnouncementSummary.fromJson(Map<String, dynamic> json) {
    return AnnouncementSummary(
      id: '${json['id']}',
      title: '${json['title']}',
      authorRole: '${json['author_role']}',
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
    required super.authorRole,
    required super.publishedAt,
    required super.isRead,
    super.expiresAt,
    required this.body,
  });

  final String body;

  factory AnnouncementDetail.fromJson(Map<String, dynamic> json) {
    return AnnouncementDetail(
      id: '${json['id']}',
      title: '${json['title']}',
      authorRole: '${json['author_role']}',
      publishedAt: '${json['published_at']}',
      isRead: json['is_read'] == true,
      expiresAt: json['expires_at'] as String?,
      body: '${json['body']}',
    );
  }
}

class AnnouncementsService {
  AnnouncementsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<AnnouncementSummary>> fetchAnnouncements() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements',
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
    required String authorRole,
    bool publish = true,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements',
        data: {
          'title': title,
          'body': body,
          'author_role': authorRole,
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
    bool? publish,
  }) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/announcements/$id',
        data: {
          'title': ?title,
          'body': ?body,
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
}
