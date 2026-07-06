import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class TestimonialSection extends StatelessWidget {
  const TestimonialSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.muted,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Text(
                '“A platform that finally honors the legacy of our institution. Reconnecting with my batch after 30 years felt seamless.”',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '— Dr. Bhanu Prasad, Batch of 1985, Cardiothoracic Surgeon',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
