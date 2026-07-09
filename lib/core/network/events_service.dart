import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

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
    this.programs = const [],
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
  final List<String> programs;
  final bool registrationOpen;
  final bool isOnline;

  String get locationLabel {
    if (isOnline) return 'Online';
    final parts = [venueName, city].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Venue TBA' : parts.join(', ');
  }

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    final programs = json['programs'];
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
      programs: programs is List
          ? [for (final item in programs) '$item']
          : const [],
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
    super.programs,
    super.registrationOpen,
    super.isOnline,
    this.endsAt,
    this.venueAddress,
    this.meetingUrl,
    this.capacity,
    this.isRegistered,
    this.hasInterestRegistration,
    this.hasAttendanceRegistration,
  });

  final String? endsAt;
  final String? venueAddress;
  final String? meetingUrl;
  final int? capacity;
  final bool? isRegistered;
  final bool? hasInterestRegistration;
  final bool? hasAttendanceRegistration;

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    final programs = json['programs'];
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
      programs: programs is List
          ? [for (final item in programs) '$item']
          : const [],
      registrationOpen: json['registration_open'] != false,
      isOnline: json['is_online'] == true,
      endsAt: json['ends_at'] as String?,
      venueAddress: json['venue_address'] as String?,
      meetingUrl: json['meeting_url'] as String?,
      capacity: json['capacity'] as int?,
      isRegistered: json['is_registered'] as bool?,
      hasInterestRegistration: json['has_interest_registration'] as bool?,
      hasAttendanceRegistration: json['has_attendance_registration'] as bool?,
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
    required this.registrationKind,
    this.registrationTypes = const [],
    this.programTracks = const [],
    this.status = 'submitted',
  });

  final String eventId;
  final String title;
  final String slug;
  final String startsAt;
  final String registeredAt;
  final String registrationKind;
  final List<String> registrationTypes;
  final List<String> programTracks;
  final String status;

  factory MyEventRegistration.fromJson(Map<String, dynamic> json) {
    final types = json['registration_types'];
    final tracks = json['program_tracks'];
    return MyEventRegistration(
      eventId: '${json['event_id']}',
      title: '${json['title']}',
      slug: '${json['slug']}',
      startsAt: '${json['starts_at']}',
      registeredAt: '${json['registered_at']}',
      registrationKind: '${json['registration_kind']}',
      registrationTypes: types is List
          ? [for (final item in types) '$item']
          : const [],
      programTracks: tracks is List
          ? [for (final item in tracks) '$item']
          : const [],
      status: '${json['status']}',
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
            if (item is Map<String, dynamic>) EventSummary.fromJson(item),
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
      final registrations = response.data?['registrations'];
      if (response.statusCode == 200 && registrations is List) {
        return [
          for (final item in registrations)
            if (item is Map<String, dynamic>)
              MyEventRegistration.fromJson(item),
        ];
      }
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
    return const [];
  }

  Future<void> submitInterest({
    required String eventId,
    required List<String> registrationTypes,
    required String programTrack,
    required String fullName,
    required String email,
    String? membershipNumber,
    int? batchYear,
    String? mobile,
    String? medicalSpecialty,
    String? institution,
    String? presentationCategory,
    String? title,
    String? description,
    String? sponsorOrganization,
    String? sponsorMessage,
    List<int>? documentBytes,
    String? documentFilename,
  }) async {
    try {
      final payload = <String, dynamic>{
        'registration_types': registrationTypes.join(','),
        'program_track': programTrack,
        'full_name': fullName,
        'email': email,
        'membership_number': membershipNumber,
        'batch_year': batchYear,
        'mobile': mobile,
        'medical_specialty': medicalSpecialty,
        'institution': institution,
        'presentation_category': presentationCategory,
        'title': title,
        'description': description,
        'sponsor_organization': sponsorOrganization,
        'sponsor_message': sponsorMessage,
      }..removeWhere((_, value) => value == null);

      if (documentBytes != null && documentFilename != null) {
        payload['supporting_document'] = MultipartFile.fromBytes(
          documentBytes,
          filename: documentFilename,
          contentType: _documentContentType(documentFilename),
        );
      }

      final formData = FormData.fromMap(payload);
      await _apiClient.dio.post(
        '${AppConfig.apiPrefix}/events/$eventId/interest',
        data: formData,
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> submitAttendance({
    required String eventId,
    required List<String> programTracks,
    required String fullName,
    required String email,
    String? membershipNumber,
    int? batchYear,
    String? mobile,
    String? city,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'program_tracks': programTracks,
        'full_name': fullName,
        'email': email,
        'membership_number': membershipNumber,
        'batch_year': batchYear,
        'mobile': mobile,
        'city': city,
        'notes': notes,
      }..removeWhere((_, value) => value == null);

      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$eventId/attendance',
        data: payload,
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
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

MediaType _documentContentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  return MediaType('image', 'jpeg');
}
