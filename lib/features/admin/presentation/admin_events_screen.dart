import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/admin_api_service.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _api = AdminApiService();

  List<AdminEventItem> _events = [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

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
      final events = await _api.fetchEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
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

  Future<void> _openEditor({AdminEventItem? event}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EventEditorDialog(event: event),
    );
    if (saved == true) await _load();
  }

  Future<void> _deleteEvent(AdminEventItem event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event'),
        content: Text(
          'Delete "${event.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _api.deleteEvent(event.id);
      if (!mounted) return;
      setState(() {
        _events = _events.where((e) => e.id != event.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Create, edit, publish and delete alumni events shown to members.',
                          style: GoogleFonts.inter(color: AppColors.bodyText),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _ErrorBanner(message: _error!, onRetry: _load)
                  else if (_events.isEmpty)
                    Text(
                      'No events yet. Create the first one.',
                      style: GoogleFonts.inter(color: AppColors.bodyText),
                    )
                  else
                    ..._events.map(_buildEventTile),
                ],
              ),
            ),
          ),
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildEventTile(AdminEventItem event) {
    final venue = event.isOnline
        ? 'Online'
        : [
            if (event.venueName != null && event.venueName!.isNotEmpty)
              event.venueName,
            if (event.city != null && event.city!.isNotEmpty) event.city,
          ].whereType<String>().join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openRegistrationsPage(event),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 96,
                      height: 72,
                      child: event.coverImageUrl != null &&
                              event.coverImageUrl!.trim().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: event.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => _coverPlaceholder(),
                            )
                          : _coverPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.heading,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            _formatDate(event.startsAt),
                            if (venue.isNotEmpty) venue,
                            event.isPublished ? 'Published' : 'Draft',
                            if (event.registrationOpen) 'Registration open',
                          ].join(' · '),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.bodyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _openRegistrationsPage(event),
                          icon: const Icon(Icons.people_outline, size: 18),
                          label: Text(
                            '${event.registeredCount} registered — view details',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        if (event.description != null &&
                            event.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            event.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'View registrations',
            onPressed: () => _openRegistrationsPage(event),
            icon: const Icon(Icons.people_outline),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _openEditor(event: event),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _deleteEvent(event),
            icon: Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  void _openRegistrationsPage(AdminEventItem event) {
    context.go('/admin/events/${event.id}', extra: event.title);
  }

  Widget _coverPlaceholder() {
    return ColoredBox(
      color: AppColors.muted,
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.mutedText),
      ),
    );
  }
}

class _EventEditorDialog extends StatefulWidget {
  const _EventEditorDialog({this.event});

  final AdminEventItem? event;

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog> {
  final _api = AdminApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _slug;
  late final TextEditingController _description;
  late final TextEditingController _venueName;
  late final TextEditingController _venueAddress;
  late final TextEditingController _city;
  late final TextEditingController _meetingUrl;
  late final TextEditingController _coverImageUrl;
  late final TextEditingController _capacity;
  late final TextEditingController _programs;

  late DateTime _startsAt;
  DateTime? _endsAt;
  bool _isOnline = false;
  bool _registrationOpen = true;
  bool _publish = true;
  bool _showOnHome = false;
  bool _slugTouched = false;
  bool _saving = false;
  bool _uploadingCover = false;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _title = TextEditingController(text: event?.title ?? '');
    _slug = TextEditingController(text: event?.slug ?? '');
    _description = TextEditingController(text: event?.description ?? '');
    _venueName = TextEditingController(text: event?.venueName ?? '');
    _venueAddress = TextEditingController(text: event?.venueAddress ?? '');
    _city = TextEditingController(text: event?.city ?? '');
    _meetingUrl = TextEditingController(text: event?.meetingUrl ?? '');
    _coverImageUrl = TextEditingController(text: event?.coverImageUrl ?? '');
    _capacity = TextEditingController(
      text: event?.capacity != null ? '${event!.capacity}' : '',
    );
    _programs = TextEditingController(
      text: (event?.programs ?? const <String>[]).join('\n'),
    );
    _startsAt = event?.startsAt.toLocal() ??
        DateTime.now().add(const Duration(days: 30));
    _endsAt = event?.endsAt?.toLocal();
    _isOnline = event?.isOnline ?? false;
    _registrationOpen = event?.registrationOpen ?? true;
    _publish = event?.isPublished ?? true;
    _showOnHome = event?.showOnHome ?? false;
    _slugTouched = event != null;
    _title.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _title.removeListener(_onTitleChanged);
    _title.dispose();
    _slug.dispose();
    _description.dispose();
    _venueName.dispose();
    _venueAddress.dispose();
    _city.dispose();
    _meetingUrl.dispose();
    _coverImageUrl.dispose();
    _capacity.dispose();
    _programs.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (_slugTouched) return;
    _slug.text = _slugFromTitle(_title.text);
  }

  static String _slugFromTitle(String title) {
    final lowered = title.trim().toLowerCase();
    final slug = lowered
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'event' : slug;
  }

  Future<void> _pickStartsAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickEndsAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? _startsAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endsAt ?? _startsAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _endsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _setAsUpcoming() {
    final now = DateTime.now();
    setState(() {
      _showOnHome = true;
      _publish = true;
      if (!_startsAt.isAfter(now)) {
        _startsAt = now.add(const Duration(days: 30));
      }
      if (_endsAt != null && !_endsAt!.isAfter(_startsAt)) {
        _endsAt = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked for Home. Save the event to apply.'),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $h:$m';
  }

  Future<void> _pickAndUploadCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read image file.')),
      );
      return;
    }

    setState(() => _uploadingCover = true);
    try {
      final url = await _api.uploadEventCover(file);
      if (!mounted) return;
      setState(() {
        _coverImageUrl.text = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover image uploaded.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Widget _coverPreview() {
    final url = _coverImageUrl.text.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: double.infinity,
        height: 160,
        child: url.isEmpty
            ? ColoredBox(
                color: AppColors.muted,
                child: Center(
                  child: Text(
                    'No cover image yet',
                    style: GoogleFonts.inter(color: AppColors.mutedText),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => ColoredBox(
                  color: AppColors.muted,
                  child: Center(
                    child: Text(
                      'Could not load cover',
                      style: GoogleFonts.inter(color: AppColors.mutedText),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final capacityText = _capacity.text.trim();
    final capacity = capacityText.isEmpty ? null : int.tryParse(capacityText);
    if (capacityText.isNotEmpty && (capacity == null || capacity < 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capacity must be a positive number.')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'slug': _slug.text.trim(),
      'title': _title.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'starts_at': _startsAt.toUtc().toIso8601String(),
      'ends_at': _endsAt?.toUtc().toIso8601String(),
      'venue_name':
          _venueName.text.trim().isEmpty ? null : _venueName.text.trim(),
      'venue_address': _venueAddress.text.trim().isEmpty
          ? null
          : _venueAddress.text.trim(),
      'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
      'is_online': _isOnline,
      'meeting_url':
          _meetingUrl.text.trim().isEmpty ? null : _meetingUrl.text.trim(),
      'capacity': capacity,
      'registration_open': _registrationOpen,
      'cover_image_url': _coverImageUrl.text.trim().isEmpty
          ? null
          : _coverImageUrl.text.trim(),
      'programs': _programs.text
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
      'publish': _publish,
      'show_on_home': _showOnHome,
    };

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _api.updateEvent(widget.event!.id, payload);
      } else {
        await _api.createEvent(payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 700 ? 12 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit event' : 'Create event',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Event title *',
                        hintText: 'Alumni Meet 2027',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _slug,
                      decoration: const InputDecoration(
                        labelText: 'Slug *',
                        hintText: 'alumni-meet-2027',
                        helperText: 'Used in the event URL',
                      ),
                      onChanged: (_) => _slugTouched = true,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'details will be announced soon',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _programs,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Schedule lines (one per line)',
                        hintText:
                            'Scientific Session - 5th June\nAlumni - 6th June',
                        helperText:
                            'Shown on Home and Announcements event details',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start date & time *'),
                      subtitle: Text(_formatDateTime(_startsAt)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: _pickStartsAt,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _setAsUpcoming,
                        icon: const Icon(Icons.upcoming_outlined, size: 18),
                        label: const Text('Set as upcoming on Home'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End date & time'),
                      subtitle: Text(
                        _endsAt == null
                            ? 'Optional — tap to set'
                            : _formatDateTime(_endsAt!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_endsAt != null)
                            IconButton(
                              tooltip: 'Clear',
                              onPressed: () => setState(() => _endsAt = null),
                              icon: const Icon(Icons.clear),
                            ),
                          const Icon(Icons.event_outlined),
                        ],
                      ),
                      onTap: _pickEndsAt,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Online event'),
                      value: _isOnline,
                      onChanged: (v) => setState(() => _isOnline = v),
                    ),
                    if (!_isOnline) ...[
                      TextFormField(
                        controller: _venueName,
                        decoration: const InputDecoration(
                          labelText: 'Venue name',
                          hintText: 'HITEX Novotel',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _city,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          hintText: 'Hyderabad',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _venueAddress,
                        decoration: const InputDecoration(
                          labelText: 'Venue address',
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _meetingUrl,
                        decoration: const InputDecoration(
                          labelText: 'Meeting URL',
                          hintText: 'https://...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        hintText: 'Optional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cover image',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _coverPreview(),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              (_saving || _uploadingCover) ? null : _pickAndUploadCover,
                          icon: _uploadingCover
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_outlined, size: 18),
                          label: Text(
                            _uploadingCover ? 'Uploading…' : 'Upload photo',
                          ),
                        ),
                        if (_coverImageUrl.text.trim().isNotEmpty)
                          TextButton(
                            onPressed: (_saving || _uploadingCover)
                                ? null
                                : () => setState(() => _coverImageUrl.clear()),
                            child: const Text('Remove cover'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _coverImageUrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Or paste cover image link',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Publish (visible to members)'),
                      value: _publish,
                      onChanged: (v) => setState(() => _publish = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Registration open'),
                      value: _registrationOpen,
                      onChanged: (v) => setState(() => _registrationOpen = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show on Home (upcoming)'),
                      subtitle: const Text(
                        'Only events marked here appear in the home page Upcoming Events section.',
                      ),
                      value: _showOnHome,
                      onChanged: (v) => setState(() => _showOnHome = v),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_saving || _uploadingCover) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdit ? 'Save changes' : 'Create event'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          Text(message, style: GoogleFonts.inter(color: AppColors.bodyText)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
