import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

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

  String get displayPrice => _formatPaise(pricePaise);

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    final benefits = json['benefits'];
    return MembershipPlan(
      id: '${json['id']}',
      slug: '${json['slug']}',
      name: '${json['name']}',
      pricePaise: json['price_paise'] is int
          ? json['price_paise'] as int
          : int.tryParse('${json['price_paise']}') ?? 0,
      currency: '${json['currency'] ?? 'INR'}',
      description: json['description'] as String?,
      benefits: benefits is List
          ? [for (final item in benefits) '$item']
          : const [],
    );
  }

  static const fallback = MembershipPlan(
    id: 'life',
    slug: 'life',
    name: 'Life Membership',
    pricePaise: 100000,
    currency: 'INR',
    description: 'One plan. Every benefit. Lifetime access.',
    benefits: [
      'Verified alumni profile in the MY KMC directory',
      'Event registration & reminders',
      'Voting Rights',
    ],
  );
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

class MembershipRecord {
  const MembershipRecord({
    required this.status,
    required this.planName,
    required this.planSlug,
    required this.votingRights,
    required this.feePaise,
    required this.generalDonationPaise,
    required this.projectDonationPaise,
    required this.projectDonations,
    this.membershipNumber,
    this.registrationDate,
    this.paymentDate,
  });

  final String status;
  final String planName;
  final String planSlug;
  final bool votingRights;
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

  factory MembershipRecord.fromJson(Map<String, dynamic> json) {
    final projects = json['project_donations'];
    return MembershipRecord(
      status: '${json['status']}',
      planName: '${json['plan_name']}',
      planSlug: '${json['plan_slug']}',
      votingRights: json['voting_rights'] == true,
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

class MembershipService {
  MembershipService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<MembershipPlan>> fetchPlans() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/plans',
      );
      final plans = response.data?['plans'];
      if (response.statusCode == 200 && plans is List && plans.isNotEmpty) {
        return [
          for (final item in plans)
            if (item is Map<String, dynamic>)
              MembershipPlan.fromJson(item),
        ];
      }
    } catch (_) {
      // Fall back to handbook defaults when plans API is offline.
    }
    return [MembershipPlan.fallback];
  }

  Future<MembershipRecord> fetchMyMembership() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/me',
      );
      if (response.statusCode == 200 && response.data != null) {
        return MembershipRecord.fromJson(response.data!);
      }
      throw const ApiException('Could not load membership record.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<List<DonationCategory>> fetchDonationCategories() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/donations/categories',
      );
      final items = response.data?['categories'];
      if (response.statusCode == 200 && items is List) {
        return [
          for (final item in items)
            if (item is Map<String, dynamic>)
              DonationCategory.fromJson(item),
        ];
      }
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
    return const [];
  }

  Future<List<DonationRecord>> fetchMyDonations() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/donations',
      );
      final items = response.data?['donations'];
      if (response.statusCode == 200 && items is List) {
        return [
          for (final item in items)
            if (item is Map<String, dynamic>)
              DonationRecord.fromJson(item),
        ];
      }
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
    return const [];
  }

  Future<DonationCheckout> createDonationCheckout({
    required int amountPaise,
    required String donationType,
    String? projectCategory,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/donations/checkout',
        data: {
          'amount_paise': amountPaise,
          'donation_type': donationType,
          if (projectCategory != null) 'project_category': projectCategory,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return DonationCheckout.fromJson(response.data!);
      }
      throw const ApiException('Could not start donation checkout.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<String> completeDonation(String orderId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/membership/donations/complete',
        data: {'order_id': orderId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return '${response.data!['message']}';
      }
      throw const ApiException('Could not confirm donation.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }
}
