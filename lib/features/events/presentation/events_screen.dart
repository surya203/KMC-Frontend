import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/event_card.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _api = EventsApiService();
  List<EventItem> _upcoming = [];
  List<EventItem> _past = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchEvents(upcoming: true),
        _api.fetchEvents(upcoming: false),
      ]);
      if (!mounted) return;
      final upcoming = results[0];
      final all = results[1];
      final upcomingIds = upcoming.map((e) => e.id).toSet();
      setState(() {
        _upcoming = upcoming;
        _past = all.where((e) => !upcomingIds.contains(e.id)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

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
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        _ErrorBanner(
                          message: _error!,
                          onRetry: _loadEvents,
                        )
                      else ...[
                        if (_upcoming.isEmpty)
                          Text(
                            'No upcoming events yet. Check back soon.',
                            style: GoogleFonts.inter(color: AppColors.bodyText),
                          )
                        else
                          _EventGrid(events: _upcoming),
                        if (_past.isNotEmpty) ...[
                          const SizedBox(height: 48),
                          Text(
                            'Past events',
                            style: HeadingStyles.contentColumnHeading,
                          ),
                          const SizedBox(height: 28),
                          _EventGrid(events: _past),
                        ],
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

class _EventGrid extends StatelessWidget {
  const _EventGrid({required this.events});

  final List<EventItem> events;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        for (final event in events)
          SizedBox(
            width: 520,
            child: EventCard(
              title: event.title,
              dateLabel: event.displayDate,
              venueLabel: event.displayVenue,
              registeredCount: event.registeredCount,
              coverImageUrl: event.coverImageUrl,
              registrationOpen: event.registrationOpen,
              isRegistered: event.isRegistered ?? false,
              onTap: () => context.go('/events/${event.slug}'),
              onRegister: () => context.go('/events/${event.slug}'),
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(color: AppColors.bodyText),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
