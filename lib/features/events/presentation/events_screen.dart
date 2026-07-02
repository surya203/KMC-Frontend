import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/event_card.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            PageHero(
              eyebrow: 'Events',
              title: HeadingStyles.pageHeroTitleWidget(
                context,
                regular: 'Reunions, symposia, ',
                italic: 'and small ceremonies.',
              ),
              subtitle:
                  'Every gathering of the KMC family — on campus, across India, and online.',
            ),
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 72),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming',
                        style: HeadingStyles.contentColumnHeading,
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: const EventCard(),
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
