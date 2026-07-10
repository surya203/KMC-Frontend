import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

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
    this.programs = const [],
    this.hasInterestRegistration,
    this.hasAttendanceRegistration,
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
  final List<String> programs;
  final bool? hasInterestRegistration;
  final bool? hasAttendanceRegistration;

  String get displayDate => formatEventDate(startsAt);

  String get displayVenue {
    if (isOnline) return 'Online';
    final parts = [venueName, city].where((e) => e != null && e.isNotEmpty);
    return parts.isEmpty ? 'Venue TBA' : parts.join(', ');
  }

  EventItem copyWith({
    int? registeredCount,
    bool? isRegistered,
    bool? hasInterestRegistration,
    bool? hasAttendanceRegistration,
  }) {
    return EventItem(
      id: id,
      slug: slug,
      title: title,
      startsAt: startsAt,
      description: description,
      endsAt: endsAt,
      venueName: venueName,
      venueAddress: venueAddress,
      city: city,
      isOnline: isOnline,
      meetingUrl: meetingUrl,
      capacity: capacity,
      coverImageUrl: coverImageUrl,
      registrationOpen: registrationOpen,
      registeredCount: registeredCount ?? this.registeredCount,
      isRegistered: isRegistered ?? this.isRegistered,
      programs: programs,
      hasInterestRegistration:
          hasInterestRegistration ?? this.hasInterestRegistration,
      hasAttendanceRegistration:
          hasAttendanceRegistration ?? this.hasAttendanceRegistration,
    );
  }

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final rawPrograms = json['programs'] as List<dynamic>? ?? [];
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
      programs: rawPrograms.map((e) => '$e').toList(),
      hasInterestRegistration: json['has_interest_registration'] as bool?,
      hasAttendanceRegistration: json['has_attendance_registration'] as bool?,
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

class EventSubmissionResult {
  const EventSubmissionResult({
    required this.eventId,
    required this.status,
    required this.message,
  });

  final String eventId;
  final String status;
  final String message;

  factory EventSubmissionResult.fromJson(Map<String, dynamic> json) {
    return EventSubmissionResult(
      eventId: json['event_id'] as String,
      status: json['status'] as String,
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
    required this.registrationKind,
    this.venueName,
    this.city,
    this.registrationTypes = const [],
    this.programTracks = const [],
  });

  final String eventId;
  final String slug;
  final String title;
  final DateTime startsAt;
  final String status;
  final DateTime registeredAt;
  final String registrationKind;
  final String? venueName;
  final String? city;
  final List<String> registrationTypes;
  final List<String> programTracks;

  String get displayDate => EventItem.formatEventDate(startsAt);

  String get displayVenue {
    final parts = [venueName, city].where((e) => e != null && e.isNotEmpty);
    return parts.isEmpty ? 'Venue TBA' : parts.join(', ');
  }

  String get displayKind {
    switch (registrationKind) {
      case 'attendance':
        return 'Attendance';
      case 'interest':
        return 'Participation';
      case 'registered':
        return 'RSVP';
      default:
        return registrationKind;
    }
  }

  factory MyEventRegistration.fromJson(Map<String, dynamic> json) {
    final types = json['registration_types'] as List<dynamic>? ?? [];
    final tracks = json['program_tracks'] as List<dynamic>? ?? [];
    return MyEventRegistration(
      eventId: json['event_id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      venueName: json['venue_name'] as String?,
      city: json['city'] as String?,
      status: json['status'] as String,
      registeredAt: DateTime.parse(json['registered_at'] as String),
      registrationKind: json['registration_kind'] as String? ?? 'registered',
      registrationTypes: types.map((e) => '$e').toList(),
      programTracks: tracks.map((e) => '$e').toList(),
    );
  }
}

class EventsApiService {
  EventsApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Options? get _authOptions {
    final header = AuthService.authorizationHeader;
    if (header == null) return null;
    return Options(headers: {'Authorization': header});
  }

  Future<List<EventItem>> fetchEvents({bool upcoming = false}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events',
        queryParameters: {'upcoming': upcoming},
        options: _authOptions,
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
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$slug',
        options: _authOptions,
      );
      if (response.data == null) throw Exception('Event not found.');
      return EventItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<EventRegistrationResult> registerForEvent(String eventId) async {
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to register for events.');
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$eventId/register',
        options: options,
      );
      if (response.data == null) throw Exception('Registration failed.');
      return EventRegistrationResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<EventSubmissionResult> submitAttendance({
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
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to register attendance.');
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$eventId/attendance',
        data: {
          'program_tracks': programTracks,
          'full_name': fullName,
          'email': email,
          if (membershipNumber != null && membershipNumber.isNotEmpty)
            'membership_number': membershipNumber,
          if (batchYear != null) 'batch_year': batchYear,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
          if (city != null && city.isNotEmpty) 'city': city,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        options: options,
      );
      if (response.data == null) throw Exception('Attendance submission failed.');
      return EventSubmissionResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<EventSubmissionResult> submitInterest({
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
    PlatformFile? supportingDocument,
  }) async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in to submit participation.');
    try {
      final formMap = <String, dynamic>{
        'registration_types': registrationTypes.join(','),
        'program_track': programTrack,
        'full_name': fullName,
        'email': email,
        if (membershipNumber != null && membershipNumber.isNotEmpty)
          'membership_number': membershipNumber,
        if (batchYear != null) 'batch_year': batchYear,
        if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
        if (medicalSpecialty != null && medicalSpecialty.isNotEmpty)
          'medical_specialty': medicalSpecialty,
        if (institution != null && institution.isNotEmpty)
          'institution': institution,
        if (presentationCategory != null && presentationCategory.isNotEmpty)
          'presentation_category': presentationCategory,
        if (title != null && title.isNotEmpty) 'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (sponsorOrganization != null && sponsorOrganization.isNotEmpty)
          'sponsor_organization': sponsorOrganization,
        if (sponsorMessage != null && sponsorMessage.isNotEmpty)
          'sponsor_message': sponsorMessage,
      };
      if (supportingDocument?.bytes != null) {
        formMap['supporting_document'] = MultipartFile.fromBytes(
          supportingDocument!.bytes!,
          filename: supportingDocument.name,
        );
      }
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$eventId/interest',
        data: FormData.fromMap(formMap),
        options: Options(headers: {'Authorization': header}),
      );
      if (response.data == null) {
        throw Exception('Participation submission failed.');
      }
      return EventSubmissionResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<MyEventRegistration>> fetchMyRegistrations() async {
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view registrations.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/me',
        options: options,
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
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to cancel registration.');
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/events/$eventId/register',
        options: options,
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
