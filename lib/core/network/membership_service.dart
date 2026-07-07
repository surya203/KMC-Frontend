import '../config/app_config.dart';
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

  String get displayPrice {
    final rupees = pricePaise / 100;
    if (rupees == rupees.roundToDouble()) {
      return '₹${rupees.toInt()}';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }

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
}
