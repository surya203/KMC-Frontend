import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class RegistrationStepper extends StatelessWidget {
  const RegistrationStepper({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Registration progress',
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(child: Container(height: 1, color: AppColors.border)),
            Semantics(
              label: 'Step ${i + 1}: ${steps[i]}',
              selected: i == currentStep,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: i <= currentStep
                        ? AppColors.primary
                        : AppColors.muted,
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            i <= currentStep ? Colors.white : AppColors.bodyText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          i == currentStep ? FontWeight.w700 : FontWeight.w500,
                      color: i == currentStep
                          ? AppColors.heading
                          : AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
