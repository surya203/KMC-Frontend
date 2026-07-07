import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_service.dart';
import '../../../core/widgets/event_card.dart';
import 'section_header.dart';

class LatestEvents extends StatefulWidget {
  const LatestEvents({super.key});

  @override
  State<LatestEvents> createState() => _LatestEventsState();
}

class _LatestEventsState extends State<LatestEvents> {
  final _service = EventsService();
  List<EventSummary> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _service.fetchUpcoming();
    if (!mounted) return;
    setState(() => _events = events.take(1).toList());
  }

  @override
  Widget build(BuildContext context) {
    final event = _events.isNotEmpty ? _events.first : null;

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
                  child: EventCard(
                    event: event,
                    onTap: event != null
                        ? () => context.go('/events/${event.slug}')
                        : () => context.go('/events'),
                    onRegister: event != null
                        ? () => context.go('/events/${event.slug}')
                        : () => context.go('/events'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
