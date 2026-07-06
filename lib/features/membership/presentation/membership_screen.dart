import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/page_intro.dart';
import '../../../core/widgets/public_layout.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  static const _steps = [
    'Plan',
    'Details',
    'Verify',
    'Payment',
    'Complete',
  ];

  static const _benefits = [
    'Verified alumni profile in the MY KMC directory',
    'Event registration & reminders',
    'Voting Rights',
  ];

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      showFooter: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                const PageIntro(title: 'Join the Alumni Network'),
                const SizedBox(height: 36),
                _StepperRow(steps: _steps),
                const SizedBox(height: 36),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Life Membership',
                        style: GoogleFonts.fraunces(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'One plan. Every benefit. Lifetime access.',
                        style: GoogleFonts.inter(
                          color: AppColors.bodyText,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹1,000',
                            style: GoogleFonts.fraunces(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: AppColors.heading,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'one-time',
                              style: GoogleFonts.inter(
                                color: AppColors.bodyText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      for (final benefit in _benefits) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                benefit,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AppColors.heading,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Join for ₹1,000',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _StepperRow extends StatelessWidget {
  const _StepperRow({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.border,
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    i == 0 ? AppColors.primary : AppColors.muted,
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: i == 0 ? Colors.white : AppColors.bodyText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                steps[i],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                  color: i == 0 ? AppColors.heading : AppColors.bodyText,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
