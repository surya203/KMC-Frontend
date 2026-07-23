import 'package:flutter/material.dart';

import '../../../core/constants/business_info.dart';
import '../widgets/legal_page_scaffold.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPageScaffold(
      eyebrow: 'Legal',
      title: 'Cancellation & Refund Policy',
      subtitle:
          'Clear timelines and conditions for membership payments.',
      sections: [
        LegalSection(
          heading: 'Membership fees',
          body: [
            'Membership registration fees are generally non-refundable once '
            'membership has been verified and activated on the platform.',
            'If your membership application is rejected during verification '
            'before activation, you may request a full refund within 7 days of '
            'payment by writing to ${BusinessInfo.email} with your payment '
            'reference and registered email.',
            'Approved refunds are processed to the original payment method '
            'within 5–7 business days. Bank or payment-provider processing '
            'times may vary.',
          ],
        ),
        LegalSection(
          heading: 'Cancellation',
          body: [
            'You may cancel a pending membership registration before payment '
            'is completed without any charge.',
            'After payment, cancellation requests before verification will be '
            'reviewed on a case-by-case basis. Contact ${BusinessInfo.phone} '
            'or ${BusinessInfo.email} during business hours '
            '(${BusinessInfo.supportHours}).',
          ],
        ),
        LegalSection(
          heading: 'Failed transactions',
          body: [
            'If a payment fails but your bank account is debited, the amount is '
            'typically auto-reversed by your bank or Razorpay within 5–7 '
            'business days. If not reversed within 10 business days, contact us '
            'with your transaction reference for assistance.',
          ],
        ),
        LegalSection(
          heading: 'How to request a refund',
          body: [
            'Email ${BusinessInfo.email} or message us on WhatsApp at '
            '${BusinessInfo.whatsapp} with your full name, registered email, '
            'payment ID or receipt, and reason for the request.',
            'We will acknowledge your request within 2 business days and '
            'provide a resolution within 7 business days.',
          ],
        ),
      ],
    );
  }
}
