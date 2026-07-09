import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/events_service.dart';
import '../../../core/network/notifications_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/event_card.dart';
import '../../../core/widgets/events_hero_banner.dart';
import '../../../core/widgets/member_layout.dart';

List<String> eventProgramsFor(EventDetail event) {
  if (event.programs.isNotEmpty) return event.programs;
  return const [
    '5th June Scientific Sessions',
    'CME Programs',
    'NRI Programs',
  ];
}

/// Static program categories until admin-managed categories are wired in.
const kStaticEventProgramCategories = [
  (
    title: '5th June Scientific Sessions',
    description:
        'Scientific papers, posters, and abstracts presented by alumni.',
  ),
  (
    title: 'CME Programs',
    description: 'Continuing medical education sessions and workshops.',
  ),
  (
    title: 'NRI Programs',
    description: 'Sessions and activities for NRI alumni participation.',
  ),
];

List<({String title, String description})> eventProgramCategoriesFor(
  EventDetail event,
) {
  final programs = eventProgramsFor(event);
  if (programs.isEmpty) return kStaticEventProgramCategories;

  return [
    for (final program in programs)
      (
        title: program,
        description: _descriptionForProgram(program),
      ),
  ];
}

String _descriptionForProgram(String program) {
  for (final item in kStaticEventProgramCategories) {
    if (item.title == program) return item.description;
  }
  return 'Register your interest or attendance for this program.';
}

String _displayEventTitle(EventDetail event) {
  if (event.slug == '2nd-kmc-alumni-meet' ||
      event.title == '2nd KMC Alumni Meet') {
    return 'Scientific Sessions';
  }
  return event.title;
}

String _displayEventDate(EventDetail event) {
  if (event.slug == '2nd-kmc-alumni-meet') {
    return formatDateTime('2027-06-05T09:00:00+00:00');
  }
  return formatDateTime(event.startsAt);
}

class DashboardMyEventsScreen extends StatefulWidget {
  const DashboardMyEventsScreen({super.key});

  @override
  State<DashboardMyEventsScreen> createState() =>
      _DashboardMyEventsScreenState();
}

class _DashboardMyEventsScreenState extends State<DashboardMyEventsScreen> {
  final _service = EventsService();
  List<EventSummary> _upcoming = [];
  List<MyEventRegistration> _mine = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final upcoming = await _service.fetchUpcoming();
    List<MyEventRegistration> mine = const [];
    try {
      mine = await _service.fetchMyRegistrations();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _upcoming = upcoming;
      _mine = mine;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MemberLayout(
      currentPath: '/dashboard/events',
      title: 'Events',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Events',
                          style: HeadingStyles.contentColumnHeading,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reunions, CME symposia and alumni meet registrations.',
                          style: GoogleFonts.inter(color: AppColors.bodyText),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Upcoming',
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_upcoming.isEmpty)
                          const Text('No upcoming events right now.')
                        else
                          Column(
                            children: [
                              for (final event in _upcoming)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: EventCard(
                                    event: event,
                                    showHeroImage: true,
                                    heroAssetPath: AppAssets.eventsUpcomingHero,
                                    onTap: () => context.go(
                                      '/dashboard/events/${event.slug}',
                                    ),
                                    onRegister: () => context.go(
                                      '/dashboard/events/${event.slug}',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        if (_mine.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'My registrations',
                            style: GoogleFonts.fraunces(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._mine.map(
                            (item) => Card(
                              child: ListTile(
                                title: Text(item.title),
                                subtitle: Text(
                                  '${_kindLabel(item.registrationKind)} · '
                                  '${_tracksLabel(item)}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.go(
                                  '/dashboard/events/${item.slug}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'interest':
        return 'Interest submitted';
      case 'attendance':
        return 'Attendance interest';
      default:
        return 'Registered';
    }
  }

  String _tracksLabel(MyEventRegistration item) {
    final tracks = item.programTracks.isNotEmpty
        ? item.programTracks
        : item.registrationTypes;
    if (tracks.isEmpty) return item.status;
    return tracks.join(', ');
  }
}

class MemberEventDetailScreen extends StatefulWidget {
  const MemberEventDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<MemberEventDetailScreen> createState() =>
      _MemberEventDetailScreenState();
}

class _MemberEventDetailScreenState extends State<MemberEventDetailScreen> {
  final _service = EventsService();
  EventDetail? _event;
  bool _loading = true;
  String? _error;

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
      final event = await _service.fetchBySlug(widget.slug);
      if (!mounted) return;
      setState(() {
        _event = event;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openInterestForm() async {
    final event = _event;
    if (event == null) return;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => _EventInterestFormDialog(event: event),
    );
    if (submitted == true) {
      await _load();
      _showMessage('Interest registration submitted.');
    }
  }

  Future<void> _openAttendanceForm() async {
    final event = _event;
    if (event == null) return;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => _EventAttendanceFormDialog(event: event),
    );
    if (submitted == true) {
      await _load();
      _showMessage('Attendance interest submitted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    return MemberLayout(
      currentPath: '/dashboard/events',
      title: 'Event',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? Center(child: Text(_error ?? 'Event not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EventsHeroBanner(),
                          const SizedBox(height: 24),
                          Text(
                            _displayEventTitle(event),
                            style: HeadingStyles.contentColumnHeading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_displayEventDate(event)} · ${event.locationLabel}',
                            style: GoogleFonts.inter(color: AppColors.bodyText),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Available events',
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.heading,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Program categories for this alumni meet.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.bodyText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...eventProgramCategoriesFor(event).map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProgramCategoryCard(
                                title: category.title,
                                description: category.description,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (event.hasInterestRegistration == true)
                            const _StatusBanner(
                              icon: Icons.check_circle_outline,
                              text: 'You have submitted your interest for this event.',
                            ),
                          if (event.hasAttendanceRegistration == true)
                            const _StatusBanner(
                              icon: Icons.event_available_outlined,
                              text: 'You have registered your attendance interest.',
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton(
                                onPressed: event.registrationOpen
                                    ? _openInterestForm
                                    : null,
                                child: const Text('Register your interest'),
                              ),
                              OutlinedButton(
                                onPressed: event.registrationOpen
                                    ? _openAttendanceForm
                                    : null,
                                child: const Text('I would like to attend'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _ProgramCategoryCard extends StatelessWidget {
  const _ProgramCategoryCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: AppColors.shadow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_note_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.bodyText,
                      height: 1.4,
                    ),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EventInterestFormDialog extends StatefulWidget {
  const _EventInterestFormDialog({required this.event});

  final EventDetail event;

  @override
  State<_EventInterestFormDialog> createState() =>
      _EventInterestFormDialogState();
}

class _EventInterestFormDialogState extends State<_EventInterestFormDialog> {
  final _service = EventsService();
  final _formKey = GlobalKey<FormState>();
  final _membershipController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _institutionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sponsorOrgController = TextEditingController();
  final _sponsorMessageController = TextEditingController();

  final _selectedTypes = <String>{};
  String? _programTrack;
  int? _batchYear;
  PlatformFile? _document;
  bool _submitting = false;

  static const _typeOptions = [
    ('scientific_paper', 'Present scientific paper'),
    ('poster', 'Present poster'),
    ('abstract', 'Present abstract'),
    ('sponsor', 'Sponsor event'),
  ];

  @override
  void initState() {
    super.initState();
    final user = authSession.user;
    _nameController.text = user?.profile?.fullName ?? '';
    _emailController.text = user?.email ?? '';
    _batchYear = user?.profile?.batchYear;
    _membershipController.text = user?.profile?.id ?? '';
    if (eventProgramsFor(widget.event).isNotEmpty) {
      _programTrack = eventProgramsFor(widget.event).first;
    }
  }

  @override
  void dispose() {
    _membershipController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _institutionController.dispose();
    _categoryController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _sponsorOrgController.dispose();
    _sponsorMessageController.dispose();
    super.dispose();
  }

  bool get _needsPresentationFields =>
      _selectedTypes.contains('scientific_paper') ||
      _selectedTypes.contains('poster') ||
      _selectedTypes.contains('abstract');

  bool get _needsSponsorFields => _selectedTypes.contains('sponsor');

  Future<void> _pickDocument() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    setState(() => _document = picked.files.first);
  }

  Future<void> _submit() async {
    if (_selectedTypes.isEmpty) {
      _showError('Select at least one registration type.');
      return;
    }
    if (_programTrack == null) {
      _showError('Select a program track.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _service.submitInterest(
        eventId: widget.event.id,
        registrationTypes: _selectedTypes.toList(),
        programTrack: _programTrack!,
        membershipNumber: _membershipController.text.trim(),
        fullName: _nameController.text.trim(),
        batchYear: _batchYear,
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        medicalSpecialty: _specialtyController.text.trim(),
        institution: _institutionController.text.trim(),
        presentationCategory: _categoryController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        sponsorOrganization: _sponsorOrgController.text.trim(),
        sponsorMessage: _sponsorMessageController.text.trim(),
        documentBytes: _document?.bytes,
        documentFilename: _document?.name,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register your interest'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Registration type'),
                const SizedBox(height: 8),
                ..._typeOptions.map(
                  (option) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.$2),
                    value: _selectedTypes.contains(option.$1),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedTypes.add(option.$1);
                        } else {
                          _selectedTypes.remove(option.$1);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _programTrack,
                  decoration: const InputDecoration(labelText: 'Program track'),
                  items: [
                    for (final program in eventProgramsFor(widget.event))
                      DropdownMenuItem(value: program, child: Text(program)),
                  ],
                  onChanged: (value) => setState(() => _programTrack = value),
                  validator: (value) =>
                      value == null ? 'Select a program track' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _membershipController,
                  decoration: const InputDecoration(labelText: 'Membership number'),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  initialValue: _batchYear?.toString(),
                  decoration: const InputDecoration(labelText: 'Batch year'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      _batchYear = int.tryParse(value.trim()),
                ),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile number'),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _specialtyController,
                  decoration:
                      const InputDecoration(labelText: 'Medical specialty'),
                ),
                TextFormField(
                  controller: _institutionController,
                  decoration: const InputDecoration(
                    labelText: 'Institution / hospital',
                  ),
                ),
                if (_needsPresentationFields) ...[
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Presentation category',
                    ),
                  ),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Paper / poster / abstract title',
                    ),
                    validator: (value) => _needsPresentationFields &&
                            (value == null || value.trim().isEmpty)
                        ? 'Required for presentation submissions'
                        : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Brief description / abstract',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _document?.name ?? 'Upload supporting document',
                    ),
                  ),
                ],
                if (_needsSponsorFields) ...[
                  TextFormField(
                    controller: _sponsorOrgController,
                    decoration: const InputDecoration(
                      labelText: 'Sponsor organization',
                    ),
                    validator: (value) => _needsSponsorFields &&
                            (value == null || value.trim().isEmpty)
                        ? 'Required for sponsor registration'
                        : null,
                  ),
                  TextFormField(
                    controller: _sponsorMessageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Sponsorship message',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _EventAttendanceFormDialog extends StatefulWidget {
  const _EventAttendanceFormDialog({required this.event});

  final EventDetail event;

  @override
  State<_EventAttendanceFormDialog> createState() =>
      _EventAttendanceFormDialogState();
}

class _EventAttendanceFormDialogState
    extends State<_EventAttendanceFormDialog> {
  final _service = EventsService();
  final _formKey = GlobalKey<FormState>();
  final _membershipController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedTracks = <String>{};
  int? _batchYear;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = authSession.user;
    _nameController.text = user?.profile?.fullName ?? '';
    _emailController.text = user?.email ?? '';
    _batchYear = user?.profile?.batchYear;
    _membershipController.text = user?.profile?.id ?? '';
  }

  @override
  void dispose() {
    _membershipController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one program track.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _service.submitAttendance(
        eventId: widget.event.id,
        programTracks: _selectedTracks.toList(),
        membershipNumber: _membershipController.text.trim(),
        fullName: _nameController.text.trim(),
        batchYear: _batchYear,
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('I would like to attend'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Program tracks'),
                const SizedBox(height: 8),
                ...eventProgramsFor(widget.event).map(
                  (program) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(program),
                    value: _selectedTracks.contains(program),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedTracks.add(program);
                        } else {
                          _selectedTracks.remove(program);
                        }
                      });
                    },
                  ),
                ),
                TextFormField(
                  controller: _membershipController,
                  decoration: const InputDecoration(labelText: 'Membership number'),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  initialValue: _batchYear?.toString(),
                  decoration: const InputDecoration(labelText: 'Batch year'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      _batchYear = int.tryParse(value.trim()),
                ),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile number'),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class DashboardNotificationsScreen extends StatefulWidget {
  const DashboardNotificationsScreen({super.key});

  @override
  State<DashboardNotificationsScreen> createState() =>
      _DashboardNotificationsScreenState();
}

class _DashboardNotificationsScreenState
    extends State<DashboardNotificationsScreen> {
  final _service = NotificationsService();
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberLayout(
      currentPath: '/dashboard/notifications',
      title: 'Notifications',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No notifications yet.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          leading: Icon(
                            item.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: item.isRead
                                ? AppColors.mutedText
                                : AppColors.primary,
                          ),
                          title: Text(item.title),
                          subtitle: Text(item.body),
                          onTap: () async {
                            if (!item.isRead) {
                              await _service.markRead(item.id);
                              await _load();
                            }
                            final slug = item.eventSlug;
                            if (slug != null && context.mounted) {
                              context.go('/dashboard/events/$slug');
                            }
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
