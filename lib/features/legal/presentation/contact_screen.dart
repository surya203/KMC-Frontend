import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/business_info.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            PageHero(
              dark: true,
              eyebrow: 'Contact',
              title: HeadingStyles.pageHeroTitleWidget(
                context,
                dark: true,
                regular: 'Get in touch with the alumni office.',
              ),
              subtitle:
                  'We are here to help with membership, payments, events, '
                  'and platform support.',
            ),
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;

                      final details = _ContactDetailsCard(onLaunch: _launch);
                      final hours = _SupportHoursCard();

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: details),
                            const SizedBox(width: 32),
                            Expanded(child: hours),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          details,
                          const SizedBox(height: 24),
                          hours,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _ContactDetailsCard extends StatelessWidget {
  const _ContactDetailsCard({required this.onLaunch});

  final Future<void> Function(Uri uri) onLaunch;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Registered business details',
      children: [
        _ContactRow(
          label: 'Legal entity',
          value: BusinessInfo.legalName,
        ),
        _ContactRow(
          label: 'Platform',
          value: BusinessInfo.brandName,
        ),
        _ContactLinkRow(
          label: 'Website',
          value: BusinessInfo.websiteHost,
          onTap: () => onLaunch(Uri.parse(BusinessInfo.websiteUrl)),
        ),
        _ContactRow(
          label: 'Address',
          value: BusinessInfo.fullAddress,
        ),
        _ContactLinkRow(
          label: 'Email',
          value: BusinessInfo.email,
          onTap: () => onLaunch(
            Uri(scheme: 'mailto', path: BusinessInfo.email),
          ),
        ),
        _ContactLinkRow(
          label: 'Phone',
          value: BusinessInfo.phone,
          onTap: () => onLaunch(
            Uri(scheme: 'tel', path: BusinessInfo.phone.replaceAll(' ', '')),
          ),
        ),
        _ContactLinkRow(
          label: 'WhatsApp',
          value: BusinessInfo.whatsapp,
          onTap: () => onLaunch(
            Uri.parse(
              'https://wa.me/${BusinessInfo.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}',
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportHoursCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Support hours',
      children: [
        Text(
          BusinessInfo.supportHours,
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.75,
            color: AppColors.bodyText,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'For membership verification, payment issues, refund requests, or '
          'general enquiries, reach us by email or WhatsApp. We aim to respond '
          'within 2 business days.',
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.75,
            color: AppColors.bodyText,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Payment-related queries should include your registered email and '
          'Razorpay payment ID or receipt reference for faster resolution.',
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.75,
            color: AppColors.bodyText,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.5,
              color: AppColors.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLinkRow extends StatelessWidget {
  const _ContactLinkRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.5,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
