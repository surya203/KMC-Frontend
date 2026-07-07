import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class EventItem {
  const EventItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.startsAt,
    this.description,
    this.endsAt,
    this.venueName,
    this.venueAddress,
    this.city,
    this.isOnline = false,
    this.meetingUrl,
    this.capacity,
    this.coverImageUrl,
    this.registrationOpen = true,
    this.registeredCount = 0,
    this.isRegistered,
  });

  final String id;
  final String slug;
  final String title;
  final DateTime startsAt;
  final String? description;
  final DateTime? endsAt;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final bool isOnline;
  final String? meetingUrl;
  final int? capacity;
  final String? coverImageUrl;
  final bool registrationOpen;
  final int registeredCount;
  final bool? isRegistered;

  String get displayDate => formatEventDate(startsAt);

  String get displayVenue {
    if (isOnline) return 'Online';
    final parts = [venueName, city].where((e) => e != null && e.isNotEmpty);
    return parts.isEmpty ? 'Venue TBA' : parts.join(', ');
  }

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      venueName: json['venue_name'] as String?,
      venueAddress: json['venue_address'] as String?,
      city: json['city'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      meetingUrl: json['meeting_url'] as String?,
      capacity: json['capacity'] as int?,
      coverImageUrl: json['cover_image_url'] as String?,
      registrationOpen: json['registration_open'] as bool? ?? true,
      registeredCount: json['registered_count'] as int? ?? 0,
      isRegistered: json['is_registered'] as bool?,
    );
  }

  static String formatEventDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class EventRegistrationResult {
  const EventRegistrationResult({
    required this.eventId,
    required this.status,
    required this.registeredCount,
    required this.message,
  });

  final String eventId;
  final String status;
  final int registeredCount;
  final String message;

  factory EventRegistrationResult.fromJson(Map<String, dynamic> json) {
    return EventRegistrationResult(
      eventId: json['event_id'] as String,
      status: json['status'] as String,
      registeredCount: json['registered_count'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}

class MyEventRegistration {
  const MyEventRegistration({
    required this.eventId,
    required this.slug,
    required this.title,
    required this.startsAt,
    required this.status,
    required this.registeredAt,
    this.venueName,
    this.city,
  });

  final String eventId;
  final String slug;
  final String title;
  final DateTime startsAt;
  final String status;
  final DateTime registeredAt;
  final String? venueName;
  final String? city;

  String get displayDate => EventItem.formatEventDate(startsAt);

  String get displayVenue {
    final parts = [venueName, city].where((e) => e != null && e.isNotEmpty);
    return parts.isEmpty ? 'Venue TBA' : parts.join(', ');
  }

  factory MyEventRegistration.fromJson(Map<String, dynamic> json) {
    return MyEventRegistration(
      eventId: json['event_id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      venueName: json['venue_name'] as String?,
      city: json['city'] as String?,
      status: json['status'] as String,
      registeredAt: DateTime.parse(json['registered_at'] as String),
    );
  }
}

class EventsApiService {
  EventsApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EventItem>> fetchEvents({bool upcoming = false}) async {
    final header = AuthService.authorizationHeader;
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events',
        queryParameters: {'upcoming': upcoming},
        options: header != null
            ? Options(headers: {'Authorization': header})
            : null,
      );
      final events = response.data?['events'] as List<dynamic>? ?? [];
      return events
          .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<EventItem> fetchEventBySlug(String slug) async {
    final header = AuthService.authorizationHeader;
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$slug',
        options: header != null
            ? Options(headers: {'Authorization': header})
            : null,
      );
      if (response.data == null) throw Exception('Event not found.');
      return EventItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<EventRegistrationResult> registerForEvent(String eventId) async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in to register for events.');
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$eventId/register',
        options: Options(headers: {'Authorization': header}),
      );
      if (response.data == null) throw Exception('Registration failed.');
      return EventRegistrationResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<MyEventRegistration>> fetchMyRegistrations() async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in to view registrations.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/me',
        options: Options(headers: {'Authorization': header}),
      );
      final items = response.data?['registrations'] as List<dynamic>? ?? [];
      return items
          .map((e) => MyEventRegistration.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<EventRegistrationResult> cancelRegistration(String eventId) async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in to cancel registration.');
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$eventId/register',
        options: Options(headers: {'Authorization': header}),
      );
      if (response.data == null) throw Exception('Cancellation failed.');
      return EventRegistrationResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      return '${detail['detail']}';
    }
    return e.response?.statusMessage ?? 'Events request failed.';
  }
}
