import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/widgets/event_card.dart';

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
  String? _registeringId;

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

  Future<void> _register(EventItem event) async {
    setState(() => _registeringId = event.id);
    try {
      await _api.registerForEvent(event.id);
      if (!mounted) return;
      setState(() => _registeringId = null);
      await _loadEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered for ${event.title}.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _registeringId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events',
                  style: GoogleFonts.fraunces(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reunions, CME symposia and alumni meet registrations.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.bodyText,
                    height: 1.5,
                  ),
                ),
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
                else if (_upcoming.isEmpty)
                  Text(
                    'No upcoming events yet. Check back soon.',
                    style: GoogleFonts.inter(color: AppColors.bodyText),
                  )
                else
                  _EventGrid(
                    events: _upcoming,
                    registeringId: _registeringId,
                    onRegister: _register,
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
                  _EventGrid(
                    events: _past,
                    registeringId: _registeringId,
                    onRegister: _register,
                  ),
                ],
              ],
            ),
          ),
        ),
    );
  }
}

class _EventGrid extends StatelessWidget {
  const _EventGrid({
    required this.events,
    required this.registeringId,
    required this.onRegister,
  });

  final List<EventItem> events;
  final String? registeringId;
  final Future<void> Function(EventItem event) onRegister;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        for (final event in events)
          SizedBox(
            width: 400,
            child: EventCard(
              title: event.title,
              dateLabel: event.displayDate,
              venueLabel: event.displayVenue,
              registeredCount: event.registeredCount,
              coverImageUrl: event.coverImageUrl,
              registrationOpen: event.registrationOpen,
              isRegistered: event.isRegistered ?? false,
              onTap: () => context.go('/events/${event.slug}'),
              onRegister: registeringId == event.id
                  ? null
                  : () => onRegister(event),
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
