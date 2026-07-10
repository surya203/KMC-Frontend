import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/widgets/safe_asset_image.dart';

/// Header block for the dashboard events page with a custom hero image.
class DashboardEventsHero extends StatelessWidget {
  const DashboardEventsHero({super.key, this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: 220,
            child: _HeroCoverImage(coverImageUrl: coverImageUrl),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Events',
          style: GoogleFonts.fraunces(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Reunions, CME symposia and alumni meet registrations.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.bodyText,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// One registerable program card shown on the events page.
class EventProgramCardData {
  const EventProgramCardData({
    required this.title,
    required this.programTrack,
    required this.event,
  });

  final String title;
  final String programTrack;
  final EventItem event;

  String get dateLabel => event.displayDate;
  String get venueLabel => event.displayVenue;
}

List<EventProgramCardData> buildEventProgramCards(EventItem event) {
  const defaultTitles = [
    'Scientific Sessions',
    'CME Programs',
    'NRI Programs',
  ];

  final tracks = event.programs.length >= 3
      ? event.programs.take(3).toList()
      : <String>[
          event.title,
          defaultTitles[1],
          defaultTitles[2],
        ];

  return [
    for (final track in tracks)
      EventProgramCardData(
        title: track,
        programTrack: track,
        event: event,
      ),
  ];
}

bool isRegisteredForProgramTrack(
  List<MyEventRegistration> registrations,
  String eventId,
  String programTrack,
) {
  for (final reg in registrations) {
    if (reg.eventId != eventId) continue;
    if (reg.registrationKind == 'attendance' &&
        reg.programTracks.any(
          (t) => t.toLowerCase() == programTrack.toLowerCase(),
        )) {
      return true;
    }
  }
  return false;
}

class _HeroCoverImage extends StatelessWidget {
  const _HeroCoverImage({this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final url = coverImageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorWidget: (context, url, error) => const SafeAssetImage(
          assetPath: AppAssets.eventBanner,
          fit: BoxFit.cover,
          expandToFill: true,
        ),
      );
    }
    return const SafeAssetImage(
      assetPath: AppAssets.eventBanner,
      fit: BoxFit.cover,
      expandToFill: true,
    );
  }
}
