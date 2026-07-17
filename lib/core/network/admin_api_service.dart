import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../auth/auth_refresh.dart';
import '../auth/auth_session.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.totalMembers,
    required this.activeMemberships,
    required this.pendingVerifications,
    required this.publishedEvents,
    required this.upcomingEvents,
    required this.totalRevenuePaise,
    required this.capturedPayments,
  });

  final int totalMembers;
  final int activeMemberships;
  final int pendingVerifications;
  final int publishedEvents;
  final int upcomingEvents;
  final int totalRevenuePaise;
  final int capturedPayments;

  String get displayRevenue => '₹${(totalRevenuePaise / 100).round()}';

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      totalMembers: json['total_members'] as int? ?? 0,
      activeMemberships: json['active_memberships'] as int? ?? 0,
      pendingVerifications: json['pending_verifications'] as int? ?? 0,
      publishedEvents: json['published_events'] as int? ?? 0,
      upcomingEvents: json['upcoming_events'] as int? ?? 0,
      totalRevenuePaise: json['total_revenue_paise'] as int? ?? 0,
      capturedPayments: json['captured_payments'] as int? ?? 0,
    );
  }
}

class EventEngagement {
  const EventEngagement({
    required this.eventId,
    required this.title,
    required this.slug,
    required this.registeredCount,
    this.capacity,
  });

  final String eventId;
  final String title;
  final String slug;
  final int registeredCount;
  final int? capacity;

  factory EventEngagement.fromJson(Map<String, dynamic> json) {
    return EventEngagement(
      eventId: json['event_id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      registeredCount: json['registered_count'] as int? ?? 0,
      capacity: json['capacity'] as int?,
    );
  }
}

class AnalyticsEngagement {
  const AnalyticsEngagement({
    required this.totalEventRegistrations,
    required this.membersWithEventActivity,
    required this.activeMemberships,
    required this.events,
  });

  final int totalEventRegistrations;
  final int membersWithEventActivity;
  final int activeMemberships;
  final List<EventEngagement> events;

  factory AnalyticsEngagement.fromJson(Map<String, dynamic> json) {
    final raw = json['events'] as List<dynamic>? ?? [];
    return AnalyticsEngagement(
      totalEventRegistrations: json['total_event_registrations'] as int? ?? 0,
      membersWithEventActivity:
          json['members_with_event_activity'] as int? ?? 0,
      activeMemberships: json['active_memberships'] as int? ?? 0,
      events: raw
          .map((e) => EventEngagement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VerificationQueueItem {
  const VerificationQueueItem({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.batchYear,
    required this.verificationStatus,
    this.email,
    this.degree,
    this.organization,
    this.submittedAt,
  });

  final String id;
  final String userId;
  final String fullName;
  final int batchYear;
  final String verificationStatus;
  final String? email;
  final String? degree;
  final String? organization;
  final DateTime? submittedAt;

  factory VerificationQueueItem.fromJson(Map<String, dynamic> json) {
    return VerificationQueueItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      batchYear: json['batch_year'] as int,
      verificationStatus: json['verification_status'] as String,
      email: json['email'] as String?,
      degree: json['degree'] as String?,
      organization: json['organization'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
    );
  }
}

class AdminMemberItem {
  const AdminMemberItem({
    required this.userId,
    required this.email,
    required this.role,
    this.fullName,
    this.batchYear,
    this.membershipStatus,
    this.planName,
    this.verificationStatus,
  });

  final String userId;
  final String email;
  final String role;
  final String? fullName;
  final int? batchYear;
  final String? membershipStatus;
  final String? planName;
  final String? verificationStatus;

  factory AdminMemberItem.fromJson(Map<String, dynamic> json) {
    return AdminMemberItem(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String?,
      batchYear: json['batch_year'] as int?,
      membershipStatus: json['membership_status'] as String?,
      planName: json['plan_name'] as String?,
      verificationStatus: json['verification_status'] as String?,
    );
  }
}

class AdminMembersPage {
  const AdminMembersPage({
    required this.members,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  final List<AdminMemberItem> members;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  factory AdminMembersPage.fromJson(Map<String, dynamic> json) {
    final raw = json['members'] as List<dynamic>? ?? [];
    return AdminMembersPage(
      members: raw
          .map((e) => AdminMemberItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

class AdminEventItem {
  const AdminEventItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.startsAt,
    required this.isOnline,
    required this.registrationOpen,
    required this.registeredCount,
    this.description,
    this.endsAt,
    this.venueName,
    this.venueAddress,
    this.city,
    this.meetingUrl,
    this.capacity,
    this.coverImageUrl,
    this.programs = const [],
    this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final bool isOnline;
  final String? meetingUrl;
  final int? capacity;
  final bool registrationOpen;
  final String? coverImageUrl;
  final List<String> programs;
  final DateTime? publishedAt;
  final int registeredCount;

  bool get isPublished => publishedAt != null;

  factory AdminEventItem.fromJson(Map<String, dynamic> json) {
    final rawPrograms = json['programs'] as List<dynamic>? ?? [];
    return AdminEventItem(
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
      registrationOpen: json['registration_open'] as bool? ?? true,
      coverImageUrl: json['cover_image_url'] as String?,
      programs: rawPrograms.map((e) => '$e').toList(),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      registeredCount: json['registered_count'] as int? ?? 0,
    );
  }
}

class AdminEventRegistrant {
  const AdminEventRegistrant({
    required this.id,
    required this.kind,
    required this.userId,
    required this.status,
    required this.registeredAt,
    this.fullName,
    this.email,
    this.programTracks = const [],
    this.registrationTypes = const [],
    this.title,
    this.mobile,
    this.batchYear,
    this.supportingDocumentUrl,
  });

  final String id;
  final String kind;
  final String userId;
  final String status;
  final DateTime registeredAt;
  final String? fullName;
  final String? email;
  final List<String> programTracks;
  final List<String> registrationTypes;
  final String? title;
  final String? mobile;
  final int? batchYear;
  final String? supportingDocumentUrl;

  String get kindLabel {
    switch (kind) {
      case 'attendance':
        return 'Registration';
      case 'interest':
        return 'Participation';
      case 'registered':
        return 'RSVP';
      default:
        return kind;
    }
  }

  factory AdminEventRegistrant.fromJson(Map<String, dynamic> json) {
    final tracks = json['program_tracks'] as List<dynamic>? ?? [];
    final types = json['registration_types'] as List<dynamic>? ?? [];
    return AdminEventRegistrant(
      id: json['id'] as String,
      kind: json['kind'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      registeredAt: DateTime.parse(json['registered_at'] as String),
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      programTracks: tracks.map((e) => '$e').toList(),
      registrationTypes: types.map((e) => '$e').toList(),
      title: json['title'] as String?,
      mobile: json['mobile'] as String?,
      batchYear: json['batch_year'] as int?,
      supportingDocumentUrl: json['supporting_document_url'] as String?,
    );
  }
}

class AdminEventRegistrationsPage {
  const AdminEventRegistrationsPage({
    required this.eventId,
    required this.eventTitle,
    required this.registrations,
    required this.registeredCount,
    required this.waitlistedCount,
    required this.attendanceCount,
    required this.interestCount,
  });

  final String eventId;
  final String eventTitle;
  final List<AdminEventRegistrant> registrations;
  final int registeredCount;
  final int waitlistedCount;
  final int attendanceCount;
  final int interestCount;

  factory AdminEventRegistrationsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['registrations'] as List<dynamic>? ?? [];
    return AdminEventRegistrationsPage(
      eventId: json['event_id'] as String,
      eventTitle: json['event_title'] as String,
      registrations: raw
          .map((e) => AdminEventRegistrant.fromJson(e as Map<String, dynamic>))
          .toList(),
      registeredCount: json['registered_count'] as int? ?? 0,
      waitlistedCount: json['waitlisted_count'] as int? ?? 0,
      attendanceCount: json['attendance_count'] as int? ?? 0,
      interestCount: json['interest_count'] as int? ?? 0,
    );
  }
}

class AdminApiService {
  AdminApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Options get _authOptions {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in required.');
    return Options(headers: {'Authorization': header});
  }

  Future<Response<Map<String, dynamic>>> _authenticatedGet(
    String path, {
    Map<String, dynamic>? queryParameters,
    int attempt = 0,
  }) async {
    await AuthSession.instance.ensureReady();
    try {
      return await _apiClient.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: _authOptions,
      );
    } on DioException catch (e) {
      if (attempt < 2 && _shouldRetry(e)) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await AuthRefresh.refreshIfNeeded();
        }
        await Future<void>.delayed(
          Duration(milliseconds: 450 * (attempt + 1)),
        );
        return _authenticatedGet(
          path,
          queryParameters: queryParameters,
          attempt: attempt + 1,
        );
      }
      rethrow;
    }
  }

  Future<Response<Map<String, dynamic>>> _authenticatedPatch(
    String path, {
    Map<String, dynamic>? data,
    int attempt = 0,
  }) async {
    await AuthSession.instance.ensureReady();
    try {
      return await _apiClient.patch<Map<String, dynamic>>(
        path,
        data: data,
        options: _authOptions,
      );
    } on DioException catch (e) {
      if (attempt < 2 && _shouldRetry(e)) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await AuthRefresh.refreshIfNeeded();
        }
        await Future<void>.delayed(
          Duration(milliseconds: 450 * (attempt + 1)),
        );
        return _authenticatedPatch(
          path,
          data: data,
          attempt: attempt + 1,
        );
      }
      rethrow;
    }
  }

  Future<AnalyticsOverview> fetchAnalyticsOverview() async {
    try {
      final response = await _authenticatedGet(
        '${AppConfig.apiPrefix}/admin/analytics/overview',
      );
      return AnalyticsOverview.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<AnalyticsEngagement> fetchAnalyticsEngagement() async {
    try {
      final response = await _authenticatedGet(
        '${AppConfig.apiPrefix}/admin/analytics/engagement',
      );
      return AnalyticsEngagement.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<VerificationQueueItem>> fetchVerifications({
    int page = 1,
    int pageSize = 50,
    String status = 'all',
  }) async {
    try {
      final response = await _authenticatedGet(
        '${AppConfig.apiPrefix}/admin/verifications',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'status': status,
        },
      );
      final profiles = response.data?['profiles'] as List<dynamic>? ?? [];
      return profiles
          .map((e) => VerificationQueueItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  @Deprecated('Use fetchVerifications(status: ...)')
  Future<List<VerificationQueueItem>> fetchPendingVerifications({
    int page = 1,
    int pageSize = 20,
  }) {
    return fetchVerifications(page: page, pageSize: pageSize, status: 'pending');
  }

  Future<String> reviewVerification(
    String profileId, {
    required String action,
    String? notes,
  }) async {
    try {
      final response = await _authenticatedPatch(
        '${AppConfig.apiPrefix}/admin/verifications/$profileId',
        data: {
          'action': action,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return response.data?['message'] as String? ?? 'Updated.';
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  bool _shouldRetry(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403 || status == 500) return true;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  Future<AdminMembersPage> fetchMembers({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _authenticatedGet(
        '${AppConfig.apiPrefix}/admin/members',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'page': page,
          'page_size': pageSize,
        },
      );
      return AdminMembersPage.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _authenticatedPatch(
        '${AppConfig.apiPrefix}/admin/users/$userId/role',
        data: {'role': role},
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<AdminEventItem>> fetchEvents() async {
    try {
      await AuthSession.instance.ensureReady();
      final response = await _apiClient.get<dynamic>(
        '${AppConfig.apiPrefix}/admin/events',
        options: _authOptions,
      );
      final raw = response.data;
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => AdminEventItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<AdminEventItem> createEvent(Map<String, dynamic> data) async {
    try {
      await AuthSession.instance.ensureReady();
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/admin/events',
        data: data,
        options: _authOptions,
      );
      return AdminEventItem.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<AdminEventItem> updateEvent(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _authenticatedPatch(
        '${AppConfig.apiPrefix}/admin/events/$eventId',
        data: data,
      );
      return AdminEventItem.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await AuthSession.instance.ensureReady();
      await _apiClient.delete(
        '${AppConfig.apiPrefix}/admin/events/$eventId',
        options: _authOptions,
      );
    } on DioException catch (e) {
      // 204 No Content is success; some clients still raise on empty body.
      if (e.response?.statusCode == 204) return;
      throw Exception(_readDetail(e));
    }
  }

  Future<AdminEventRegistrationsPage> fetchEventRegistrations(
    String eventId,
  ) async {
    try {
      final response = await _authenticatedGet(
        '${AppConfig.apiPrefix}/admin/events/$eventId/registrations',
      );
      return AdminEventRegistrationsPage.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<AdminEventRegistrant> updateEventRegistrationStatus({
    required String eventId,
    required String kind,
    required String registrationId,
    required String status,
  }) async {
    try {
      final response = await _authenticatedPatch(
        '${AppConfig.apiPrefix}/admin/events/$eventId/registrations/$kind/$registrationId',
        data: {'status': status},
      );
      return AdminEventRegistrant.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<String> uploadEventCover(PlatformFile file) async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in required.');
    if (file.bytes == null || file.bytes!.isEmpty) {
      throw Exception('Could not read image file.');
    }

    final mimeType = _mimeTypeFromFilename(file.name);
    try {
      await AuthSession.instance.ensureReady();
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/admin/events/cover',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
            contentType: DioMediaType.parse(mimeType),
          ),
        }),
        options: Options(headers: {'Authorization': header}),
      );
      final url = response.data?['cover_image_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Cover upload failed.');
      }
      return url;
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  String _mimeTypeFromFilename(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String membersExportUrl({String? search}) {
    final qs = search != null && search.trim().isNotEmpty
        ? '?search=${Uri.encodeQueryComponent(search.trim())}'
        : '';
    return '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/admin/members/export$qs';
  }

  String _readDetail(DioException e) {
    final status = e.response?.statusCode;
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      final raw = detail['detail'];
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first is Map && first['msg'] != null) {
          final message = '${first['msg']}';
          if (status != null) return '$message (HTTP $status)';
          return message;
        }
      }
      final message = '$raw';
      if (status != null) return '$message (HTTP $status)';
      return message;
    }
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    if (status == 403) {
      return 'You do not have permission for this admin action (HTTP 403).';
    }
    if (status == 404) {
      return 'Admin resource not found (HTTP 404).';
    }
    if (status == 422) {
      return 'Invalid role or request data (HTTP 422).';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Could not reach the server at ${AppConfig.apiBaseUrl}. '
          'Check that the backend is running on port 8001.';
    }
    if (status == 500) {
      return 'Server error while processing admin request (HTTP 500). '
          'Restart the backend on port 8001 and try again.';
    }
    final fallback = e.message ?? e.response?.statusMessage;
    if (fallback != null && fallback.isNotEmpty) {
      if (status != null) return '$fallback (HTTP $status)';
      return fallback;
    }
    return 'Admin request failed.';
  }
}
