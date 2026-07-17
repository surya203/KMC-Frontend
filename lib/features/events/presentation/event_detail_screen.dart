import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/widgets/event_card.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _api = EventsApiService();
  EventItem? _event;
  String? _error;
  bool _loading = true;
  bool _registering = false;
  bool _cancelling = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final event = await _api.fetchEventBySlug(widget.slug);
      if (!mounted) return;
      setState(() {
        _event = event;
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

  Future<void> _register() async {
    final event = _event;
    if (event == null) return;

    if (!AuthSession.instance.isAuthenticated) {
      if (!mounted) return;
      context.go('/auth');
      return;
    }

    setState(() {
      _registering = true;
      _message = null;
    });

    try {
      final result = await _api.registerForEvent(event.id);
      if (!mounted) return;
      setState(() {
        _event = event.copyWith(
          registeredCount: result.registeredCount,
          isRegistered: result.status == 'registered',
          isWaitlisted: result.status == 'waitlisted',
        );
        _registering = false;
        _message = result.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _registering = false;
        _message = e.toString();
      });
    }
  }

  Future<void> _cancel() async {
    final event = _event;
    if (event == null) return;
    final canCancel =
        (event.isRegistered ?? false) || (event.isWaitlisted ?? false);
    if (!canCancel) return;

    setState(() {
      _cancelling = true;
      _message = null;
    });

    try {
      final result = await _api.cancelRegistration(event.id);
      if (!mounted) return;
      setState(() {
        _event = event.copyWith(
          registeredCount: result.registeredCount,
          isRegistered: false,
          isWaitlisted: false,
        );
        _cancelling = false;
        _message = result.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: TextButton.icon(
                    onPressed: () => context.go('/events'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('All events'),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 72),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        )
                      : _error != null
                          ? Text(
                              _error!,
                              style: GoogleFonts.inter(color: AppColors.bodyText),
                            )
                          : _buildContent(_event!),
                ),
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(EventItem event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventCard(
          title: event.title,
          dateLabel: event.displayDate,
          venueLabel: event.displayVenue,
          registeredCount: event.registeredCount,
          coverImageUrl: event.coverImageUrl,
          registrationOpen: event.registrationOpen,
          isRegistered: (event.isRegistered ?? false) ||
              (event.isWaitlisted ?? false),
          onRegister: _registering ||
                  (event.isRegistered ?? false) ||
                  (event.isWaitlisted ?? false)
              ? null
              : _register,
        ),
        if ((event.isRegistered ?? false) ||
            (event.isWaitlisted ?? false)) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _cancelling ? null : _cancel,
            child: _cancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    (event.isWaitlisted ?? false)
                        ? 'Leave waitlist'
                        : 'Cancel registration',
                  ),
          ),
        ],
        if (_registering)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_message != null) ...[
          const SizedBox(height: 16),
          Text(
            _message!,
            style: GoogleFonts.inter(color: AppColors.bodyText),
          ),
        ],
        if (event.description != null && event.description!.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            'About this event',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.description!,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.7,
              color: AppColors.bodyText,
            ),
          ),
        ],
        if (event.venueAddress != null && event.venueAddress!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Address',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.venueAddress!,
            style: GoogleFonts.inter(color: AppColors.bodyText),
          ),
        ],
        if (event.isOnline && event.meetingUrl != null) ...[
          const SizedBox(height: 16),
          Text(
            'Meeting link: ${event.meetingUrl}',
            style: GoogleFonts.inter(color: AppColors.primary),
          ),
        ],
      ],
    );
  }
}
