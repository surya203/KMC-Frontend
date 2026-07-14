import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/widgets/event_card.dart';
import '../../events/widgets/dashboard_events_hero.dart';
import '../widgets/dashboard_layout.dart';

class DashboardEventsScreen extends StatefulWidget {
  const DashboardEventsScreen({super.key});

  @override
  State<DashboardEventsScreen> createState() => _DashboardEventsScreenState();
}

class _DashboardEventsScreenState extends State<DashboardEventsScreen> {
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

  EventItem? get _primaryEvent =>
      _upcoming.isNotEmpty ? _upcoming.first : null;

  void _openEventDetail(EventItem event) {
    context.go('/my-events/${event.slug}');
  }

  @override
  Widget build(BuildContext context) {
    final primary = _primaryEvent;
    final programCards =
        primary != null ? buildEventProgramCards(primary) : <EventProgramCardData>[];

    return SingleChildScrollView(
      padding: DashboardLayout.screenPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Text(
                'Upcoming',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                _ErrorBanner(message: _error!, onRetry: _loadEvents)
              else if (programCards.isEmpty)
                Text(
                  'No upcoming events yet. Check back soon.',
                  style: GoogleFonts.inter(color: AppColors.bodyText),
                )
              else
                _ProgramEventGrid(
                  programs: programCards,
                  onOpenDetail: _openEventDetail,
                ),
              if (!_loading && _error == null && _past.isNotEmpty) ...[
                const SizedBox(height: 40),
                Text(
                  'Past events',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 20),
                _PastEventGrid(
                  events: _past,
                  onOpen: _openEventDetail,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramEventGrid extends StatelessWidget {
  const _ProgramEventGrid({
    required this.programs,
    required this.onOpenDetail,
  });

  final List<EventProgramCardData> programs;
  final void Function(EventItem event) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.clamp(280.0, 400.0);

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            for (final program in programs)
              SizedBox(
                width: cardWidth,
                child: EventCard(
                  title: 'Alumni Meet 2027',
                  subtitle: 'details will be announced soon',
                  dateLabel: program.dateLabel,
                  venueLabel: program.venueLabel,
                  registeredCount: program.event.registeredCount,
                  coverAssetPath: AppAssets.eventBanner,
                  showRegistrationUi: false,
                  onTap: () => onOpenDetail(program.event),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PastEventGrid extends StatelessWidget {
  const _PastEventGrid({
    required this.events,
    required this.onOpen,
  });

  final List<EventItem> events;
  final void Function(EventItem event) onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.clamp(280.0, 400.0);

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            for (final event in events)
              SizedBox(
                width: cardWidth,
                child: EventCard(
                  title: event.title,
                  dateLabel: event.displayDate,
                  venueLabel: event.displayVenue,
                  registeredCount: event.registeredCount,
                  coverAssetPath: AppAssets.eventBanner,
                  showRegistrationUi: false,
                  onTap: () => onOpen(event),
                ),
              ),
          ],
        );
      },
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
