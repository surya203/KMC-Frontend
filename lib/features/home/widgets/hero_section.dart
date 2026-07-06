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
    final isCompact = width < 700;
    final data = (stats ?? CommunityStats.fallback).heroDisplay;
    final headlineSize = width < 600 ? 40.0 : width < 900 ? 52.0 : 72.0;
    final heroHeight = isCompact ? 780.0 : 760.0;

    return SizedBox(
      height: heroHeight,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, isCompact ? 36 : 48, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
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
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: AppColors.secondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
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
                      SizedBox(height: isCompact ? 18 : 28),
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
                      SizedBox(height: isCompact ? 12 : 18),
                      Text(
                        'Connecting generations of medical excellence.',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: width < 600 ? 17 : 22,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isCompact ? 12 : 18),
                      Text(
                        'The official alumni engagement platform for Kakatiya Medical College, Warangal — uniting alumni batches, doctors, researchers, practicing doctors, clinical researchers, policy makers and pharmaceutical industry advisors across the world.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: width < 600 ? 14 : 17,
                          height: 1.7,
                        ),
                      ),
                      SizedBox(height: isCompact ? 18 : 28),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go('/membership'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: width < 400 ? 20 : 28,
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
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              padding: EdgeInsets.symmetric(
                                horizontal: width < 400 ? 20 : 28,
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
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, isCompact ? 20 : 24),
                child: _HeroStatsPanel(data: data, compact: isCompact),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatsPanel extends StatelessWidget {
  const _HeroStatsPanel({required this.data, required this.compact});

  final CommunityStats data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HeroStat(value: data.alumni, label: 'ALUMNI WORLDWIDE', compact: compact),
      _HeroStat(value: data.batches, label: 'GRADUATING BATCHES', compact: compact),
      _HeroStat(
        value: data.upcomingEvents == '1' ? 'ONE' : data.upcomingEvents,
        label: 'EVENT HOSTED',
        compact: compact,
      ),
      _HeroStat(
        value: data.globalMembers.replaceAll(',', ''),
        label: 'ACTIVE MEMBERS',
        compact: compact,
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 20,
        vertical: compact ? 18 : 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 700) {
            return Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: items[i]),
                ],
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 12),
                  Expanded(child: items[1]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: items[2]),
                  const SizedBox(width: 12),
                  Expanded(child: items[3]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.compact,
  });

  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(
            fontSize: compact ? 26 : 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: compact ? 10 : 11,
            letterSpacing: compact ? 0.8 : 1.2,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
