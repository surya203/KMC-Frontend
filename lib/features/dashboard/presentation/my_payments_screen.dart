import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/membership_api_service.dart';

class MyPaymentsScreen extends StatefulWidget {
  const MyPaymentsScreen({super.key});

  @override
  State<MyPaymentsScreen> createState() => _MyPaymentsScreenState();
}

class _MyPaymentsScreenState extends State<MyPaymentsScreen> {
  final _api = MembershipApiService();

  List<PaymentHistoryItem> _payments = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payments = await _api.fetchMyPayments();
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payments',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Receipts and membership payment history.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _ErrorBanner(message: _error!, onRetry: _load),
                const SizedBox(height: 16),
              ],
              if (_payments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No payments recorded yet.',
                    style: GoogleFonts.inter(color: AppColors.bodyText),
                  ),
                )
              else
                for (final payment in _payments) ...[
                  _PaymentCard(payment: payment),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final PaymentHistoryItem payment;

  @override
  Widget build(BuildContext context) {
    final captured = payment.status == 'captured';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: captured
                  ? Colors.green.shade50
                  : AppColors.muted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              captured ? Icons.receipt_long : Icons.schedule,
              color: captured ? Colors.green.shade700 : AppColors.bodyText,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.displayAmount,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(payment.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),
                if (payment.providerPaymentId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${payment.providerPaymentId}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: captured ? Colors.green.shade50 : AppColors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              payment.status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: captured ? Colors.green.shade800 : AppColors.bodyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 14),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
