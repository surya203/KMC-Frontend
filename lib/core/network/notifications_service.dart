import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
    this.metadata = const {},
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;
  final String? referenceType;
  final String? referenceId;
  final Map<String, dynamic> metadata;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return AppNotification(
      id: '${json['id']}',
      type: '${json['type']}',
      title: '${json['title']}',
      body: '${json['body']}',
      isRead: json['is_read'] == true,
      createdAt: '${json['created_at']}',
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      metadata: metadata is Map<String, dynamic> ? metadata : const {},
    );
  }

  String? get eventSlug => metadata['event_slug'] as String?;
}

class NotificationsService {
  NotificationsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<({List<AppNotification> items, int unreadCount})> fetchAll() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/notifications',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final rows = data['notifications'];
        return (
          items: rows is List
              ? [
                  for (final item in rows)
                    if (item is Map<String, dynamic>)
                      AppNotification.fromJson(item),
                ]
              : <AppNotification>[],
          unreadCount: data['unread_count'] is int
              ? data['unread_count'] as int
              : int.tryParse('${data['unread_count']}') ?? 0,
        );
      }
      throw const ApiException('Could not load notifications.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/notifications/$notificationId/read',
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }
}
