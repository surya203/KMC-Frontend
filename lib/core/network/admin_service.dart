import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'events_service.dart';

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

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    int i(String key) => json[key] is int
        ? json[key] as int
        : int.tryParse('${json[key]}') ?? 0;
    return AnalyticsOverview(
      totalMembers: i('total_members'),
      activeMemberships: i('active_memberships'),
      pendingVerifications: i('pending_verifications'),
      publishedEvents: i('published_events'),
      upcomingEvents: i('upcoming_events'),
      totalRevenuePaise: i('total_revenue_paise'),
      capturedPayments: i('captured_payments'),
    );
  }
}

class VerificationItem {
  const VerificationItem({
    required this.profileId,
    required this.fullName,
    required this.batchYear,
    required this.email,
    required this.submittedAt,
    this.degree,
    this.documentPath,
  });

  final String profileId;
  final String fullName;
  final int batchYear;
  final String email;
  final String submittedAt;
  final String? degree;
  final String? documentPath;

  factory VerificationItem.fromJson(Map<String, dynamic> json) {
    return VerificationItem(
      profileId: '${json['id']}',
      fullName: '${json['full_name']}',
      batchYear: json['batch_year'] is int
          ? json['batch_year'] as int
          : int.tryParse('${json['batch_year']}') ?? 0,
      email: '${json['email'] ?? ''}',
      submittedAt: '${json['submitted_at'] ?? ''}',
      degree: json['degree'] as String?,
    );
  }
}

class AdminMember {
  const AdminMember({
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

  factory AdminMember.fromJson(Map<String, dynamic> json) {
    return AdminMember(
      userId: '${json['user_id']}',
      email: '${json['email']}',
      role: '${json['role']}',
      fullName: json['full_name'] as String?,
      batchYear: json['batch_year'] as int?,
      membershipStatus: json['membership_status'] as String?,
      planName: json['plan_name'] as String?,
      verificationStatus: json['verification_status'] as String?,
    );
  }
}

class AdminEvent extends EventSummary {
  const AdminEvent({
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
    required this.isPublished,
  });

  final bool isPublished;

  factory AdminEvent.fromJson(Map<String, dynamic> json) {
    return AdminEvent(
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
      isPublished: json['published_at'] != null,
    );
  }
}

class AdminService {
  AdminService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<AnalyticsOverview> fetchOverview() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/analytics/overview',
    );
    if (response.statusCode == 200 && response.data != null) {
      return AnalyticsOverview.fromJson(response.data!);
    }
    throw const ApiException('Could not load analytics.');
  }

  Future<Map<String, dynamic>> fetchEngagement() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/analytics/engagement',
    );
    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    }
    throw const ApiException('Could not load engagement.');
  }

  Future<List<VerificationItem>> fetchVerifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/verifications',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final items = response.data?['profiles'];
    if (response.statusCode == 200 && items is List) {
      return [
        for (final item in items)
          if (item is Map<String, dynamic>)
            VerificationItem.fromJson(item),
      ];
    }
    return const [];
  }

  Future<void> updateVerification(String profileId, String action) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/verifications/$profileId',
      data: {'action': action},
    );
  }

  Future<List<AdminMember>> fetchMembers({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/members',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'page_size': pageSize,
      },
    );
    final members = response.data?['members'];
    if (response.statusCode == 200 && members is List) {
      return [
        for (final item in members)
          if (item is Map<String, dynamic>) AdminMember.fromJson(item),
      ];
    }
    return const [];
  }

  Future<List<int>> exportMembers() async {
    final response = await _apiClient.dio.get<List<int>>(
      '${AppConfig.apiPrefix}/admin/members/export',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/users/$userId/role',
      data: {'role': role},
    );
  }

  Future<String> sendEventReminder(String eventId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/notifications/event-reminders/$eventId',
    );
    return '${response.data?['message'] ?? 'Reminder sent.'}';
  }

  Future<List<AdminEvent>> fetchAdminEvents() async {
    final response = await _apiClient.get<List<dynamic>>(
      '${AppConfig.apiPrefix}/admin/events',
    );
    final events = response.data;
    if (response.statusCode == 200 && events != null) {
      return [
        for (final item in events)
          if (item is Map<String, dynamic>) AdminEvent.fromJson(item),
      ];
    }
    return const [];
  }

  Future<void> createEvent(Map<String, dynamic> body) async {
    await _apiClient.post<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/events',
      data: body,
    );
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> body) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '${AppConfig.apiPrefix}/admin/events/$eventId',
      data: body,
    );
  }

  Future<void> deleteEvent(String eventId) async {
    await _apiClient.dio.delete(
      '${AppConfig.apiPrefix}/admin/events/$eventId',
    );
  }
}
