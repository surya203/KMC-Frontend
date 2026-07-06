import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/cms_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _cmsService = CmsService();
  List<CmsMilestone> _milestones = CmsMilestone.fallback;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    final milestones = await _cmsService.fetchMilestones();
    if (!mounted) return;
    setState(() => _milestones = milestones);
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            PageHero(
              dark: true,
              eyebrow: 'About',
              title: HeadingStyles.pageHeroTitleWidget(
                context,
                dark: true,
                regular: 'Six decades of medical ',
                italic: 'excellence from Warangal.',
              ),
              subtitle:
                  'From its founding in Warangal to a global network of physicians, '
                  'surgeons, and healthcare leaders — Kakatiya Medical College has '
                  'shaped generations of medical excellence.',
            ),
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      TwoColumnSection(
                        heading: 'Our mission',
                        child: Text(
                          'We connect KMC alumni, practicing doctors, researchers, '
                          'academicians, and healthcare leaders across the globe — '
                          'fostering mentorship, reunions, and lifelong association '
                          'with our alma mater.',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            height: 1.8,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ),
                      TwoColumnSection(
                        heading: 'Milestones',
                        showDivider: false,
                        child: Column(
                          children: [
                            for (var i = 0; i < _milestones.length; i++) ...[
                              if (i > 0) const SizedBox(height: 28),
                              _MilestoneEntry(
                                key: ValueKey(
                                  'about-milestone-${_milestones[i].year}',
                                ),
                                year: _milestones[i].year,
                                title: _milestones[i].title,
                                description: _milestones[i].description,
                              ),
                            ],
                          ],
                        ),
                      ),
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

class _MilestoneEntry extends StatelessWidget {
  const _MilestoneEntry({
    super.key,
    required this.year,
    required this.title,
    required this.description,
  });

  final int year;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            '$year',
            style: GoogleFonts.fraunces(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
