import 'package:flutter/material.dart';

import '../../../core/constants/business_info.dart';
import '../widgets/legal_page_scaffold.dart';

class ShippingPolicyScreen extends StatelessWidget {
  const ShippingPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPageScaffold(
      eyebrow: 'Legal',
      title: 'Shipping & Delivery Policy',
      subtitle:
          'How membership and digital services are delivered after payment.',
      sections: [
        LegalSection(
          heading: 'Nature of services',
          body: [
            '${BusinessInfo.brandName} provides digital membership and alumni '
            'services. We do not sell or ship physical products through this '
            'platform.',
          ],
        ),
        LegalSection(
          heading: 'Membership delivery',
          body: [
            'Upon successful payment and verification of your alumni credentials, '
            'your membership is activated digitally on the platform.',
            'You will receive access to member dashboard features, directory '
            'listing (subject to your privacy settings), events, announcements, '
            'and other membership benefits as described on the Pricing page.',
            'Activation typically occurs within 2–5 business days after payment, '
            'depending on verification workload. You will be notified by email '
            'once your membership is approved.',
          ],
        ),
        LegalSection(
          heading: 'Digital receipts',
          body: [
            'Payment receipts are available for download from your account under '
            'My Payments after successful transaction. Receipts are delivered '
            'electronically; no physical documents are mailed unless separately '
            'arranged by the alumni office.',
          ],
        ),
        LegalSection(
          heading: 'Support',
          body: [
            'For delivery or access issues, contact the alumni office at '
            '${BusinessInfo.email}, ${BusinessInfo.phone}, or visit '
            '${BusinessInfo.fullAddress} during ${BusinessInfo.supportHours}.',
          ],
        ),
      ],
    );
  }
}
