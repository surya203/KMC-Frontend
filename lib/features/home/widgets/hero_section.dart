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

  static const _heroNavItems = [
    ('Home', '/'),
    ('About', '/about'),
    ('Events', '/events'),
    ('Gallery', '/gallery'),
    ('MY KMC', '/membership'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 700;
    final isDesktop = width >= 1100;
    final data = (stats ?? CommunityStats.fallback).heroDisplay;
    final headlineSize = width < 600
        ? 40.0
        : width < 900
        ? 52.0
        : isDesktop
        ? 58.0
        : 64.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: isCompact ? 720 : isDesktop ? 620 : 680,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const SafeAssetImage(
                  assetPath: AppAssets.hero,
                  fit: BoxFit.cover,
                  expandToFill: true,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xCC0B1736),
                        AppColors.heroOverlay,
                        const Color(0xB3162D5C),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              isCompact ? 20 : isDesktop ? 18 : 24,
              24,
              isCompact ? 20 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                SizedBox(height: isCompact ? 12 : 14),
                _HeroNavRow(
                  items: _heroNavItems,
                  compact: isCompact,
                ),
                SizedBox(height: isDesktop ? 20 : isCompact ? 18 : 28),
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
                    if (isDesktop)
                      Text(
                        ' Connect',
                        style: GoogleFonts.fraunces(
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                if (!isDesktop)
                  Text(
                    'Connect',
                    style: GoogleFonts.fraunces(
                      fontSize: headlineSize,
                      fontWeight: FontWeight.w600,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),
                SizedBox(height: isDesktop ? 12 : isCompact ? 12 : 18),
                Text(
                  'Connecting generations of medical excellence.',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: width < 600 ? 17 : isDesktop ? 20 : 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isDesktop ? 10 : isCompact ? 12 : 18),
                Text(
                  'The official alumni engagement platform for Kakatiya Medical College, Warangal — uniting alumni batches, doctors, researchers, practicing doctors, clinical researchers, policy makers and pharmaceutical industry advisors across the world.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: width < 600 ? 14 : isDesktop ? 16 : 17,
                    height: 1.65,
                  ),
                ),
                SizedBox(height: isDesktop ? 16 : isCompact ? 18 : 28),
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
                          vertical: isDesktop ? 16 : 18,
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
                          vertical: isDesktop ? 16 : 18,
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
                const SizedBox(height: 20),
                _HeroStatsPanel(data: data, compact: isCompact),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroNavRow extends StatelessWidget {
  const _HeroNavRow({
    required this.items,
    required this.compact,
  });

  final List<(String, String)> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Hide the overlay scrollbar so it never covers the tab buttons.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(width: compact ? 8 : 10),
              _HeroNavLink(
                label: items[i].$1,
                path: items[i].$2,
                compact: compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroNavLink extends StatelessWidget {
  const _HeroNavLink({
    required this.label,
    required this.path,
    required this.compact,
  });

  final String label;
  final String path;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 8 : 10,
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ),
        ),
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
