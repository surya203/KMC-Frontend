import 'package:flutter/material.dart';

import '../../../core/network/cms_service.dart';
import '../../../core/widgets/public_layout.dart';
import '../widgets/footer_section.dart';
import '../widgets/featured_alumni_section.dart';
import '../widgets/gallery_preview.dart';
import '../widgets/hero_section.dart';
import '../widgets/latest_events.dart';
import '../widgets/platform_features_section.dart';
import '../widgets/reconnect_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cmsService = CmsService();
  CommunityStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _cmsService.fetchStats();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(stats: _stats),
            const PlatformFeaturesSection(),
            const FeaturedAlumniSection(),
            const LatestEvents(),
            const GalleryPreview(),
            const ReconnectSection(),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}
