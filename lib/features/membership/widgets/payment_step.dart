import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/membership_service.dart';
import '../../../core/network/registration_service.dart';

class PaymentStep extends StatelessWidget {
  const PaymentStep({
    super.key,
    required this.plan,
    this.checkout,
    required this.onContinue,
    required this.loading,
    this.errorMessage,
  });

  final MembershipPlan plan;
  final CheckoutResult? checkout;
  final VoidCallback onContinue;
  final bool loading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Payment',
          style: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pay securely with Razorpay. After payment we confirm your '
          'registration on the completion step.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.bodyText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.displayPrice,
                style: GoogleFonts.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              if (checkout != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Order ID: ${checkout!.orderId}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: GoogleFonts.inter(color: AppColors.error, fontSize: 14),
          ),
        ],
        if (AppConfig.env == 'development') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8D9A8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Razorpay test mode (India)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Do not use 4111 1111 1111 1111 — it is treated as an '
                  'international card on Indian accounts.\n\n'
                  'Easiest: choose Netbanking → any bank → Success on the '
                  'mock page.\n\n'
                  'Or UPI: success@razorpay → Success.\n\n'
                  'Or Indian card: 5267 3181 8797 5449, any CVV, future expiry, '
                  'then enter any 4+ digit OTP on the bank page.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.bodyText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          key: const ValueKey('membership-payment-continue'),
          onPressed: loading ? null : onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Pay with Razorpay'),
        ),
      ],
    );
  }
}
