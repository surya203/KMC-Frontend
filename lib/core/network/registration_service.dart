import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class RegistrationDraft {
  const RegistrationDraft({
    required this.id,
    required this.step,
    required this.payload,
    required this.expiresAt,
    this.email,
    this.verificationToken,
  });

  final String id;
  final int step;
  final Map<String, dynamic> payload;
  final DateTime expiresAt;
  final String? email;
  final String? verificationToken;

  factory RegistrationDraft.fromJson(Map<String, dynamic> json) {
    return RegistrationDraft(
      id: '${json['id']}',
      step: json['step'] is int
          ? json['step'] as int
          : int.tryParse('${json['step']}') ?? 1,
      email: json['email'] as String?,
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : {},
      verificationToken: json['verification_token'] as String?,
      expiresAt: DateTime.parse('${json['expires_at']}'),
    );
  }
}

class SendOtpResult {
  const SendOtpResult({
    required this.draftId,
    required this.message,
    this.debugOtp,
  });

  final String draftId;
  final String message;
  final String? debugOtp;

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      draftId: '${json['draft_id']}',
      message: '${json['message']}',
      debugOtp: json['debug_otp'] as String?,
    );
  }
}

class VerifyOtpResult {
  const VerifyOtpResult({
    required this.draftId,
    required this.verified,
    required this.message,
    this.verificationToken,
  });

  final String draftId;
  final bool verified;
  final String message;
  final String? verificationToken;

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResult(
      draftId: '${json['draft_id']}',
      verified: json['verified'] == true,
      message: '${json['message']}',
      verificationToken: json['verification_token'] as String?,
    );
  }
}

class CheckoutResult {
  const CheckoutResult({
    required this.draftId,
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
  });

  final String draftId;
  final String orderId;
  final int amountPaise;
  final String currency;
  final String keyId;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      draftId: '${json['draft_id']}',
      orderId: '${json['order_id']}',
      amountPaise: json['amount_paise'] is int
          ? json['amount_paise'] as int
          : int.tryParse('${json['amount_paise']}') ?? 0,
      currency: '${json['currency'] ?? 'INR'}',
      keyId: '${json['key_id']}',
    );
  }
}

class CompleteRegistrationResult {
  const CompleteRegistrationResult({
    required this.completed,
    required this.email,
    required this.message,
    this.debugPassword,
  });

  final bool completed;
  final String email;
  final String message;
  final String? debugPassword;

  factory CompleteRegistrationResult.fromJson(Map<String, dynamic> json) {
    return CompleteRegistrationResult(
      completed: json['completed'] == true,
      email: '${json['email']}',
      message: '${json['message']}',
      debugPassword: json['debug_password'] as String?,
    );
  }
}

class RegistrationService {
  RegistrationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<RegistrationDraft> createDraft({
    required int step,
    required Map<String, dynamic> payload,
    String? email,
  }) async {
    return _draftRequest(
      () => _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/draft',
        data: {
          'step': step,
          'email': email,
          'payload': payload,
        },
      ),
    );
  }

  Future<RegistrationDraft> updateDraft({
    required String draftId,
    required int step,
    required Map<String, dynamic> payload,
    String? email,
  }) async {
    return _draftRequest(
      () => _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/draft/$draftId',
        data: {
          'step': step,
          'email': email,
          'payload': payload,
        },
      ),
    );
  }

  Future<RegistrationDraft> getDraft(String draftId) async {
    return _draftRequest(
      () => _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/draft/$draftId',
      ),
    );
  }

  Future<SendOtpResult> sendOtp(String draftId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/verify',
        data: {'draft_id': draftId, 'action': 'send_otp'},
      );
      if (response.statusCode == 200 && response.data != null) {
        return SendOtpResult.fromJson(response.data!);
      }
      throw const ApiException('Could not send verification code.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<VerifyOtpResult> verifyOtp({
    required String draftId,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/verify',
        data: {
          'draft_id': draftId,
          'action': 'verify_otp',
          'otp': otp,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return VerifyOtpResult.fromJson(response.data!);
      }
      throw const ApiException('Verification failed.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<VerifyOtpResult> uploadVerificationDocument({
    required String draftId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'draft_id': draftId,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: _contentTypeForFilename(filename),
        ),
      });
      final response = await _apiClient.postMultipart<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/register/verify/document',
        data: formData,
      );
      if (response.statusCode == 200 && response.data != null) {
        return VerifyOtpResult.fromJson(response.data!);
      }
      throw const ApiException('Could not upload the document.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<CheckoutResult> createCheckout(String draftId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/checkout',
        data: {'draft_id': draftId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return CheckoutResult.fromJson(response.data!);
      }
      throw const ApiException('Could not start checkout.');
    } catch (error) {
      throw ApiClient.wrapError(error);
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
      if (response.statusCode == 200 && response.data != null) {
        return CompleteRegistrationResult.fromJson(response.data!);
      }
      throw const ApiException('Registration is not complete yet.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<RegistrationDraft> _draftRequest(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      if (response.statusCode == 200 && response.data != null) {
        return RegistrationDraft.fromJson(response.data!);
      }
      throw const ApiException('Could not save registration progress.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  DioMediaType _contentTypeForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return DioMediaType.parse('application/pdf');
    }
    if (lower.endsWith('.png')) {
      return DioMediaType.parse('image/png');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return DioMediaType.parse('image/jpeg');
    }
    return DioMediaType.parse('application/octet-stream');
  }
}
