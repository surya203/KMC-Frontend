import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/event_card.dart';

const _participationTypes = <String, String>{
  'scientific_paper': 'Scientific paper',
  'poster': 'Poster',
  'abstract': 'Abstract',
  'sponsor': 'Sponsor',
};

class DashboardEventDetailScreen extends StatefulWidget {
  const DashboardEventDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<DashboardEventDetailScreen> createState() =>
      _DashboardEventDetailScreenState();
}

class _DashboardEventDetailScreenState extends State<DashboardEventDetailScreen> {
  final _eventsApi = EventsApiService();
  final _profilesApi = ProfilesApiService();

  EventItem? _event;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  final _attendanceName = TextEditingController();
  final _attendanceEmail = TextEditingController();
  final _attendanceMobile = TextEditingController();
  final _attendanceMembership = TextEditingController();
  final _attendanceBatchYear = TextEditingController();
  final _attendanceCity = TextEditingController();
  final _attendanceNotes = TextEditingController();
  final Set<String> _selectedTracks = {};

  final _interestName = TextEditingController();
  final _interestEmail = TextEditingController();
  final _interestMobile = TextEditingController();
  final _interestMembership = TextEditingController();
  final _interestBatchYear = TextEditingController();
  final _interestSpecialty = TextEditingController();
  final _interestInstitution = TextEditingController();
  final _interestCategory = TextEditingController();
  final _interestTitle = TextEditingController();
  final _interestDescription = TextEditingController();
  final _interestSponsorOrg = TextEditingController();
  final _interestSponsorMessage = TextEditingController();
  String? _interestProgramTrack;
  final Set<String> _selectedParticipationTypes = {};
  PlatformFile? _supportingDocument;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _attendanceName.dispose();
    _attendanceEmail.dispose();
    _attendanceMobile.dispose();
    _attendanceMembership.dispose();
    _attendanceBatchYear.dispose();
    _attendanceCity.dispose();
    _attendanceNotes.dispose();
    _interestName.dispose();
    _interestEmail.dispose();
    _interestMobile.dispose();
    _interestMembership.dispose();
    _interestBatchYear.dispose();
    _interestSpecialty.dispose();
    _interestInstitution.dispose();
    _interestCategory.dispose();
    _interestTitle.dispose();
    _interestDescription.dispose();
    _interestSponsorOrg.dispose();
    _interestSponsorMessage.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final event = await _eventsApi.fetchEventBySlug(widget.slug);
      if (!mounted) return;
      _prefillContactFields();
      try {
        final profile = await _profilesApi.fetchMyProfile();
        if (!mounted) return;
        _attendanceName.text = profile.fullName;
        _interestName.text = profile.fullName;
        _attendanceBatchYear.text = '${profile.batchYear}';
        _interestBatchYear.text = '${profile.batchYear}';
        if (profile.phone != null && profile.phone!.isNotEmpty) {
          _attendanceMobile.text = profile.phone!;
          _interestMobile.text = profile.phone!;
        }
        if (profile.organization != null) {
          _interestInstitution.text = profile.organization!;
        }
      } catch (_) {
        // Profile optional for prefill.
      }
      final user = AuthSession.instance.currentUser;
      if (user != null) {
        _attendanceEmail.text = user.email;
        _interestEmail.text = user.email;
        if (user.membershipNumber != null) {
          _attendanceMembership.text = user.membershipNumber!;
          _interestMembership.text = user.membershipNumber!;
        }
      }
      if (event.programs.isNotEmpty) {
        _interestProgramTrack ??= event.programs.first;
      }
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

  void _prefillContactFields() {
    final user = AuthSession.instance.currentUser;
    if (user != null) {
      _attendanceEmail.text = user.email;
      _interestEmail.text = user.email;
      if (user.fullName != null && user.fullName!.isNotEmpty) {
        _attendanceName.text = user.fullName!;
        _interestName.text = user.fullName!;
      }
      if (user.membershipNumber != null) {
        _attendanceMembership.text = user.membershipNumber!;
        _interestMembership.text = user.membershipNumber!;
      }
    }
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitAttendance() async {
    final event = _event;
    if (event == null) return;
    if (_selectedTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one program track.')),
      );
      return;
    }
    final name = _attendanceName.text.trim();
    final email = _attendanceEmail.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required.')),
      );
      return;
    }
    final mobileError = validateMobileNumber(_attendanceMobile.text);
    if (mobileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mobileError)),
      );
      return;
    }

    await _runBusy(() async {
      await _eventsApi.submitAttendance(
        eventId: event.id,
        programTracks: _selectedTracks.toList(),
        fullName: name,
        email: email,
        membershipNumber: _attendanceMembership.text.trim().isEmpty
            ? null
            : _attendanceMembership.text.trim(),
        batchYear: int.tryParse(_attendanceBatchYear.text.trim()),
        mobile: _attendanceMobile.text.trim().isEmpty
            ? null
            : normalizeMobileNumber(_attendanceMobile.text),
        city: _attendanceCity.text.trim().isEmpty
            ? null
            : _attendanceCity.text.trim(),
        notes: _attendanceNotes.text.trim().isEmpty
            ? null
            : _attendanceNotes.text.trim(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance registration submitted.')),
      );
    });
  }

  Future<void> _submitInterest() async {
    final event = _event;
    if (event == null) return;
    if (_selectedParticipationTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participation type.')),
      );
      return;
    }
    final track = _interestProgramTrack;
    if (track == null || track.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a program track.')),
      );
      return;
    }
    final name = _interestName.text.trim();
    final email = _interestEmail.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required.')),
      );
      return;
    }
    final mobileError = validateMobileNumber(_interestMobile.text);
    if (mobileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mobileError)),
      );
      return;
    }

    await _runBusy(() async {
      await _eventsApi.submitInterest(
        eventId: event.id,
        registrationTypes: _selectedParticipationTypes.toList(),
        programTrack: track,
        fullName: name,
        email: email,
        membershipNumber: _interestMembership.text.trim().isEmpty
            ? null
            : _interestMembership.text.trim(),
        batchYear: int.tryParse(_interestBatchYear.text.trim()),
        mobile: _interestMobile.text.trim().isEmpty
            ? null
            : normalizeMobileNumber(_interestMobile.text),
        medicalSpecialty: _interestSpecialty.text.trim().isEmpty
            ? null
            : _interestSpecialty.text.trim(),
        institution: _interestInstitution.text.trim().isEmpty
            ? null
            : _interestInstitution.text.trim(),
        presentationCategory: _interestCategory.text.trim().isEmpty
            ? null
            : _interestCategory.text.trim(),
        title: _interestTitle.text.trim().isEmpty
            ? null
            : _interestTitle.text.trim(),
        description: _interestDescription.text.trim().isEmpty
            ? null
            : _interestDescription.text.trim(),
        sponsorOrganization: _interestSponsorOrg.text.trim().isEmpty
            ? null
            : _interestSponsorOrg.text.trim(),
        sponsorMessage: _interestSponsorMessage.text.trim().isEmpty
            ? null
            : _interestSponsorMessage.text.trim(),
        supportingDocument: _supportingDocument,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participation registration submitted.')),
      );
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _supportingDocument = result.files.first);
  }

  Future<void> _quickRegister() async {
    final event = _event;
    if (event == null) return;
    await _runBusy(() async {
      final result = await _eventsApi.registerForEvent(event.id);
      if (!mounted) return;
      setState(() {
        _event = event.copyWith(
          isRegistered: true,
          registeredCount: result.registeredCount,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _error != null
                      ? _ErrorBanner(message: _error!, onRetry: _load)
                      : _buildContent(_event!),
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

  Widget _buildContent(EventItem event) {
    final programs = event.programs;
    final trackOptions =
        programs.isNotEmpty ? programs : const ['General Sessions'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/my-events'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to events'),
        ),
        const SizedBox(height: 8),
        EventCard(
          title: event.title,
          dateLabel: event.displayDate,
          venueLabel: event.displayVenue,
          registeredCount: event.registeredCount,
          coverImageUrl: event.coverImageUrl,
          registrationOpen: event.registrationOpen,
          isRegistered: event.isRegistered ?? false,
        ),
        if (event.description != null && event.description!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'About this event',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description!,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: AppColors.bodyText,
            ),
          ),
        ],
        if (event.venueAddress != null && event.venueAddress!.isNotEmpty) ...[
          const SizedBox(height: 16),
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
        if (programs.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Program categories',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final program in programs)
                Chip(
                  label: Text(program),
                  backgroundColor: AppColors.muted,
                  labelStyle: GoogleFonts.inter(color: AppColors.heading),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _StatusSection(event: event),
        if (event.registrationOpen) ...[
          const SizedBox(height: 32),
          if (!(event.isRegistered ?? false))
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _quickRegister,
                child: const Text('Quick RSVP'),
              ),
            ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Attendance registration',
            subtitle: 'Register to attend and select program tracks.',
            child: event.hasAttendanceRegistration == true
                ? _SubmittedBanner(
                    label: 'Attendance registration submitted',
                  )
                : _AttendanceForm(
                    trackOptions: trackOptions,
                    selectedTracks: _selectedTracks,
                    onTracksChanged: (tracks) => setState(() {
                      _selectedTracks
                        ..clear()
                        ..addAll(tracks);
                    }),
                    nameController: _attendanceName,
                    emailController: _attendanceEmail,
                    mobileController: _attendanceMobile,
                    membershipController: _attendanceMembership,
                    batchYearController: _attendanceBatchYear,
                    cityController: _attendanceCity,
                    notesController: _attendanceNotes,
                    onSubmit: _submitAttendance,
                  ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Participation registration',
            subtitle:
                'Submit paper, poster, abstract, or sponsor interest.',
            child: event.hasInterestRegistration == true
                ? _SubmittedBanner(
                    label: 'Participation registration submitted',
                  )
                : _ParticipationForm(
                    trackOptions: trackOptions,
                    programTrack: _interestProgramTrack,
                    onProgramTrackChanged: (v) =>
                        setState(() => _interestProgramTrack = v),
                    selectedTypes: _selectedParticipationTypes,
                    onTypesChanged: (types) => setState(
                      () => _selectedParticipationTypes
                        ..clear()
                        ..addAll(types),
                    ),
                    nameController: _interestName,
                    emailController: _interestEmail,
                    mobileController: _interestMobile,
                    membershipController: _interestMembership,
                    batchYearController: _interestBatchYear,
                    specialtyController: _interestSpecialty,
                    institutionController: _interestInstitution,
                    categoryController: _interestCategory,
                    titleController: _interestTitle,
                    descriptionController: _interestDescription,
                    sponsorOrgController: _interestSponsorOrg,
                    sponsorMessageController: _interestSponsorMessage,
                    document: _supportingDocument,
                    onPickDocument: _pickDocument,
                    onSubmit: _submitInterest,
                  ),
          ),
        ],
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your registration status',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'RSVP',
            active: event.isRegistered ?? false,
          ),
          _StatusRow(
            label: 'Attendance',
            active: event.hasAttendanceRegistration ?? false,
          ),
          _StatusRow(
            label: 'Participation',
            active: event.hasInterestRegistration ?? false,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: active ? AppColors.success : AppColors.mutedText,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${active ? 'Submitted' : 'Not submitted'}',
            style: GoogleFonts.inter(color: AppColors.bodyText),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: AppColors.bodyText),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SubmittedBanner extends StatelessWidget {
  const _SubmittedBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: AppColors.heading),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceForm extends StatelessWidget {
  const _AttendanceForm({
    required this.trackOptions,
    required this.selectedTracks,
    required this.onTracksChanged,
    required this.nameController,
    required this.emailController,
    required this.mobileController,
    required this.membershipController,
    required this.batchYearController,
    required this.cityController,
    required this.notesController,
    required this.onSubmit,
  });

  final List<String> trackOptions;
  final Set<String> selectedTracks;
  final ValueChanged<Set<String>> onTracksChanged;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController membershipController;
  final TextEditingController batchYearController;
  final TextEditingController cityController;
  final TextEditingController notesController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Program tracks',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final track in trackOptions)
              FilterChip(
                label: Text(track),
                selected: selectedTracks.contains(track),
                onSelected: (selected) {
                  final next = Set<String>.from(selectedTracks);
                  if (selected) {
                    next.add(track);
                  } else {
                    next.remove(track);
                  }
                  onTracksChanged(next);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        _FormField(label: 'Full name', controller: nameController),
        const SizedBox(height: 12),
        _FormField(label: 'Email', controller: emailController),
        const SizedBox(height: 12),
        _FormField(
          label: 'Mobile',
          controller: mobileController,
          isMobileNumber: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Membership number',
                controller: membershipController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormField(
                label: 'Batch year',
                controller: batchYearController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FormField(label: 'City', controller: cityController),
        const SizedBox(height: 12),
        _FormField(
          label: 'Notes (optional)',
          controller: notesController,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.primary,
          ),
          child: const Text('Submit attendance registration'),
        ),
      ],
    );
  }
}

class _ParticipationForm extends StatelessWidget {
  const _ParticipationForm({
    required this.trackOptions,
    required this.programTrack,
    required this.onProgramTrackChanged,
    required this.selectedTypes,
    required this.onTypesChanged,
    required this.nameController,
    required this.emailController,
    required this.mobileController,
    required this.membershipController,
    required this.batchYearController,
    required this.specialtyController,
    required this.institutionController,
    required this.categoryController,
    required this.titleController,
    required this.descriptionController,
    required this.sponsorOrgController,
    required this.sponsorMessageController,
    required this.document,
    required this.onPickDocument,
    required this.onSubmit,
  });

  final List<String> trackOptions;
  final String? programTrack;
  final ValueChanged<String?> onProgramTrackChanged;
  final Set<String> selectedTypes;
  final ValueChanged<Set<String>> onTypesChanged;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController membershipController;
  final TextEditingController batchYearController;
  final TextEditingController specialtyController;
  final TextEditingController institutionController;
  final TextEditingController categoryController;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController sponsorOrgController;
  final TextEditingController sponsorMessageController;
  final PlatformFile? document;
  final VoidCallback onPickDocument;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final showPresenterFields = selectedTypes.any(
      (t) => t == 'scientific_paper' || t == 'poster' || t == 'abstract',
    );
    final showSponsorFields = selectedTypes.contains('sponsor');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Participation type',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _participationTypes.entries)
              FilterChip(
                label: Text(entry.value),
                selected: selectedTypes.contains(entry.key),
                onSelected: (selected) {
                  final next = Set<String>.from(selectedTypes);
                  if (selected) {
                    next.add(entry.key);
                  } else {
                    next.remove(entry.key);
                  }
                  onTypesChanged(next);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: programTrack,
          decoration: const InputDecoration(
            labelText: 'Program track',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final track in trackOptions)
              DropdownMenuItem(value: track, child: Text(track)),
          ],
          onChanged: onProgramTrackChanged,
        ),
        const SizedBox(height: 16),
        _FormField(label: 'Full name', controller: nameController),
        const SizedBox(height: 12),
        _FormField(label: 'Email', controller: emailController),
        const SizedBox(height: 12),
        _FormField(
          label: 'Mobile',
          controller: mobileController,
          isMobileNumber: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Membership number',
                controller: membershipController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormField(
                label: 'Batch year',
                controller: batchYearController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (showPresenterFields) ...[
          const SizedBox(height: 12),
          _FormField(label: 'Medical specialty', controller: specialtyController),
          const SizedBox(height: 12),
          _FormField(label: 'Institution', controller: institutionController),
          const SizedBox(height: 12),
          _FormField(
            label: 'Presentation category',
            controller: categoryController,
          ),
          const SizedBox(height: 12),
          _FormField(label: 'Title', controller: titleController),
          const SizedBox(height: 12),
          _FormField(
            label: 'Description',
            controller: descriptionController,
            maxLines: 3,
          ),
        ],
        if (showSponsorFields) ...[
          const SizedBox(height: 12),
          _FormField(
            label: 'Sponsor organization',
            controller: sponsorOrgController,
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Sponsor message',
            controller: sponsorMessageController,
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onPickDocument,
          icon: const Icon(Icons.attach_file),
          label: Text(
            document == null
                ? 'Attach supporting document (optional)'
                : document!.name,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.primary,
          ),
          child: const Text('Submit participation registration'),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.isMobileNumber = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool isMobileNumber;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isMobileNumber ? TextInputType.number : keyboardType,
      inputFormatters:
          isMobileNumber ? mobileNumberInputFormatters : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
