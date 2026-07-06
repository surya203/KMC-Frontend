import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'section_header.dart';

class PlatformFeaturesSection extends StatelessWidget {
  const PlatformFeaturesSection({super.key});

  static const _features = [
    (
      Icons.verified_user_outlined,
      'Alumni Registration',
      'Verified, batch-tagged profiles for every graduate.',
      '/membership',
    ),
    (
      Icons.card_membership_outlined,
      'Membership Plans',
      'Lifetime and Patron tiers with rich benefits.',
      '/membership',
    ),
    (
      Icons.campaign_outlined,
      'Announcements',
      'Direct messages from President, Treasurer & Office.',
      null,
    ),
    (
      Icons.event_outlined,
      'Reunion Events',
      'Discover, register, and revisit alumni gatherings.',
      '/events',
    ),
    (
      Icons.photo_library_outlined,
      'Alumni Gallery',
      'Decades of memories, curated and searchable.',
      '/gallery',
    ),
    (
      Icons.notifications_active_outlined,
      'Smart Notifications',
      'Stay informed across web, email, and mobile.',
      null,
    ),
    (
      Icons.insights_outlined,
      'Member Analytics',
      'Track engagement, attendance, and contributions.',
      null,
    ),
    (
      Icons.admin_panel_settings_outlined,
      'Admin Controls',
      'Role-based dashboards for the executive committee.',
      null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 1100 ? 4 : width > 700 ? 2 : 1;

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              SectionHeader(
                eyebrow: 'Platform',
                regularTitle: 'Everything an alumni association needs,\n',
                italicTitle: 'beautifully unified.',
                subtitle:
                    'From member onboarding to reunion logistics, KMC Alumni Connect is built as a single, modern SaaS experience.',
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var row = 0; row < (_features.length / columns).ceil(); row++)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var col = 0; col < columns; col++) ...[
                              if (col > 0)
                                const VerticalDivider(
                                  width: 1,
                                  color: AppColors.border,
                                ),
                              Expanded(
                                child: _cellAt(row, col, columns),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cellAt(int row, int col, int columns) {
    final index = row * columns + col;
    if (index >= _features.length) {
      return const SizedBox.shrink();
    }

    final feature = _features[index];
    final isLastRow = row == (_features.length / columns).ceil() - 1;

    return Builder(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: feature.$4 == null ? null : () => context.go(feature.$4!),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLastRow
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(feature.$1, color: AppColors.bodyText, size: 22),
                  const SizedBox(height: 16),
                  Text(
                    feature.$2,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature.$3,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
