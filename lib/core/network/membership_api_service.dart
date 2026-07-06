import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'api_client.dart';

class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.slug,
    required this.name,
    required this.pricePaise,
    required this.currency,
    required this.benefits,
    this.description,
  });

  final String id;
  final String slug;
  final String name;
  final int pricePaise;
  final String currency;
  final List<String> benefits;
  final String? description;

  String get displayPrice => '₹${(pricePaise / 100).round()}';

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    final rawBenefits = json['benefits'];
    return MembershipPlan(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      pricePaise: json['price_paise'] as int,
      currency: json['currency'] as String? ?? 'INR',
      description: json['description'] as String?,
      benefits: rawBenefits is List
          ? rawBenefits.map((e) => '$e').toList()
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
      draftId: json['draft_id'] as String,
      orderId: json['order_id'] as String,
      amountPaise: json['amount_paise'] as int,
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['key_id'] as String? ?? '',
    );
  }
}

class MemberMembership {
  const MemberMembership({
    required this.status,
    required this.planName,
    required this.planSlug,
    required this.votingRights,
  });

  final String status;
  final String planName;
  final String planSlug;
  final bool votingRights;

  factory MemberMembership.fromJson(Map<String, dynamic> json) {
    return MemberMembership(
      status: json['status'] as String,
      planName: json['plan_name'] as String,
      planSlug: json['plan_slug'] as String,
      votingRights: json['voting_rights'] as bool? ?? false,
    );
  }
}

class MembershipApiService {
  MembershipApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<MembershipPlan>> fetchPlans() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/plans',
      );
      final plans = response.data?['plans'] as List<dynamic>? ?? [];
      return plans
          .map((e) => MembershipPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<CheckoutSession> createCheckout(String draftId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/checkout',
        data: {'draft_id': draftId},
      );
      if (response.data == null) throw Exception('Checkout failed.');
      return CheckoutSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<MemberMembership> fetchMyMembership() async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/me',
        options: Options(headers: {'Authorization': header}),
      );
      if (response.data == null) throw Exception('No membership data.');
      return MemberMembership.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      return '${detail['detail']}';
    }
    return e.response?.statusMessage ?? 'Membership request failed.';
  }
}
