import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/cms_service.dart';
import '../../../core/widgets/safe_asset_image.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, this.stats});

  final CommunityStats? stats;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final data = stats ?? CommunityStats.fallback;
    final headlineSize = width < 600 ? 44.0 : 72.0;

    return SizedBox(
      height: width < 700 ? 680 : 760,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const SafeAssetImage(
            assetPath: AppAssets.hero,
            fit: BoxFit.cover,
            expandToFill: true,
          ),
          Container(color: AppColors.heroOverlay),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Kakatiya Medical College · ESTD 1959',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'KMC ',
                      style: GoogleFonts.fraunces(
                        fontSize: headlineSize,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      color: AppColors.secondary,
                      child: Text(
                        'Alumni',
                        style: GoogleFonts.fraunces(
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Connect',
                  style: GoogleFonts.fraunces(
                    fontSize: headlineSize,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Connecting generations of medical excellence.',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: width < 600 ? 18 : 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'The official alumni engagement platform for Kakatiya Medical College, Warangal — uniting alumni batches, doctors, researchers, practicing doctors, clinical researchers, policy makers and pharmaceutical industry advisors across the world.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: width < 600 ? 15 : 17,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/membership'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text(
                        'Join Alumni Network',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/about'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text(
                        'Explore Platform',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final items = [
                    _HeroStat(value: data.alumni, label: 'ALUMNI WORLDWIDE'),
                    _HeroStat(value: data.batches, label: 'GRADUATING BATCHES'),
                    _HeroStat(
                      value: data.upcomingEvents == '1'
                          ? 'ONE'
                          : data.upcomingEvents,
                      label: 'EVENT HOSTED',
                    ),
                    _HeroStat(
                      value: data.globalMembers.replaceAll(',', ''),
                      label: 'ACTIVE MEMBERS',
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: items[i]),
                        ],
                      ],
                    );
                  }

                  return Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: items
                        .map((item) => SizedBox(width: 140, child: item))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.fraunces(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
