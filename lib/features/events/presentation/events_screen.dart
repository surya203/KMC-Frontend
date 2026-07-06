import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/cover_image.dart';
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
  final _service = EventsService();
  List<EventSummary> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _service.fetchUpcoming();
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
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
                      else if (_events.isEmpty)
                        const Text('No upcoming events right now.')
                      else
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            for (final event in _events)
                              SizedBox(
                                width: 520,
                                child: EventCard(
                                  event: event,
                                  onTap: () =>
                                      context.go('/events/${event.slug}'),
                                  onRegister: () =>
                                      context.go('/events/${event.slug}'),
                                ),
                              ),
                          ],
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

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _service = EventsService();
  EventDetail? _event;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final event = await _service.fetchBySlug(widget.slug);
      if (!mounted) return;
      setState(() {
        _event = event;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _toggleRegistration() async {
    final event = _event;
    if (event == null) return;
    setState(() => _busy = true);
    try {
      if (event.isRegistered == true) {
        await _service.cancelRegistration(event.id);
      } else {
        await _service.register(event.id);
      }
      await _load();
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? Center(child: Text(_error ?? 'Event not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CoverImage(imageUrl: _event!.coverImageUrl, height: 280),
                          const SizedBox(height: 24),
                          Text(
                            _event!.title,
                            style: HeadingStyles.contentColumnHeading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${formatDateTime(_event!.startsAt)} · ${_event!.locationLabel}',
                          ),
                          const SizedBox(height: 16),
                          if (_event!.description != null)
                            Text(_event!.description!),
                          const SizedBox(height: 16),
                          Text('${_event!.registeredCount} registered'),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppColors.error)),
                          ],
                          const SizedBox(height: 20),
                          if (_event!.registrationOpen)
                            Semantics(
                              label: _event!.isRegistered == true
                                  ? 'Cancel event registration'
                                  : 'Register for event',
                              button: true,
                              child: ElevatedButton(
                                key: const ValueKey('event-register-button'),
                                onPressed: _busy ? null : _toggleRegistration,
                                child: Text(
                                  _event!.isRegistered == true
                                      ? 'Cancel registration'
                                      : 'Register for event',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
