import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../widgets/dashboard_layout.dart';
import '../../../core/widgets/event_card.dart';
import '../../events/widgets/dashboard_events_hero.dart';
import '../../events/widgets/event_basic_registration_dialog.dart';

class DashboardEventsScreen extends StatefulWidget {
  const DashboardEventsScreen({super.key});

  @override
  State<DashboardEventsScreen> createState() => _DashboardEventsScreenState();
}

class _DashboardEventsScreenState extends State<DashboardEventsScreen> {
  final _api = EventsApiService();

  List<EventItem> _upcoming = [];
  List<EventItem> _past = [];
  List<MyEventRegistration> _myRegistrations = [];
  String? _error;
  bool _loading = true;
  String? _registeringTrack;

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
        _api.fetchMyRegistrations(),
      ]);
      if (!mounted) return;
      final upcoming = results[0] as List<EventItem>;
      final all = results[1] as List<EventItem>;
      final myRegs = results[2] as List<MyEventRegistration>;
      final upcomingIds = upcoming.map((e) => e.id).toSet();
      setState(() {
        _upcoming = upcoming;
        _past = all.where((e) => !upcomingIds.contains(e.id)).toList();
        _myRegistrations = myRegs;
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

  Future<void> _registerForProgram(EventProgramCardData program) async {
    if (!program.event.registrationOpen) return;

    final details = await showEventBasicRegistrationDialog(
      context,
      programTitle: program.title,
    );
    if (details == null || !mounted) return;

    setState(() => _registeringTrack = program.programTrack);
    try {
      await submitBasicEventRegistration(
        api: _api,
        eventId: program.event.id,
        programTrack: program.programTrack,
        details: details,
      );
      if (!mounted) return;
      await _loadEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered for ${program.title}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _registeringTrack = null);
    }
  }

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
              if (!_loading && _error == null && _myRegistrations.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'My registrations',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 16),
                ..._myRegistrations.map(_buildRegistrationTile),
              ],
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
                  registrations: _myRegistrations,
                  registeringTrack: _registeringTrack,
                  onRegister: _registerForProgram,
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

  Widget _buildRegistrationTile(MyEventRegistration reg) {
    final details = <String>[
      reg.displayKind,
      reg.status,
      if (reg.programTracks.isNotEmpty) reg.programTracks.join(', '),
      if (reg.registrationTypes.isNotEmpty)
        reg.registrationTypes.map((t) => t.replaceAll('_', ' ')).join(', '),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => context.go('/my-events/${reg.slug}'),
        title: Text(
          reg.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        subtitle: Text(
          '${reg.displayDate} · $details',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.bodyText,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ProgramEventGrid extends StatelessWidget {
  const _ProgramEventGrid({
    required this.programs,
    required this.registrations,
    required this.registeringTrack,
    required this.onRegister,
    required this.onOpenDetail,
  });

  final List<EventProgramCardData> programs;
  final List<MyEventRegistration> registrations;
  final String? registeringTrack;
  final Future<void> Function(EventProgramCardData program) onRegister;
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
              Builder(
                builder: (context) {
                  final isRegistered = isRegisteredForProgramTrack(
                    registrations,
                    program.event.id,
                    program.programTrack,
                  );
                  final isSubmitting =
                      registeringTrack == program.programTrack;

                  return SizedBox(
                    width: cardWidth,
                    child: EventCard(
                      title: program.title,
                      dateLabel: program.dateLabel,
                      venueLabel: program.venueLabel,
                      registeredCount: program.event.registeredCount,
                      coverAssetPath: AppAssets.eventBanner,
                      registrationOpen: program.event.registrationOpen,
                      isRegistered: isRegistered,
                      onTap: () => onOpenDetail(program.event),
                      onRegister: program.event.registrationOpen &&
                              !isRegistered &&
                              !isSubmitting
                          ? () => onRegister(program)
                          : null,
                    ),
                  );
                },
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
                  registrationOpen: false,
                  isRegistered: false,
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
