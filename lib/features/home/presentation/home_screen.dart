import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/footer_section.dart';
import '../widgets/gallery_preview.dart';
import '../widgets/hero_section.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/latest_events.dart';
import '../widgets/quick_actions.dart';
import '../widgets/stats_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HomeAppBar(),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(),
            QuickActions(),
            StatsSection(),
            LatestEvents(),
            GalleryPreview(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}