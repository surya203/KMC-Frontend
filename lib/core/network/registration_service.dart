import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'api_errors.dart';

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
  RegistrationException(this.message, {this.retryAfterSeconds});

  final String message;
  final int? retryAfterSeconds;

  bool get isOtpCooldown =>
      message.toLowerCase().contains('wait before requesting another otp');

  bool get isAlreadyVerified =>
      message.toLowerCase().contains('already verified');

  @override
  String toString() => message;
}

class SendOtpResult {
  const SendOtpResult({required this.message, this.debugOtp});

  final String message;
  final String? debugOtp;
}

class RegistrationService {
  RegistrationService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<RegistrationDraft> createDraft({
    required String planId,
    String? countryCode,
    String? currency,
    int? amountPaise,
  }) async {
    return _draftRequest(
      'POST',
      '${AppConfig.apiPrefix}/auth/register/draft',
      data: {
        'step': 1,
        'payload': {
          'plan_id': planId,
          if (countryCode != null) 'country_code': countryCode,
          if (currency != null) 'currency': currency,
          if (amountPaise != null) 'amount_paise': amountPaise,
        },
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

  Future<SendOtpResult> sendOtp(String draftId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/verify',
        data: {'draft_id': draftId, 'action': 'send_otp'},
      );
      final data = response.data;
      if (data == null) throw RegistrationException('Failed to send OTP.');
      return SendOtpResult(
        message: data['message'] as String? ??
            'Verification code sent to your email.',
        debugOtp: data['debug_otp'] as String?,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
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
      throw _mapDioException(e);
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
      throw _mapDioException(e);
    }
  }

  Future<void> uploadDraftRegistrationDocument({
    required String draftId,
    required String documentType,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document_type': documentType,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: _documentContentType(fileName),
        ),
      });
      await _apiClient.dio.post(
        '${AppConfig.apiPrefix}/auth/register/draft/$draftId/registration-document',
        data: formData,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @Deprecated('Use uploadDraftRegistrationDocument with documentType mcr')
  Future<void> uploadDraftCouncilCertificate({
    required String draftId,
    required String fileName,
    required List<int> bytes,
  }) {
    return uploadDraftRegistrationDocument(
      draftId: draftId,
      documentType: 'mcr',
      fileName: fileName,
      bytes: bytes,
    );
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
      throw _mapDioException(e);
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
      throw _mapDioException(e);
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
      throw _mapDioException(e);
    }
  }

  RegistrationException _mapDioException(DioException e) {
    final detail = e.response?.data;
    if (detail is Map) {
      final nested = detail['detail'];
      if (nested is Map) {
        final message = nested['message'] as String? ?? 'Registration request failed.';
        return RegistrationException(
          sanitizeUserFacingMessage(message),
          retryAfterSeconds: _parseRetryAfter(nested['retry_after_seconds']),
        );
      }
      if (nested is String) {
        return RegistrationException(
          sanitizeUserFacingMessage(nested),
          retryAfterSeconds: null,
        );
      }
      final message = detail['message'] as String?;
      if (message != null) {
        return RegistrationException(
          sanitizeUserFacingMessage(message),
          retryAfterSeconds: _parseRetryAfter(detail['retry_after_seconds']),
        );
      }
    }
    return RegistrationException(
      sanitizeUserFacingMessage(
        e.response?.statusMessage ?? 'Registration request failed.',
      ),
    );
  }

  int? _parseRetryAfter(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value');
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

  MediaType _documentContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return MediaType('application', 'pdf');
    }
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
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
