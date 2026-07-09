import '../config/app_config.dart';
import 'api_client.dart';

class CommunityStats {
  const CommunityStats({
    required this.alumni,
    required this.batches,
    required this.upcomingEvents,
    required this.globalMembers,
    this.fromApi = false,
  });

  final String alumni;
  final String batches;
  final String upcomingEvents;
  final String globalMembers;
  final bool fromApi;

  static const fallback = CommunityStats(
    alumni: '15,000+',
    batches: '60+',
    upcomingEvents: 'ONE',
    globalMembers: '1000+',
    fromApi: false,
  );

  factory CommunityStats.fromJson(Map<String, dynamic> json) {
    return CommunityStats(
      alumni: '${json['alumni_count'] ?? '15,000+'}',
      batches: '${json['batch_count'] ?? '60+'}',
      upcomingEvents: '${json['upcoming_events'] ?? 'ONE'}',
      globalMembers: '${json['active_members'] ?? '1000+'}',
      fromApi: true,
    );
  }
}

class CmsMilestone {
  const CmsMilestone({
    required this.year,
    required this.title,
    required this.description,
    required this.sortOrder,
  });

  final int year;
  final String title;
  final String description;
  final int sortOrder;

  static const fallback = [
    CmsMilestone(
      year: 1959,
      title: 'Founded',
      description:
          'Kakatiya Medical College established in Warangal, Telangana.',
      sortOrder: 1,
    ),
    CmsMilestone(
      year: 1985,
      title: 'Postgraduate Programs',
      description:
          'Expansion of specialist training and research across departments.',
      sortOrder: 2,
    ),
    CmsMilestone(
      year: 2008,
      title: 'Golden Jubilee',
      description:
          'Celebrating fifty years of medical education and alumni pride.',
      sortOrder: 3,
    ),
    CmsMilestone(
      year: 2025,
      title: 'Digital Alumni Platform',
      description: 'KMC Alumni Connect launches to unite batches worldwide.',
      sortOrder: 4,
    ),
  ];

  factory CmsMilestone.fromJson(Map<String, dynamic> json, int index) {
    return CmsMilestone(
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse('${json['year']}') ?? 0,
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse('${json['sort_order']}') ?? index + 1,
    );
  }
}

class CmsService {
  CmsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<CommunityStats> fetchStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/cms/stats',
      );
      if (response.statusCode == 200 && response.data != null) {
        return CommunityStats.fromJson(response.data!);
      }
    } catch (_) {
      // Backend CMS endpoint may not exist yet — use handbook defaults.
    }
    return CommunityStats.fallback;
  }

  Future<List<CmsMilestone>> fetchMilestones() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/cms/milestones',
      );
      final data = response.data?['milestones'];
      if (response.statusCode == 200 && data is List) {
        final milestones = [
          for (var i = 0; i < data.length; i++)
            if (data[i] is Map<String, dynamic>)
              CmsMilestone.fromJson(data[i] as Map<String, dynamic>, i),
        ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (milestones.isNotEmpty) {
          return milestones;
        }
      }
    } catch (_) {
      // Keep the About page usable when the Phase 1 CMS endpoint is offline.
    }
    return CmsMilestone.fallback;
  }
}
