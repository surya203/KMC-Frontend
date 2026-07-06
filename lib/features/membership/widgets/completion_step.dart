import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/registration_service.dart';

class CompletionStep extends StatelessWidget {
  const CompletionStep({
    super.key,
    required this.result,
    this.pendingMessage,
    required this.onRetry,
    required this.retrying,
  });

  final CompleteRegistrationResult? result;
  final String? pendingMessage;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final completed = result?.completed == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          completed ? Icons.check_circle_outline : Icons.info_outline,
          size: 56,
          color: completed ? AppColors.secondary : AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          completed ? 'Registration complete' : 'Almost there',
          style: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          completed
              ? (result?.message ??
                  'Your account is ready. Sign in with your email and password.')
              : (pendingMessage ??
                  'Payment is not confirmed yet. Complete the Razorpay payment, then check the status again.'),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.bodyText,
            height: 1.5,
          ),
        ),
        if (result?.debugPassword != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Dev temporary password (legacy auto-generated accounts only): '
              '${result!.debugPassword}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.heading,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (!completed)
          OutlinedButton(
            key: const ValueKey('membership-complete-retry'),
            onPressed: retrying ? null : onRetry,
            child: retrying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Check registration status'),
          ),
        if (completed) ...[
          ElevatedButton(
            key: const ValueKey('membership-go-sign-in'),
            onPressed: () => context.go('/auth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Sign in to MY KMC'),
          ),
        ],
      ],
    );
  }
}
