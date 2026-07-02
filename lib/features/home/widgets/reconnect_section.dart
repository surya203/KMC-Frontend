import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class ReconnectSection extends StatelessWidget {
  const ReconnectSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  '“A platform that finally honors the legacy of our institution. Reconnecting with my batch after 30 years felt seamless.”',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '— Dr. Bhanu Prasad, Batch of 1985, Cardiothoracic Surgeon',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 36),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.fraunces(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    children: [
                      const TextSpan(text: 'Ready to '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          color: AppColors.secondary,
                          child: Text(
                            'reconnect?',
                            style: GoogleFonts.fraunces(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verify your batch, claim your profile, and join thousands of KMC alumni already on the platform.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    height: 1.7,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/membership'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
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
                      onPressed: () => context.go('/membership'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text(
                        'View Membership Tiers',
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
      ),
    );
  }
}
