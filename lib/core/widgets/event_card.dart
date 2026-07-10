import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import 'safe_asset_image.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.venueLabel,
    required this.registeredCount,
    this.coverImageUrl,
    this.coverAssetPath,
    this.registrationOpen = true,
    this.isRegistered = false,
    this.onTap,
    this.onRegister,
  });

  final String title;
  final String dateLabel;
  final String venueLabel;
  final int registeredCount;
  final String? coverImageUrl;
  final String? coverAssetPath;
  final bool registrationOpen;
  final bool isRegistered;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final canRegister = registrationOpen && !isRegistered;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 240,
              child: _EventCoverImage(
                coverImageUrl: coverImageUrl,
                coverAssetPath: coverAssetPath,
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
                        label: venueLabel,
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
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackActions = constraints.maxWidth < 340;
                      final countLabel = '$registeredCount registered';
                      final buttonLabel = isRegistered
                          ? 'Registered'
                          : registrationOpen
                              ? 'Register'
                              : 'Closed';

                      if (stackActions) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: 18,
                                  color: AppColors.bodyText,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    countLabel,
                                    style: GoogleFonts.inter(
                                      color: AppColors.bodyText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                onPressed: canRegister ? onRegister : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      AppColors.muted.withValues(alpha: 0.4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(buttonLabel),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 18,
                            color: AppColors.bodyText,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              countLabel,
                              style: GoogleFonts.inter(
                                color: AppColors.bodyText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: canRegister ? onRegister : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.muted.withValues(alpha: 0.4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(buttonLabel),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCoverImage extends StatelessWidget {
  const _EventCoverImage({
    this.coverImageUrl,
    this.coverAssetPath,
  });

  final String? coverImageUrl;
  final String? coverAssetPath;

  @override
  Widget build(BuildContext context) {
    final asset = coverAssetPath;
    if (asset != null && asset.isNotEmpty) {
      return SafeAssetImage(
        assetPath: asset,
        fit: BoxFit.cover,
        expandToFill: true,
      );
    }
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
