import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/widgets/event_card.dart';
import 'section_header.dart';

class LatestEvents extends StatefulWidget {
  const LatestEvents({super.key});

  @override
  State<LatestEvents> createState() => _LatestEventsState();
}

class _LatestEventsState extends State<LatestEvents> {
  final _api = EventsApiService();
  EventItem? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final events = await _api.fetchEvents(upcoming: true);
      if (!mounted) return;
      setState(() {
        _event = events.isNotEmpty ? events.first : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

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
              if (_loading)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_event != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: EventCard(
                      title: _event!.title,
                      dateLabel: _event!.displayDate,
                      venueLabel: _event!.displayVenue,
                      registeredCount: _event!.registeredCount,
                      coverImageUrl: _event!.coverImageUrl,
                      registrationOpen: _event!.registrationOpen,
                      isRegistered: _event!.isRegistered ?? false,
                      onTap: () => context.go('/events/${_event!.slug}'),
                      onRegister: () => context.go('/events/${_event!.slug}'),
                    ),
                  ),
                )
              else
                Text(
                  'No upcoming events yet. Check back soon.',
                  style: GoogleFonts.inter(color: AppColors.bodyText),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
