import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/role_utils.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/widgets/event_card.dart';
import '../../events/widgets/event_registrations_dialog.dart';
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
  List<MyEventRegistration> _myRegistrations = [];
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
      final upcoming = await _api.fetchEvents(upcoming: true);
      final all = await _api.fetchEvents(upcoming: false);
      List<MyEventRegistration> mine = [];
      try {
        mine = await _api.fetchMyRegistrations();
        mine = mine
            .where((r) => r.registrationKind != 'interest')
            .toList();
      } catch (_) {
        // Optional section — do not fail the whole page.
      }
      if (!mounted) return;
      final upcomingIds = upcoming.map((e) => e.id).toSet();
      setState(() {
        _upcoming = upcoming;
        _past = all.where((e) => !upcomingIds.contains(e.id)).toList();
        _myRegistrations = mine;
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

  void _openEventDetail(EventItem event) {
    context.go('/my-events/${event.slug}');
  }

  void _openRegistrants(EventItem event) {
    showEventRegistrationsDialog(
      context,
      eventId: event.id,
      eventTitle: event.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = canManageEvents(currentUserRole);
    return SingleChildScrollView(
      padding: DashboardLayout.screenPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              if (!_loading && _error == null && !isAdmin && _myRegistrations.isNotEmpty) ...[
                Text(
                  'My registrations',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                const SizedBox(height: 12),
                ..._myRegistrations.map(
                  (reg) => _MyRegistrationTile(
                    registration: reg,
                    onOpen: () => context.go('/my-events/${reg.slug}'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
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
                _UpcomingEventGrid(
                  events: _upcoming,
                  isAdmin: isAdmin,
                  onOpenDetail: _openEventDetail,
                  onViewRegistrants: isAdmin ? _openRegistrants : null,
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
                  isAdmin: isAdmin,
                  onOpen: _openEventDetail,
                  onViewRegistrants: isAdmin ? _openRegistrants : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MyRegistrationTile extends StatelessWidget {
  const _MyRegistrationTile({
    required this.registration,
    required this.onOpen,
  });

  final MyEventRegistration registration;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        registration.displayKind,
                        registration.status,
                        registration.displayDate,
                        registration.displayVenue,
                      ].join(' · '),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingEventGrid extends StatelessWidget {
  const _UpcomingEventGrid({
    required this.events,
    required this.isAdmin,
    required this.onOpenDetail,
    this.onViewRegistrants,
  });

  final List<EventItem> events;
  final bool isAdmin;
  final void Function(EventItem event) onOpenDetail;
  final void Function(EventItem event)? onViewRegistrants;

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
                  dateLabel: event.displayDateRange,
                  venueLabel: event.displayVenue,
                  registeredCount: event.registeredCount,
                  coverImageUrl: event.coverImageUrl,
                  coverAssetPath: AppAssets.eventBanner,
                  registrationOpen: event.registrationOpen,
                  isRegistered: event.isRegistered ?? false,
                  showDateAndVenue: false,
                  detailMeta: event.homeDetailMeta,
                  showRegistrationUi: true,
                  onTap: () => onOpenDetail(event),
                  onViewRegistrants: isAdmin && onViewRegistrants != null
                      ? () => onViewRegistrants!(event)
                      : null,
                  onRegister: !isAdmin && event.registrationOpen
                      ? () => onOpenDetail(event)
                      : null,
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
    required this.isAdmin,
    required this.onOpen,
    this.onViewRegistrants,
  });

  final List<EventItem> events;
  final bool isAdmin;
  final void Function(EventItem event) onOpen;
  final void Function(EventItem event)? onViewRegistrants;

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
                  dateLabel: event.displayDateRange,
                  venueLabel: event.displayVenue,
                  registeredCount: event.registeredCount,
                  coverImageUrl: event.coverImageUrl,
                  coverAssetPath: AppAssets.eventBanner,
                  registrationOpen: event.registrationOpen,
                  isRegistered: event.isRegistered ?? false,
                  showDateAndVenue: false,
                  detailMeta: event.homeDetailMeta,
                  showRegistrationUi: true,
                  onTap: () => onOpen(event),
                  onViewRegistrants: isAdmin && onViewRegistrants != null
                      ? () => onViewRegistrants!(event)
                      : null,
                  onRegister: !isAdmin && event.registrationOpen
                      ? () => onOpen(event)
                      : null,
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
