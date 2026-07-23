import 'package:flutter/material.dart';

import '../../../core/constants/business_info.dart';
import '../widgets/legal_page_scaffold.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPageScaffold(
      eyebrow: 'Legal',
      title: 'Privacy Policy',
      subtitle:
          'How ${BusinessInfo.legalName} collects, uses, and protects your '
          'personal information.',
      sections: [
        LegalSection(
          heading: 'Information we collect',
          body: [
            'We collect information you provide during registration and membership, '
            'including your name, email address, phone number, batch year, '
            'specialisation, practice location, profile photo, and verification '
            'documents where applicable.',
            'When you make a payment, transaction details such as order ID, '
            'amount, payment status, and timestamp are recorded. Card and UPI '
            'details are processed directly by Razorpay and are not stored on '
            'our servers.',
            'We also collect technical data such as browser type, device '
            'information, and usage logs to maintain platform security and '
            'performance.',
          ],
        ),
        LegalSection(
          heading: 'How we use data',
          body: [
            'Your information is used to verify alumni membership, provide '
            'platform access, process membership payments, send service '
            'notifications, and improve our services.',
            'Directory visibility settings allow you to control what profile '
            'information is shown to other verified members.',
            'We do not sell your personal data to third parties.',
          ],
        ),
        LegalSection(
          heading: 'Data sharing',
          body: [
            'We share payment information with Razorpay solely to process '
            'transactions. Razorpay handles card and banking data according to '
            'its own privacy policy and PCI-DSS standards.',
            'We may disclose information when required by law, court order, or '
            'to protect the rights and safety of our members and organisation.',
          ],
        ),
        LegalSection(
          heading: 'Data retention & security',
          body: [
            'We retain membership and payment records for as long as your account '
            'is active and as required for legal, tax, and audit purposes.',
            'We implement reasonable technical and organisational measures to '
            'protect your data, including encrypted connections (HTTPS/TLS) and '
            'access controls on our systems.',
          ],
        ),
        LegalSection(
          heading: 'Your rights',
          body: [
            'You may request access to, correction of, or deletion of your '
            'personal data by contacting us. Some data may be retained where '
            'required by law or for legitimate business purposes.',
            'You can update profile visibility and contact preferences from '
            'your account settings after signing in.',
          ],
        ),
        LegalSection(
          heading: 'Contact',
          body: [
            'For privacy-related queries, contact ${BusinessInfo.legalName} at '
            '${BusinessInfo.email}, ${BusinessInfo.phone}, or '
            '${BusinessInfo.fullAddress}.',
          ],
        ),
      ],
    );
  }
}
