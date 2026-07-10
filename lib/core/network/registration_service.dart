import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import 'api_client.dart';

class RegistrationDraft {
  const RegistrationDraft({
    required this.id,
    required this.step,
    required this.payload,
    this.email,
    this.verificationToken,
  });

  final String id;
  final int step;
  final Map<String, dynamic> payload;
  final String? email;
  final String? verificationToken;

  factory RegistrationDraft.fromJson(Map<String, dynamic> json) {
    return RegistrationDraft(
      id: json['id'] as String,
      step: json['step'] as int,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      email: json['email'] as String?,
      verificationToken: json['verification_token'] as String?,
    );
  }
}

class RegistrationException implements Exception {
  RegistrationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RegistrationService {
  RegistrationService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<RegistrationDraft> createDraft({
    required String planId,
  }) async {
    return _draftRequest(
      'POST',
      '${AppConfig.apiPrefix}/auth/register/draft',
      data: {
        'step': 1,
        'payload': {'plan_id': planId},
      },
    );
  }

  Future<RegistrationDraft> updateDraft({
    required String draftId,
    required int step,
    String? email,
    required Map<String, dynamic> payload,
  }) async {
    final draftPayload = <String, dynamic>{
      'step': step,
      'email': email,
      'payload': payload,
    }..removeWhere((key, value) => value == null);
    return _draftRequest(
      'PATCH',
      '${AppConfig.apiPrefix}/auth/register/draft/$draftId',
      data: draftPayload,
    );
  }

  Future<RegistrationDraft> getDraft(String draftId) async {
    return _draftRequest(
      'GET',
      '${AppConfig.apiPrefix}/auth/register/draft/$draftId',
    );
  }

  Future<String> sendOtp(String draftId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/verify',
        data: {'draft_id': draftId, 'action': 'send_otp'},
      );
      final data = response.data;
      if (data == null) throw RegistrationException('Failed to send OTP.');
      return data['message'] as String? ??
          'Verification code sent to your email.';
    } on DioException catch (e) {
      throw RegistrationException(_readDetail(e));
    }
  }

  Future<void> verifyOtp({
    required String draftId,
    required String otp,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/verify',
        data: {
          'draft_id': draftId,
          'action': 'verify_otp',
          'otp': otp,
        },
      );
    } on DioException catch (e) {
      throw RegistrationException(_readDetail(e));
    }
  }

  Future<void> uploadDraftPhoto({
    required String draftId,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: _imageContentType(fileName),
        ),
      });
      await _apiClient.dio.post(
        '${AppConfig.apiPrefix}/auth/register/draft/$draftId/photo',
        data: formData,
      );
    } on DioException catch (e) {
      throw RegistrationException(_readDetail(e));
    }
  }

  Future<void> uploadVerificationDocument({
    required String draftId,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'draft_id': draftId,
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      await _apiClient.dio.post(
        '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/auth/register/verify/document',
        data: formData,
      );
    } on DioException catch (e) {
      throw RegistrationException(_readDetail(e));
    }
  }

  Future<CompleteRegistrationResult> completeRegistration(
    String draftId,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/complete',
        data: {'draft_id': draftId},
      );
      final data = response.data;
      if (data == null) {
        throw RegistrationException('Registration completion failed.');
      }
      return CompleteRegistrationResult.fromJson(data);
    } on DioException catch (e) {
      throw RegistrationException(_readDetail(e));
    }
  }

  Future<RegistrationDraft> _draftRequest(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final Response<Map<String, dynamic>> response;
      if (method == 'GET') {
        response = await _apiClient.get<Map<String, dynamic>>(path);
      } else if (method == 'POST') {
        response = await _apiClient.post<Map<String, dynamic>>(path, data: data);
      } else {
        response = await _apiClient.patch<Map<String, dynamic>>(path, data: data);
      }
      if (response.data == null) {
        throw RegistrationException('Empty response from server.');
      }
      return RegistrationDraft.fromJson(response.data!);
    } on DioException catch (e) {
      throw RegistrationException(_readDetail(e));
    }
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      return '${detail['detail']}';
    }
    return e.response?.statusMessage ?? 'Registration request failed.';
  }

  MediaType _imageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }
}

class CompleteRegistrationResult {
  const CompleteRegistrationResult({
    required this.completed,
    required this.email,
    required this.message,
    this.debugPassword,
    this.receiptId,
    this.receiptUrl,
    this.membershipNumber,
    this.receiptNumber,
    this.paymentId,
    this.receiptHtml,
  });

  final bool completed;
  final String email;
  final String message;
  final String? debugPassword;
  final String? receiptId;
  final String? receiptUrl;
  final String? membershipNumber;
  final String? receiptNumber;
  final String? paymentId;
  final String? receiptHtml;

  factory CompleteRegistrationResult.fromJson(Map<String, dynamic> json) {
    return CompleteRegistrationResult(
      completed: json['completed'] as bool? ?? false,
      email: json['email'] as String? ?? '',
      message: json['message'] as String? ?? '',
      debugPassword: json['debug_password'] as String?,
      receiptId: json['receipt_id'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      membershipNumber: json['membership_number'] as String?,
      receiptNumber: json['receipt_number'] as String?,
      paymentId: json['payment_id'] as String?,
      receiptHtml: json['receipt_html'] as String?,
    );
  }
}
