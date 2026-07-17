import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'section_header.dart';

class PlatformFeaturesSection extends StatelessWidget {
  const PlatformFeaturesSection({super.key});

  static const _features = [
    (
      Icons.person_add_alt_1_outlined,
      'Alumni Registration',
      'Verified, specialty, location and batch-tagged profiles for every graduate.',
      '/membership',
    ),
    (
      Icons.verified_user_outlined,
      'Life Membership',
      'Lifetime membership and access to all alumni batches.',
      '/membership',
    ),
    (
      Icons.campaign_outlined,
      'Announcements',
      'Direct messages from President, Secretary, Treasurer and Admin Office.',
      null,
    ),
    (
      Icons.event_outlined,
      'Reunion Events',
      'Register, Revisit, Rejuvenate and Discover alumni experience.',
      '/events',
    ),
    (
      Icons.photo_library_outlined,
      'Alumni Gallery',
      'Decades of memories available to refresh.',
      '/gallery',
    ),
    (
      Icons.notifications_active_outlined,
      'Smart Notifications',
      'Stay informed through the bell icon of the app, email and mobile.',
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
                italicTitle: 'exquisitely unified with rare elegance.',
                subtitle:
                    'Member onboarding to alumni, KMC Alumni Connect is built as a single, modern Software as a Service experience.',
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
                    for (var row = 0;
                        row < (_features.length / columns).ceil();
                        row++)
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
        return _FeatureCell(
          icon: feature.$1,
          title: feature.$2,
          description: feature.$3,
          route: feature.$4,
          showBottomBorder: !isLastRow,
        );
      },
    );
  }
}

class _FeatureCell extends StatefulWidget {
  const _FeatureCell({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.showBottomBorder,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? route;
  final bool showBottomBorder;

  @override
  State<_FeatureCell> createState() => _FeatureCellState();
}

class _FeatureCellState extends State<_FeatureCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? const Color(0xFFF5F0E6) : Colors.transparent,
        child: InkWell(
          onTap: widget.route == null ? null : () => context.go(widget.route!),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: widget.showBottomBorder
                    ? const BorderSide(color: AppColors.border)
                    : BorderSide.none,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hovered ? AppColors.primary : AppColors.muted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color: _hovered ? Colors.white : AppColors.bodyText,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
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
      ),
    );
  }
}
