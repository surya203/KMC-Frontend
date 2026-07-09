import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../network/events_api_service.dart';
import '../network/events_service.dart';
import '../utils/date_format.dart';
import 'cover_image.dart';
import 'event_hero_image.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    this.event,
    this.onTap,
    this.onRegister,
    this.showRegisterButton = true,
    this.showHeroImage = true,
    this.heroAssetPath,
  });

  factory EventCard.fromEventItem(
    EventItem item, {
    Key? key,
    VoidCallback? onTap,
    VoidCallback? onRegister,
    bool showRegisterButton = true,
    bool showHeroImage = true,
    String? heroAssetPath,
  }) {
    return EventCard(
      key: key,
      event: EventSummary(
        id: item.id,
        slug: item.slug,
        title: item.title,
        startsAt: item.startsAt.toIso8601String(),
        registeredCount: item.registeredCount,
        venueName: item.venueName,
        city: item.city,
        coverImageUrl: item.coverImageUrl,
        registrationOpen: item.registrationOpen,
        isOnline: item.isOnline,
      ),
      onTap: onTap,
      onRegister: onRegister,
      showRegisterButton: showRegisterButton,
      showHeroImage: showHeroImage,
      heroAssetPath: heroAssetPath,
    );
  }

  final EventSummary? event;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final bool showRegisterButton;
  final bool showHeroImage;
  final String? heroAssetPath;

  @override
  Widget build(BuildContext context) {
    final data = event;
    final title = _displayTitle(data);
    final dateLabel = _displayDate(data);
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
            if (showHeroImage)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: heroAssetPath != null || data == null
                    ? EventHeroImage(
                        height: 320,
                        borderRadius: 16,
                        assetPath:
                            heroAssetPath ?? AppAssets.eventsUpcomingHero,
                      )
                    : CoverImage(imageUrl: data.coverImageUrl),
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

String _displayTitle(EventSummary? data) {
  if (data == null) return 'Scientific Sessions';
  if (data.slug == '2nd-kmc-alumni-meet' ||
      data.title == '2nd KMC Alumni Meet') {
    return 'Scientific Sessions';
  }
  return data.title;
}

String _displayDate(EventSummary? data) {
  if (data == null) return '5 Jun 2027';
  if (data.slug == '2nd-kmc-alumni-meet') return '5 Jun 2027';
  return formatEventDate(data.startsAt);
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
