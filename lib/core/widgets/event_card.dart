import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import 'safe_asset_image.dart';

class EventCard extends StatelessWidget {
  const EventCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
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
                    children: const [
                      _MetaRow(
                        icon: Icons.calendar_today_outlined,
                        label: '6 Jun 2027',
                      ),
                      _MetaRow(
                        icon: Icons.location_on_outlined,
                        label: 'HITEX Novotel, Hyderabad',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '2nd KMC Alumni Meet',
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 18,
                        color: AppColors.bodyText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '0 registered',
                        style: GoogleFonts.inter(color: AppColors.bodyText),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: onTap,
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
                    ],
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
