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

class CmsService {
  CmsService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

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

  static const galleryAlbums = [
    ('Grand Get-Together 2026', 'assets/images/gallery_01.webp'),
    ('Tricolour Stage Tribute', 'assets/images/gallery_02.webp'),
    ('Felicitation on Stage', 'assets/images/gallery_03.webp'),
    ('Alumni Speeches', 'assets/images/gallery_04.webp'),
    ("Chief Patron's Address", 'assets/images/gallery_05.webp'),
    ('Young Alumna Speaks', 'assets/images/gallery_06.webp'),
    ('Alumnae of KMC', 'assets/images/gallery_07.webp'),
    ('Welcome Desk', 'assets/images/gallery_08.webp'),
  ];
}
