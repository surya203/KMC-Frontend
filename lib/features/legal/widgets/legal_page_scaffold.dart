import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/business_info.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class LegalSection {
  const LegalSection({required this.heading, required this.body});

  final String heading;
  final List<String> body;
}

class LegalPageScaffold extends StatelessWidget {
  const LegalPageScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.sections,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            PageHero(
              dark: true,
              eyebrow: eyebrow,
              title: HeadingStyles.pageHeroTitleWidget(
                context,
                dark: true,
                regular: title,
              ),
              subtitle: subtitle,
            ),
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last updated: ${BusinessInfo.lastPolicyUpdate}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 40),
                      for (var i = 0; i < sections.length; i++) ...[
                        if (i > 0) const SizedBox(height: 48),
                        TwoColumnSection(
                          heading: sections[i].heading,
                          showDivider: i < sections.length - 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var j = 0; j < sections[i].body.length; j++) ...[
                                if (j > 0) const SizedBox(height: 16),
                                Text(
                                  sections[i].body[j],
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    height: 1.75,
                                    color: AppColors.bodyText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
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
