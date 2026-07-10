import 'package:dio/dio.dart';

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

  Future<List<VerificationQueueItem>> fetchPendingVerifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _authenticatedGet(
        '${AppConfig.apiPrefix}/admin/verifications',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final profiles = response.data?['profiles'] as List<dynamic>? ?? [];
      return profiles
          .map((e) => VerificationQueueItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
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
