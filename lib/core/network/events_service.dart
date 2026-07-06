import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class EventSummary {
  const EventSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.startsAt,
    required this.registeredCount,
    this.description,
    this.venueName,
    this.city,
    this.coverImageUrl,
    this.registrationOpen = true,
    this.isOnline = false,
  });

  final String id;
  final String slug;
  final String title;
  final String startsAt;
  final int registeredCount;
  final String? description;
  final String? venueName;
  final String? city;
  final String? coverImageUrl;
  final bool registrationOpen;
  final bool isOnline;

  String get locationLabel {
    if (isOnline) return 'Online';
    final parts = [venueName, city].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Venue TBA' : parts.join(', ');
  }

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    return EventSummary(
      id: '${json['id']}',
      slug: '${json['slug']}',
      title: '${json['title']}',
      startsAt: '${json['starts_at']}',
      registeredCount: json['registered_count'] is int
          ? json['registered_count'] as int
          : int.tryParse('${json['registered_count']}') ?? 0,
      description: json['description'] as String?,
      venueName: json['venue_name'] as String?,
      city: json['city'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      registrationOpen: json['registration_open'] != false,
      isOnline: json['is_online'] == true,
    );
  }
}

class EventDetail extends EventSummary {
  const EventDetail({
    required super.id,
    required super.slug,
    required super.title,
    required super.startsAt,
    required super.registeredCount,
    super.description,
    super.venueName,
    super.city,
    super.coverImageUrl,
    super.registrationOpen,
    super.isOnline,
    this.endsAt,
    this.venueAddress,
    this.meetingUrl,
    this.capacity,
    this.isRegistered,
  });

  final String? endsAt;
  final String? venueAddress;
  final String? meetingUrl;
  final int? capacity;
  final bool? isRegistered;

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    return EventDetail(
      id: '${json['id']}',
      slug: '${json['slug']}',
      title: '${json['title']}',
      startsAt: '${json['starts_at']}',
      registeredCount: json['registered_count'] is int
          ? json['registered_count'] as int
          : int.tryParse('${json['registered_count']}') ?? 0,
      description: json['description'] as String?,
      venueName: json['venue_name'] as String?,
      city: json['city'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      registrationOpen: json['registration_open'] != false,
      isOnline: json['is_online'] == true,
      endsAt: json['ends_at'] as String?,
      venueAddress: json['venue_address'] as String?,
      meetingUrl: json['meeting_url'] as String?,
      capacity: json['capacity'] as int?,
      isRegistered: json['is_registered'] as bool?,
    );
  }
}

class MyEventRegistration {
  const MyEventRegistration({
    required this.eventId,
    required this.title,
    required this.slug,
    required this.startsAt,
    required this.registeredAt,
    required this.registeredCount,
  });

  final String eventId;
  final String title;
  final String slug;
  final String startsAt;
  final String registeredAt;
  final int registeredCount;

  factory MyEventRegistration.fromJson(Map<String, dynamic> json) {
    return MyEventRegistration(
      eventId: '${json['event_id']}',
      title: '${json['title']}',
      slug: '${json['slug']}',
      startsAt: '${json['starts_at']}',
      registeredAt: '${json['registered_at']}',
      registeredCount: json['registered_count'] is int
          ? json['registered_count'] as int
          : int.tryParse('${json['registered_count']}') ?? 0,
    );
  }
}

class EventsService {
  EventsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<EventSummary>> fetchUpcoming() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events',
        queryParameters: {'upcoming': true},
      );
      final events = response.data?['events'];
      if (response.statusCode == 200 && events is List) {
        return [
          for (final item in events)
            if (item is Map<String, dynamic>)
              EventSummary.fromJson(item),
        ];
      }
    } catch (_) {}
    return const [];
  }

  Future<EventDetail> fetchBySlug(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$slug',
      );
      if (response.statusCode == 200 && response.data != null) {
        return EventDetail.fromJson(response.data!);
      }
      throw const ApiException('Event not found.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<List<MyEventRegistration>> fetchMyRegistrations() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/me',
      );
      final events = response.data?['events'];
      if (response.statusCode == 200 && events is List) {
        return [
          for (final item in events)
            if (item is Map<String, dynamic>)
              MyEventRegistration.fromJson(item),
        ];
      }
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
    return const [];
  }

  Future<void> register(String eventId) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$eventId/register',
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> cancelRegistration(String eventId) async {
    try {
      await _apiClient.dio.delete(
        '${AppConfig.apiPrefix}/events/$eventId/register',
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }
}
