import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import '../config/app_config.dart';
import 'announcements_api_service.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Parse API timestamps as UTC when no timezone is provided.
DateTime parseConnectDateTime(Object? raw) {
  final text = '${raw ?? ''}'.trim();
  if (text.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  final hasZone = text.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text);
  final normalized = hasZone ? text : '${text}Z';
  return DateTime.parse(normalized).toUtc();
}

class ConnectOfficer {
  const ConnectOfficer({
    required this.userId,
    required this.email,
    required this.role,
    required this.roleLabel,
    required this.initials,
    this.fullName,
    this.photoUrl,
  });

  final String userId;
  final String email;
  final String role;
  final String roleLabel;
  final String initials;
  final String? fullName;
  final String? photoUrl;

  String get displayName => fullName ?? email.split('@').first;

  factory ConnectOfficer.fromJson(Map<String, dynamic> json) {
    return ConnectOfficer(
      userId: '${json['user_id']}',
      email: '${json['email']}',
      role: '${json['role']}',
      roleLabel: '${json['role_label']}',
      initials: '${json['initials']}',
      fullName: json['full_name'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class CommunityMessageItem {
  const CommunityMessageItem({
    required this.id,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.createdAt,
    this.batchYear,
    this.authorRoleLabel,
    this.targetName,
    this.targetMembershipNumber,
    this.targetBatchYear,
    this.targetLocation,
    this.targetSpecialization,
    this.targetPhone,
    this.audienceLabel,
    this.isTargeted = false,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMime,
    this.attachmentSize,
  });

  final String id;
  final String body;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final DateTime createdAt;
  final int? batchYear;
  final String? authorRoleLabel;
  final String? targetName;
  final String? targetMembershipNumber;
  final int? targetBatchYear;
  final String? targetLocation;
  final String? targetSpecialization;
  final String? targetPhone;
  final String? audienceLabel;
  final bool isTargeted;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMime;
  final int? attachmentSize;

  bool get hasAttachment =>
      (attachmentUrl != null && attachmentUrl!.trim().isNotEmpty) ||
      (attachmentName != null && attachmentName!.trim().isNotEmpty);

  factory CommunityMessageItem.fromJson(Map<String, dynamic> json) {
    final audience = json['audience_label'] as String?;
    final isTargeted = json['is_targeted'] as bool? ??
        (audience != null && audience.trim().isNotEmpty);
    return CommunityMessageItem(
      id: '${json['id']}',
      body: '${json['body']}',
      authorId: '${json['author_id']}',
      authorName: '${json['author_name']}',
      authorInitials: '${json['author_initials']}',
      batchYear: json['batch_year'] as int?,
      authorRoleLabel: json['author_role_label'] as String?,
      targetName: json['target_name'] as String?,
      targetMembershipNumber: json['target_membership_number'] as String?,
      targetBatchYear: json['target_batch_year'] is int
          ? json['target_batch_year'] as int
          : int.tryParse('${json['target_batch_year'] ?? ''}'),
      targetLocation: json['target_location'] as String?,
      targetSpecialization: json['target_specialization'] as String?,
      targetPhone: json['target_phone'] as String?,
      audienceLabel: audience,
      isTargeted: isTargeted,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentMime: json['attachment_mime'] as String?,
      attachmentSize: json['attachment_size'] as int?,
      createdAt: parseConnectDateTime(json['created_at']),
    );
  }
}

class AlumniChatTargets {
  const AlumniChatTargets({
    this.name,
    this.membershipNumber,
    this.batchYear,
    this.location,
    this.specialization,
    this.phone,
  });

  final String? name;
  final String? membershipNumber;
  final int? batchYear;
  final String? location;
  final String? specialization;
  final String? phone;

  bool get hasAny {
    return (name != null && name!.trim().isNotEmpty) ||
        (membershipNumber != null && membershipNumber!.trim().isNotEmpty) ||
        batchYear != null ||
        (location != null && location!.trim().isNotEmpty) ||
        (specialization != null && specialization!.trim().isNotEmpty) ||
        (phone != null && phone!.trim().isNotEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null && name!.trim().isNotEmpty) 'target_name': name!.trim(),
      if (membershipNumber != null && membershipNumber!.trim().isNotEmpty)
        'target_membership_number': membershipNumber!.trim(),
      if (batchYear != null) 'target_batch_year': batchYear,
      if (location != null && location!.trim().isNotEmpty)
        'target_location': location!.trim(),
      if (specialization != null && specialization!.trim().isNotEmpty)
        'target_specialization': specialization!.trim(),
      if (phone != null && phone!.trim().isNotEmpty) 'target_phone': phone!.trim(),
    };
  }
}

class DmMemberCandidate {
  const DmMemberCandidate({
    required this.userId,
    required this.fullName,
    required this.initials,
    this.batchYear,
  });

  final String userId;
  final String fullName;
  final String initials;
  final int? batchYear;

  factory DmMemberCandidate.fromJson(Map<String, dynamic> json) {
    return DmMemberCandidate(
      userId: '${json['user_id']}',
      fullName: '${json['full_name']}',
      initials: '${json['initials']}',
      batchYear: json['batch_year'] as int?,
    );
  }
}

class DmThreadItem {
  const DmThreadItem({
    required this.id,
    required this.peerUserId,
    required this.peerName,
    required this.peerInitials,
    this.peerRoleLabel,
    this.lastMessage,
    this.updatedAt,
    this.iBlockedPeer = false,
    this.peerBlockedMe = false,
    this.canMessage = true,
  });

  final String id;
  final String peerUserId;
  final String peerName;
  final String peerInitials;
  final String? peerRoleLabel;
  final String? lastMessage;
  final DateTime? updatedAt;
  final bool iBlockedPeer;
  final bool peerBlockedMe;
  final bool canMessage;

  factory DmThreadItem.fromJson(Map<String, dynamic> json) {
    return DmThreadItem(
      id: '${json['id']}',
      peerUserId: '${json['peer_user_id']}',
      peerName: '${json['peer_name']}',
      peerInitials: '${json['peer_initials']}',
      peerRoleLabel: json['peer_role_label'] as String?,
      lastMessage: json['last_message'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse('${json['updated_at']}'),
      iBlockedPeer: json['i_blocked_peer'] as bool? ?? false,
      peerBlockedMe: json['peer_blocked_me'] as bool? ?? false,
      canMessage: json['can_message'] as bool? ?? true,
    );
  }
}

class DmMessageItem {
  const DmMessageItem({
    required this.id,
    required this.threadId,
    required this.body,
    required this.senderId,
    required this.senderName,
    required this.senderInitials,
    required this.isMine,
    required this.createdAt,
    this.status = 'sent',
  });

  final String id;
  final String threadId;
  final String body;
  final String senderId;
  final String senderName;
  final String senderInitials;
  final bool isMine;
  final DateTime createdAt;
  /// sent | delivered | read
  final String status;

  factory DmMessageItem.fromJson(Map<String, dynamic> json) {
    return DmMessageItem(
      id: '${json['id']}',
      threadId: '${json['thread_id']}',
      body: '${json['body']}',
      senderId: '${json['sender_id']}',
      senderName: '${json['sender_name']}',
      senderInitials: '${json['sender_initials']}',
      isMine: json['is_mine'] as bool? ?? false,
      status: '${json['status'] ?? 'sent'}',
      createdAt: parseConnectDateTime(json['created_at']),
    );
  }
}

class DmConversation {
  const DmConversation({
    required this.thread,
    required this.messages,
  });

  final DmThreadItem thread;
  final List<DmMessageItem> messages;
}

class ConnectApiService {
  ConnectApiService({
    ApiClient? apiClient,
    AnnouncementsApiService? announcementsApi,
  })  : _apiClient = apiClient ?? ApiClient(),
        _announcementsApi = announcementsApi ?? AnnouncementsApiService();

  final ApiClient _apiClient;
  final AnnouncementsApiService _announcementsApi;

  static const generalGroupCategory = 'general_group';

  Options? get _authOptions {
    final header = AuthService.authorizationHeader;
    if (header == null) return null;
    return Options(headers: {'Authorization': header});
  }

  Future<List<AnnouncementItem>> fetchGeneralGroupPosts() async {
    await AuthSession.instance.ensureReady();
    return _announcementsApi.fetchAnnouncements(category: generalGroupCategory);
  }

  Future<void> postGeneralGroupMessage(String body) async {
    await AuthSession.instance.ensureReady();
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final title = trimmed.length > 80 ? '${trimmed.substring(0, 77)}...' : trimmed;
    await _announcementsApi.createAnnouncement(
      title: title,
      body: trimmed,
      category: generalGroupCategory,
      publish: true,
    );
  }

  Future<List<CommunityMessageItem>> fetchCommunityMessages() async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view Alumni Chat.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/community/messages',
        options: options,
      );
      final items = response.data?['messages'] as List<dynamic>? ?? [];
      return items
          .map((e) => CommunityMessageItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> postCommunityMessage(
    String body, [
    AlumniChatTargets? targets,
    List<int>? fileBytes,
    String? fileName,
  ]) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to post to Alumni Chat.');
    final trimmed = body.trim();
    final hasFile = fileBytes != null &&
        fileBytes.isNotEmpty &&
        fileName != null &&
        fileName.trim().isNotEmpty;
    if (trimmed.isEmpty && !hasFile) return;

    try {
      if (hasFile) {
        final bytes = List<int>.from(fileBytes);
        final formData = FormData.fromMap({
          // Caption is optional — empty string is fine when a file is present.
          'body': trimmed,
          for (final entry in (targets?.toJson() ?? {}).entries)
            entry.key: '${entry.value}',
          'file': MultipartFile.fromBytes(
            bytes,
            filename: fileName.trim(),
          ),
        });

        // Absolute URL from AppConfig (API_BASE_URL in .env / window.__ENV__).
        final uploadUrl =
            '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/connect/community/messages/with-file';
        final response = await _apiClient.dio.post<Map<String, dynamic>>(
          uploadUrl,
          data: formData,
          options: Options(
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 2),
          ),
        );

        final savedName = response.data?['attachment_name'] as String?;
        if (savedName == null || savedName.trim().isEmpty) {
          throw Exception(
            'Document was not saved. Check API_BASE_URL (${AppConfig.apiBaseUrl}), '
            'migration-022, and storage bucket, then retry.',
          );
        }
      } else {
        final data = <String, dynamic>{
          'body': trimmed,
          ...?targets?.toJson(),
        };
        await _apiClient.post<Map<String, dynamic>>(
          '${AppConfig.apiPrefix}/connect/community/messages',
          data: data,
          options: options,
        );
      }
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<({List<int> bytes, String fileName, String mimeType})>
      downloadCommunityAttachment(String messageId) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to download this document.');
    try {
      final response = await _apiClient.get<List<int>>(
        '${AppConfig.apiPrefix}/connect/community/messages/$messageId/attachment',
        options: options.copyWith(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Download failed. Empty file.');
      }
      final disposition = response.headers.value('content-disposition') ?? '';
      var fileName = 'document';
      final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
      if (match != null) {
        fileName = match.group(1) ?? fileName;
      }
      final mime =
          response.headers.value('content-type') ?? 'application/octet-stream';
      return (bytes: bytes, fileName: fileName, mimeType: mime);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<CommunityMessageItem>> fetchFinanceCouncilMessages() async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view Financial Decisions.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/finance-council/messages',
        options: options,
      );
      final items = response.data?['messages'] as List<dynamic>? ?? [];
      return items
          .map((e) => CommunityMessageItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> postFinanceCouncilMessage(
    String body, [
    List<int>? fileBytes,
    String? fileName,
  ]) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to post to Financial Decisions.');
    final trimmed = body.trim();
    final hasFile = fileBytes != null &&
        fileBytes.isNotEmpty &&
        fileName != null &&
        fileName.trim().isNotEmpty;
    if (trimmed.isEmpty && !hasFile) return;

    try {
      if (hasFile) {
        final bytes = List<int>.from(fileBytes);
        final formData = FormData.fromMap({
          'body': trimmed,
          'file': MultipartFile.fromBytes(
            bytes,
            filename: fileName.trim(),
          ),
        });
        final uploadUrl =
            '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/connect/finance-council/messages/with-file';
        final response = await _apiClient.dio.post<Map<String, dynamic>>(
          uploadUrl,
          data: formData,
          options: Options(
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 2),
          ),
        );
        final savedName = response.data?['attachment_name'] as String?;
        if (savedName == null || savedName.trim().isEmpty) {
          throw Exception(
            'Document was not saved. Run migration-025 and check storage, then retry.',
          );
        }
      } else {
        await _apiClient.post<Map<String, dynamic>>(
          '${AppConfig.apiPrefix}/connect/finance-council/messages',
          data: {'body': trimmed},
          options: options,
        );
      }
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<({List<int> bytes, String fileName, String mimeType})>
      downloadFinanceCouncilAttachment(String messageId) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to download this document.');
    try {
      final response = await _apiClient.get<List<int>>(
        '${AppConfig.apiPrefix}/connect/finance-council/messages/$messageId/attachment',
        options: options.copyWith(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Download failed. Empty file.');
      }
      final disposition = response.headers.value('content-disposition') ?? '';
      var fileName = 'document';
      final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
      if (match != null) {
        fileName = match.group(1) ?? fileName;
      }
      final mime =
          response.headers.value('content-type') ?? 'application/octet-stream';
      return (bytes: bytes, fileName: fileName, mimeType: mime);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<CommunityMessageItem>> fetchExecutiveCommitteeMessages() async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) {
      throw Exception('Sign in to view Executive Committee Chat.');
    }
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/executive-committee/messages',
        options: options,
      );
      final items = response.data?['messages'] as List<dynamic>? ?? [];
      return items
          .map((e) => CommunityMessageItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> postExecutiveCommitteeMessage(
    String body, [
    List<int>? fileBytes,
    String? fileName,
  ]) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) {
      throw Exception('Sign in to post to Executive Committee Chat.');
    }
    final trimmed = body.trim();
    final hasFile = fileBytes != null &&
        fileBytes.isNotEmpty &&
        fileName != null &&
        fileName.trim().isNotEmpty;
    if (trimmed.isEmpty && !hasFile) return;

    try {
      if (hasFile) {
        final bytes = List<int>.from(fileBytes);
        final formData = FormData.fromMap({
          'body': trimmed,
          'file': MultipartFile.fromBytes(
            bytes,
            filename: fileName.trim(),
          ),
        });
        final uploadUrl =
            '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/connect/executive-committee/messages/with-file';
        final response = await _apiClient.dio.post<Map<String, dynamic>>(
          uploadUrl,
          data: formData,
          options: Options(
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 2),
          ),
        );
        final savedName = response.data?['attachment_name'] as String?;
        if (savedName == null || savedName.trim().isEmpty) {
          throw Exception(
            'Document was not saved. Run migration-025 and check storage, then retry.',
          );
        }
      } else {
        await _apiClient.post<Map<String, dynamic>>(
          '${AppConfig.apiPrefix}/connect/executive-committee/messages',
          data: {'body': trimmed},
          options: options,
        );
      }
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<({List<int> bytes, String fileName, String mimeType})>
      downloadExecutiveCommitteeAttachment(String messageId) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to download this document.');
    try {
      final response = await _apiClient.get<List<int>>(
        '${AppConfig.apiPrefix}/connect/executive-committee/messages/$messageId/attachment',
        options: options.copyWith(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Download failed. Empty file.');
      }
      final disposition = response.headers.value('content-disposition') ?? '';
      var fileName = 'document';
      final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
      if (match != null) {
        fileName = match.group(1) ?? fileName;
      }
      final mime =
          response.headers.value('content-type') ?? 'application/octet-stream';
      return (bytes: bytes, fileName: fileName, mimeType: mime);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<ConnectOfficer>> fetchOfficers() async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view officers.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/officers',
        options: options,
      );
      final items = response.data?['officers'] as List<dynamic>? ?? [];
      return items
          .map((e) => ConnectOfficer.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<DmThreadItem>> fetchDmThreads() async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view DMs.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/dm/threads',
        options: options,
      );
      final items = response.data?['threads'] as List<dynamic>? ?? [];
      return items
          .map((e) => DmThreadItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<DmMemberCandidate>> searchDmMembers({String? query}) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to search members.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/dm/members',
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          'limit': 30,
        },
        options: options,
      );
      final items = response.data?['members'] as List<dynamic>? ?? [];
      return items
          .map((e) => DmMemberCandidate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<DmConversation> startDm({
    required String memberUserId,
    required String body,
  }) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to start a DM.');
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/dm/threads',
        data: {
          'member_user_id': memberUserId,
          'body': body.trim(),
        },
        options: options,
      );
      return _conversationFromResponse(response.data);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<DmConversation> fetchDmMessages(String threadId) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to view this DM.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/dm/threads/$threadId/messages',
        options: options,
      );
      return _conversationFromResponse(response.data);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> sendDmReply({
    required String threadId,
    required String body,
  }) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in to reply.');
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/dm/threads/$threadId/messages',
        data: {'body': trimmed},
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<DmConversation> markDmRead(String threadId) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in required.');
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/dm/threads/$threadId/read',
        options: options,
      );
      return _conversationFromResponse(response.data);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> blockDmUser(String userId) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in required.');
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/dm/block',
        data: {'user_id': userId},
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> unblockDmUser(String userId) async {
    await AuthSession.instance.ensureReady();
    final options = _authOptions;
    if (options == null) throw Exception('Sign in required.');
    try {
      await _apiClient.delete<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/connect/dm/block/$userId',
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  DmConversation _conversationFromResponse(Map<String, dynamic>? data) {
    final threadJson = data?['thread'] as Map<String, dynamic>? ?? {};
    final items = data?['messages'] as List<dynamic>? ?? [];
    return DmConversation(
      thread: DmThreadItem.fromJson(threadJson),
      messages: items
          .map((e) => DmMessageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String _readDetail(DioException e) {
    final status = e.response?.statusCode;
    final detail = e.response?.data;
    if (status == 404) {
      return 'Document upload API not found at ${AppConfig.apiBaseUrl}. '
          'Set API_BASE_URL to the backend that has /with-file, '
          'restart Flutter, then retry.';
    }
    if (detail is Map && detail['detail'] != null) {
      final raw = detail['detail'];
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first is Map && first['msg'] != null) {
          return '${first['msg']}';
        }
      }
      return '$raw';
    }
    if (detail is String && detail.isNotEmpty) return detail;
    if (status == 403) {
      final detailText = detail is Map && detail['detail'] != null
          ? '${detail['detail']}'.toLowerCase()
          : '';
      if (detailText.contains('finance council')) {
        return 'Financial Decisions access required.';
      }
      if (detailText.contains('executive committee')) {
        return 'Executive Committee access required.';
      }
      return 'Active membership required.';
    }
    if (status == 503) {
      return detail is Map && detail['detail'] != null
          ? '${detail['detail']}'
          : 'Connect feature needs a database update.';
    }
    if (status == 500) {
      return detail is Map && detail['detail'] != null
          ? '${detail['detail']}'
          : 'Server error while sending. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Cannot reach the backend at ${AppConfig.apiBaseUrl}. '
          'Restart Flutter after backend port changes.';
    }
    return e.response?.statusMessage ??
        'Connect request failed (check API at ${AppConfig.apiBaseUrl}).';
  }
}
