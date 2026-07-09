import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

/// Rounded hero image for the dashboard events page.
/// Image file: assets/images/events_upcoming_hero.png
class EventHeroImage extends StatelessWidget {
  const EventHeroImage({
    super.key,
    this.height = 220,
    this.borderRadius = 16,
    this.assetPath = AppAssets.eventsUpcomingHero,
  });

  final double height;
  final double borderRadius;
  final String assetPath;

  String get _fileName => assetPath.split('/').last;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _PlaceholderBox(
            height: height,
            borderRadius: borderRadius,
            fileName: _fileName,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({
    required this.height,
    required this.borderRadius,
    required this.fileName,
  });

  final double height;
  final double borderRadius;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 40,
            color: AppColors.mutedText.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          Text(
            fileName,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save your image in assets/images/',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
