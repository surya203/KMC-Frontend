import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../network/events_service.dart';
import '../utils/date_format.dart';
import 'cover_image.dart';
import 'safe_asset_image.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    this.event,
    this.onTap,
    this.onRegister,
    this.showRegisterButton = true,
  });

  final EventSummary? event;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final bool showRegisterButton;

  @override
  Widget build(BuildContext context) {
    final data = event;
    final title = data?.title ?? '2nd KMC Alumni Meet';
    final dateLabel = data != null
        ? formatEventDate(data.startsAt)
        : '6 Jun 2027';
    final location = data?.locationLabel ?? 'HITEX Novotel, Hyderabad';
    final count = data?.registeredCount ?? 0;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            data != null
                ? CoverImage(imageUrl: data.coverImageUrl)
                : const SizedBox(
                    height: 240,
                    child: SafeAssetImage(
                      assetPath: AppAssets.eventBanner,
                      fit: BoxFit.cover,
                      expandToFill: true,
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _MetaRow(
                        icon: Icons.calendar_today_outlined,
                        label: dateLabel,
                      ),
                      _MetaRow(
                        icon: Icons.location_on_outlined,
                        label: location,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.heading,
                    ),
                  ),
                  if (showRegisterButton) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 18,
                          color: AppColors.bodyText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$count registered',
                            style: GoogleFonts.inter(
                              color: AppColors.bodyText,
                            ),
                          ),
                        ),
                        Semantics(
                          label: 'Register for $title',
                          button: true,
                          child: ElevatedButton(
                            onPressed: onRegister ?? onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.bodyText),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.bodyText,
          ),
        ),
      ],
    );
  }
}
