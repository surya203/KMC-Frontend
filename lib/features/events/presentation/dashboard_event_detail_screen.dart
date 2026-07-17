import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/membership_number_format.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/event_card.dart';

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
  final _attendanceSpecialty = TextEditingController();
  final _attendanceAttendees = TextEditingController(text: '1');
  final _attendanceNotes = TextEditingController();

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
    _attendanceSpecialty.dispose();
    _attendanceAttendees.dispose();
    _attendanceNotes.dispose();
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
      MyProfile? profile;
      try {
        profile = await _profilesApi.fetchMyProfile();
        if (!mounted) return;
        _attendanceName.text = profile.fullName;
        _attendanceBatchYear.text = '${profile.batchYear}';
        if (profile.phone != null && profile.phone!.isNotEmpty) {
          _attendanceMobile.text = profile.phone!;
        }
      } catch (_) {
        // Profile optional for prefill.
      }
      _applyMembershipPrefill(profile: profile);
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
      if (user.fullName != null && user.fullName!.isNotEmpty) {
        _attendanceName.text = user.fullName!;
      }
    }
    _applyMembershipPrefill();
  }

  void _applyMembershipPrefill({MyProfile? profile}) {
    final user = AuthSession.instance.currentUser;
    final formatted = MembershipNumberFormat.display(
      storedMembershipNumber: user?.membershipNumber,
      batchYear: profile?.batchYear ?? user?.batchYear,
      fullName: profile?.fullName ?? user?.fullName,
    );
    if (formatted == null) return;
    _attendanceMembership.text = formatted;
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
    final name = _attendanceName.text.trim();
    final email = _attendanceEmail.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required.')),
      );
      return;
    }
    final specialty = _attendanceSpecialty.text.trim();
    if (specialty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Specialty is required.')),
      );
      return;
    }
    final attendeesCount = int.tryParse(_attendanceAttendees.text.trim());
    if (attendeesCount == null || attendeesCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid number of people attending.'),
        ),
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
        programTracks: const [],
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
        specialty: specialty,
        attendeesCount: attendeesCount,
        notes: _attendanceNotes.text.trim().isEmpty
            ? null
            : _attendanceNotes.text.trim(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration submitted.')),
      );
    });
  }

  Future<void> _cancelAttendance() async {
    final event = _event;
    if (event == null) return;
    await _runBusy(() async {
      await _eventsApi.cancelAttendance(event.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration cancelled.')),
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
        if (event.registrationOpen) ...[
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Registration form',
            child: event.hasAttendanceRegistration == true
                ? _SubmittedBanner(
                    label: 'Registration submitted',
                    onCancel: _cancelAttendance,
                  )
                : _AttendanceForm(
                    nameController: _attendanceName,
                    emailController: _attendanceEmail,
                    mobileController: _attendanceMobile,
                    membershipController: _attendanceMembership,
                    batchYearController: _attendanceBatchYear,
                    cityController: _attendanceCity,
                    specialtyController: _attendanceSpecialty,
                    attendeesController: _attendanceAttendees,
                    notesController: _attendanceNotes,
                    onSubmit: _submitAttendance,
                  ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SubmittedBanner extends StatelessWidget {
  const _SubmittedBanner({required this.label, this.onCancel});

  final String label;
  final VoidCallback? onCancel;

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
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}

class _AttendanceForm extends StatelessWidget {
  const _AttendanceForm({
    required this.nameController,
    required this.emailController,
    required this.mobileController,
    required this.membershipController,
    required this.batchYearController,
    required this.cityController,
    required this.specialtyController,
    required this.attendeesController,
    required this.notesController,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController membershipController;
  final TextEditingController batchYearController;
  final TextEditingController cityController;
  final TextEditingController specialtyController;
  final TextEditingController attendeesController;
  final TextEditingController notesController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        _FormField(label: 'Specialty', controller: specialtyController),
        const SizedBox(height: 12),
        _FormField(
          label: 'Number of people attending',
          controller: attendeesController,
          keyboardType: TextInputType.number,
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
          child: const Text('Submit registration'),
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
