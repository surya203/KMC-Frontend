import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/admin_api_service.dart';

Future<void> showEventRegistrationsDialog(
  BuildContext context, {
  required String eventId,
  required String eventTitle,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => EventRegistrationsDialog(
      eventId: eventId,
      eventTitle: eventTitle,
    ),
  );
}

class EventRegistrationsDialog extends StatelessWidget {
  const EventRegistrationsDialog({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Registrations — $eventTitle'),
      content: SizedBox(
        width: 640,
        height: 480,
        child: EventRegistrationsPanel(eventId: eventId),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class EventRegistrationsPanel extends StatefulWidget {
  const EventRegistrationsPanel({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<EventRegistrationsPanel> createState() =>
      _EventRegistrationsPanelState();
}

class _EventRegistrationsPanelState extends State<EventRegistrationsPanel> {
  final _api = AdminApiService();
  AdminEventRegistrationsPage? _page;
  String? _error;
  bool _loading = true;
  String? _busyId;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.fetchEventRegistrations(widget.eventId);
      if (!mounted) return;
      setState(() {
        _page = page;
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

  List<AdminEventRegistrant> get _filtered {
    final items = (_page?.registrations ?? [])
        .where((r) => r.kind != 'interest')
        .toList();
    if (_filter == 'all') return items;
    return items.where((r) => r.kind == _filter).toList();
  }

  List<String> _statusOptionsFor(String kind) {
    switch (kind) {
      case 'registered':
        return ['registered', 'waitlisted', 'cancelled'];
      case 'attendance':
        return ['submitted', 'confirmed', 'cancelled'];
      case 'interest':
        return ['submitted', 'reviewed', 'cancelled'];
      default:
        return [];
    }
  }

  Future<void> _updateStatus(AdminEventRegistrant item, String status) async {
    setState(() => _busyId = item.id);
    try {
      await _api.updateEventRegistrationStatus(
        eventId: widget.eventId,
        kind: item.kind,
        registrationId: item.id,
        status: status,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    final page = _page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (page != null)
          Text(
            'RSVP ${page.registeredCount}'
            ' · Waitlist ${page.waitlistedCount}'
            ' · Registrations ${page.attendanceCount}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.bodyText,
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in const [
              ('all', 'All'),
              ('registered', 'RSVP'),
              ('attendance', 'Registrations'),
            ])
              ChoiceChip(
                label: Text(entry.$2),
                selected: _filter == entry.$1,
                onSelected: (_) => setState(() => _filter = entry.$1),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _filtered.isEmpty
              ? Text(
                  'No registrations in this category.',
                  style: GoogleFonts.inter(color: AppColors.bodyText),
                )
              : ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    final busy = _busyId == item.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.fullName ?? 'Member',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    item.kindLabel,
                                    item.status,
                                    if (item.email != null) item.email!,
                                    if (item.mobile != null &&
                                        item.mobile!.isNotEmpty)
                                      item.mobile!,
                                    if (item.batchYear != null)
                                      'Batch ${item.batchYear}',
                                    if (item.programTracks.isNotEmpty)
                                      item.programTracks.join(', '),
                                    if (item.registrationTypes.isNotEmpty)
                                      item.registrationTypes.join(', '),
                                  ].join(' · '),
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (busy)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            PopupMenuButton<String>(
                              tooltip: 'Update status',
                              onSelected: (value) =>
                                  _updateStatus(item, value),
                              itemBuilder: (context) => [
                                for (final status
                                    in _statusOptionsFor(item.kind))
                                  PopupMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
