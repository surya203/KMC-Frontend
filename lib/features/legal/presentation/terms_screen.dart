import 'package:flutter/material.dart';

import '../../../core/constants/business_info.dart';
import '../widgets/legal_page_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPageScaffold(
      eyebrow: 'Legal',
      title: 'Terms and Conditions',
      subtitle:
          'These terms govern your use of ${BusinessInfo.brandName} and '
          'payments made through our platform.',
      sections: [
        LegalSection(
          heading: 'Introduction',
          body: [
            'Welcome to ${BusinessInfo.brandName}, operated by '
            '${BusinessInfo.legalName} ("we", "us", "our"). By accessing '
            'this website or making a payment, you agree to these Terms and '
            'Conditions. If you do not agree, please do not use our services.',
          ],
        ),
        LegalSection(
          heading: 'Services',
          body: [
            '${BusinessInfo.brandName} provides alumni membership registration, '
            'event participation, and related digital services for graduates '
            'and associates of Kakatiya Medical College, Warangal.',
            'Membership benefits, access levels, and platform features may be '
            'updated from time to time. We will communicate material changes '
            'through the platform or registered email.',
          ],
        ),
        LegalSection(
          heading: 'Membership & payments',
          body: [
            'Membership fees are displayed on the Pricing page and at checkout '
            'before payment. All prices are inclusive of applicable taxes '
            'unless stated otherwise.',
            'Membership payments are processed securely through Razorpay. By '
            'completing a payment, you confirm that the information provided is '
            'accurate and that you are authorised to use the selected payment '
            'method.',
            'Membership activation is subject to verification of your alumni '
            'credentials. We reserve the right to reject or revoke membership '
            'if submitted information is found to be false or misleading.',
          ],
        ),
        LegalSection(
          heading: 'User responsibilities',
          body: [
            'You are responsible for maintaining the confidentiality of your '
            'account credentials and for all activity under your account.',
            'You agree not to misuse the platform, impersonate others, upload '
            'unlawful content, or attempt to interfere with platform security.',
          ],
        ),
        LegalSection(
          heading: 'Limitation of liability',
          body: [
            'To the fullest extent permitted by law, ${BusinessInfo.legalName} '
            'shall not be liable for indirect, incidental, or consequential '
            'damages arising from use of the platform or payment processing '
            'delays caused by third-party providers.',
          ],
        ),
        LegalSection(
          heading: 'Governing law',
          body: [
            'These terms are governed by the laws of India. Any disputes shall '
            'be subject to the exclusive jurisdiction of courts in Warangal, '
            'Telangana.',
            'For questions about these terms, contact us at '
            '${BusinessInfo.email} or ${BusinessInfo.phone}.',
          ],
        ),
      ],
    );
  }
}
