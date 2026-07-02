import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/event_card.dart';
import 'section_header.dart';

class LatestEvents extends StatelessWidget {
  const LatestEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.muted,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                eyebrow: 'Upcoming Events',
                center: false,
                regularTitle: 'Where the KMC family ',
                italicTitle: 'gathers.',
                actionLabel: 'View all',
                onAction: () => context.go('/events'),
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: EventCard(onTap: () => context.go('/events')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
