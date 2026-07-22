import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'api_client.dart';

class MembershipPlanPrice {
  const MembershipPlanPrice({
    required this.countryCode,
    required this.countryName,
    required this.currency,
    required this.amountPaise,
    required this.displayPrice,
  });

  final String countryCode;
  final String countryName;
  final String currency;
  final int amountPaise;
  final String displayPrice;

  factory MembershipPlanPrice.fromJson(Map<String, dynamic> json) {
    final currency = '${json['currency'] ?? 'INR'}'.toUpperCase();
    final amount = json['amount_paise'] is int
        ? json['amount_paise'] as int
        : int.tryParse('${json['amount_paise']}') ?? 0;
    final display = '${json['display_price'] ?? ''}'.trim();
    return MembershipPlanPrice(
      countryCode: '${json['country_code'] ?? 'IN'}'.toUpperCase(),
      countryName: '${json['country_name'] ?? ''}',
      currency: currency,
      amountPaise: amount,
      displayPrice: display.isNotEmpty
          ? display
          : _formatCurrencyAmount(amount, currency),
    );
  }
}

String _formatCurrencyAmount(int amountPaise, String currency) {
  final major = amountPaise / 100;
  final whole = major == major.roundToDouble()
      ? '${major.toInt()}'
      : major.toStringAsFixed(2);
  return switch (currency.toUpperCase()) {
    'INR' => '₹$whole',
    'USD' => '\$$whole',
    'GBP' => '£$whole',
    'AUD' => 'A\$$whole',
    _ => '$currency $whole',
  };
}

class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.slug,
    required this.name,
    required this.pricePaise,
    required this.currency,
    required this.benefits,
    this.description,
    this.prices = const [],
  });

  final String id;
  final String slug;
  final String name;
  final int pricePaise;
  final String currency;
  final List<String> benefits;
  final String? description;
  final List<MembershipPlanPrice> prices;

  String get displayPrice => _formatCurrencyAmount(pricePaise, currency);

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    final rawBenefits = json['benefits'];
    final rawPrices = json['prices'];
    return MembershipPlan(
      id: '${json['id']}',
      slug: '${json['slug']}',
      name: '${json['name']}',
      pricePaise: json['price_paise'] is int
          ? json['price_paise'] as int
          : int.tryParse('${json['price_paise']}') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      description: json['description'] as String?,
      benefits: rawBenefits is List
          ? rawBenefits.map((e) => '$e').toList()
          : const [],
      prices: rawPrices is List
          ? rawPrices
              .whereType<Map>()
              .map(
                (e) => MembershipPlanPrice.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class CheckoutSession {
  const CheckoutSession({
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

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      draftId: '${json['draft_id']}',
      orderId: '${json['order_id']}',
      amountPaise: json['amount_paise'] as int,
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['key_id'] as String? ?? '',
    );
  }
}

class ProjectDonationTotal {
  const ProjectDonationTotal({
    required this.category,
    required this.label,
    required this.totalPaise,
  });

  final String category;
  final String label;
  final int totalPaise;

  factory ProjectDonationTotal.fromJson(Map<String, dynamic> json) {
    return ProjectDonationTotal(
      category: '${json['category']}',
      label: '${json['label']}',
      totalPaise: json['total_paise'] is int
          ? json['total_paise'] as int
          : int.tryParse('${json['total_paise']}') ?? 0,
    );
  }
}

class MemberMembership {
  const MemberMembership({
    required this.status,
    required this.planName,
    required this.planSlug,
    required this.votingRights,
    required this.feePaise,
    required this.generalDonationPaise,
    required this.projectDonationPaise,
    required this.projectDonations,
    this.planId,
    this.startedAt,
    this.expiresAt,
    this.membershipNumber,
    this.registrationDate,
    this.paymentDate,
  });

  final String status;
  final String planName;
  final String planSlug;
  final bool votingRights;
  final String? planId;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? membershipNumber;
  final String? registrationDate;
  final String? paymentDate;
  final int feePaise;
  final int generalDonationPaise;
  final int projectDonationPaise;
  final List<ProjectDonationTotal> projectDonations;

  String get feeDisplay => _formatPaise(feePaise);
  String get generalDonationDisplay => _formatPaise(generalDonationPaise);
  String get projectDonationDisplay => _formatPaise(projectDonationPaise);

  factory MemberMembership.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) =>
        raw == null ? null : DateTime.tryParse(raw);
    final projects = json['project_donations'];

    return MemberMembership(
      status: '${json['status']}',
      planName: '${json['plan_name']}',
      planSlug: '${json['plan_slug']}',
      votingRights: json['voting_rights'] == true,
      planId: json['plan_id'] as String?,
      startedAt: parseDate(json['started_at'] as String?),
      expiresAt: parseDate(json['expires_at'] as String?),
      membershipNumber: json['membership_number'] as String?,
      registrationDate: json['registration_date'] as String? ??
          json['started_at'] as String?,
      paymentDate: json['payment_date'] as String?,
      feePaise: json['fee_paise'] is int
          ? json['fee_paise'] as int
          : int.tryParse('${json['fee_paise']}') ?? 0,
      generalDonationPaise: json['general_donation_paise'] is int
          ? json['general_donation_paise'] as int
          : int.tryParse('${json['general_donation_paise']}') ?? 0,
      projectDonationPaise: json['project_donation_paise'] is int
          ? json['project_donation_paise'] as int
          : int.tryParse('${json['project_donation_paise']}') ?? 0,
      projectDonations: projects is List
          ? [
              for (final item in projects)
                if (item is Map<String, dynamic>)
                  ProjectDonationTotal.fromJson(item),
            ]
          : const [],
    );
  }
}

class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.id,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
    this.providerOrderId,
    this.providerPaymentId,
    this.receiptNumber,
    this.hasReceipt = false,
  });

  final String id;
  final int amountPaise;
  final String status;
  final DateTime createdAt;
  final String? providerOrderId;
  final String? providerPaymentId;
  final String? receiptNumber;
  final bool hasReceipt;

  String get displayAmount => '₹${(amountPaise / 100).round()}';

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: '${json['id']}',
      amountPaise: json['amount_paise'] as int,
      status: '${json['status']}',
      createdAt: DateTime.parse('${json['created_at']}'),
      providerOrderId: json['provider_order_id'] as String?,
      providerPaymentId: json['provider_payment_id'] as String?,
      receiptNumber: json['receipt_number'] as String?,
      hasReceipt: json['has_receipt'] as bool? ?? false,
    );
  }
}

class DonationCategory {
  const DonationCategory({required this.slug, required this.label});

  final String slug;
  final String label;

  factory DonationCategory.fromJson(Map<String, dynamic> json) {
    return DonationCategory(
      slug: '${json['slug']}',
      label: '${json['label']}',
    );
  }
}

class DonationCheckout {
  const DonationCheckout({
    required this.donationId,
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
    required this.donationType,
    this.projectCategory,
    this.projectCategoryLabel,
  });

  final String donationId;
  final String orderId;
  final int amountPaise;
  final String currency;
  final String keyId;
  final String donationType;
  final String? projectCategory;
  final String? projectCategoryLabel;

  factory DonationCheckout.fromJson(Map<String, dynamic> json) {
    return DonationCheckout(
      donationId: '${json['donation_id']}',
      orderId: '${json['order_id']}',
      amountPaise: json['amount_paise'] is int
          ? json['amount_paise'] as int
          : int.tryParse('${json['amount_paise']}') ?? 0,
      currency: '${json['currency'] ?? 'INR'}',
      keyId: '${json['key_id'] ?? ''}',
      donationType: '${json['donation_type']}',
      projectCategory: json['project_category'] as String?,
      projectCategoryLabel: json['project_category_label'] as String?,
    );
  }
}

class DonationRecord {
  const DonationRecord({
    required this.id,
    required this.donationType,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
    this.projectCategory,
    this.projectCategoryLabel,
    this.capturedAt,
  });

  final String id;
  final String donationType;
  final String? projectCategory;
  final String? projectCategoryLabel;
  final int amountPaise;
  final String status;
  final String createdAt;
  final String? capturedAt;

  String get amountDisplay => _formatPaise(amountPaise);

  String get title {
    if (donationType == 'general') return 'General Donation';
    return projectCategoryLabel ?? projectCategory ?? 'Project Donation';
  }

  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    return DonationRecord(
      id: '${json['id']}',
      donationType: '${json['donation_type']}',
      projectCategory: json['project_category'] as String?,
      projectCategoryLabel: json['project_category_label'] as String?,
      amountPaise: json['amount_paise'] is int
          ? json['amount_paise'] as int
          : int.tryParse('${json['amount_paise']}') ?? 0,
      status: '${json['status']}',
      createdAt: '${json['created_at']}',
      capturedAt: json['captured_at'] as String?,
    );
  }
}

String _formatPaise(int paise) {
  final rupees = paise / 100;
  if (rupees == rupees.roundToDouble()) {
    return '₹${rupees.toInt()}';
  }
  return '₹${rupees.toStringAsFixed(2)}';
}

class MembershipApiService {
  MembershipApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Options? get _authOptions {
    final header = AuthService.authorizationHeader;
    if (header == null) return null;
    return Options(headers: {'Authorization': header});
  }

  Future<List<MembershipPlan>> fetchPlans() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/plans',
        options: Options(
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final plans = response.data?['plans'] as List<dynamic>? ?? [];
      return plans
          .map((e) => MembershipPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<CheckoutSession> createCheckout(
    String draftId, {
    String? countryCode,
    String? currency,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/checkout',
        data: {
          'draft_id': draftId,
          if (countryCode != null && countryCode.isNotEmpty)
            'country_code': countryCode,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
        },
      );
      if (response.data == null) throw Exception('Checkout failed.');
      return CheckoutSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<MembershipPlan> fetchPlanBySlug(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/plans/$slug',
      );
      if (response.data == null) throw Exception('Plan not found.');
      return MembershipPlan.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<MemberMembership> fetchMyMembership() async {
    final options = _authOptions;
    if (options == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/me',
        options: options,
      );
      if (response.data == null) throw Exception('No membership data.');
      return MemberMembership.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<PaymentHistoryItem>> fetchMyPayments() async {
    final options = _authOptions;
    if (options == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/payments',
        options: options,
      );
      final payments = response.data?['payments'] as List<dynamic>? ?? [];
      return payments
          .map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<String> fetchPaymentReceiptHtml(String paymentId) async {
    final options = _authOptions;
    if (options == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.dio.get<String>(
        '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/membership/payments/$paymentId/receipt',
        options: options.copyWith(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<DonationCategory>> fetchDonationCategories() async {
    final options = _authOptions;
    if (options == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/donations/categories',
        options: options,
      );
      final items = response.data?['categories'] as List<dynamic>? ?? [];
      return items
          .map((e) => DonationCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<DonationRecord>> fetchMyDonations() async {
    final options = _authOptions;
    if (options == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/donations',
        options: options,
      );
      final items = response.data?['donations'] as List<dynamic>? ?? [];
      return items
          .map((e) => DonationRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<DonationCheckout> createDonationCheckout({
    required int amountPaise,
    required String donationType,
    String? projectCategory,
  }) async {
    final options = _authOptions;
    if (options == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/donations/checkout',
        data: {
          'amount_paise': amountPaise,
          'donation_type': donationType,
          if (projectCategory != null) 'project_category': projectCategory,
        },
        options: options,
      );
      if (response.data == null) {
        throw Exception('Could not start donation checkout.');
      }
      return DonationCheckout.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<String> completeDonation(String orderId) async {
    final options = _authOptions;
    if (options == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/donations/complete',
        data: {'order_id': orderId},
        options: options,
      );
      if (response.data?['message'] != null) {
        return '${response.data!['message']}';
      }
      return 'Donation recorded.';
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      return '${detail['detail']}';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Server is taking too long to respond. Check that the backend is running on ${AppConfig.apiBaseUrl}.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server at ${AppConfig.apiBaseUrl}. Start the backend and try again.';
    }
    return e.response?.statusMessage ?? 'Membership request failed.';
  }
}
