import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/network/events_api_service.dart';
import '../../../core/network/profiles_api_service.dart';

class EventBasicRegistrationResult {
  const EventBasicRegistrationResult({
    required this.fullName,
    required this.email,
    this.mobile,
    this.batchYear,
    this.membershipNumber,
  });

  final String fullName;
  final String email;
  final String? mobile;
  final int? batchYear;
  final String? membershipNumber;
}

Future<EventBasicRegistrationResult?> showEventBasicRegistrationDialog(
  BuildContext context, {
  required String programTitle,
}) {
  return showDialog<EventBasicRegistrationResult>(
    context: context,
    builder: (context) => _EventBasicRegistrationDialog(programTitle: programTitle),
  );
}

class _EventBasicRegistrationDialog extends StatefulWidget {
  const _EventBasicRegistrationDialog({required this.programTitle});

  final String programTitle;

  @override
  State<_EventBasicRegistrationDialog> createState() =>
      _EventBasicRegistrationDialogState();
}

class _EventBasicRegistrationDialogState
    extends State<_EventBasicRegistrationDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _batchYearController = TextEditingController();
  final _membershipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final user = AuthSession.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email;
      if (user.fullName != null) _nameController.text = user.fullName!;
      if (user.membershipNumber != null) {
        _membershipController.text = user.membershipNumber!;
      }
    }
    try {
      final profile = await ProfilesApiService().fetchMyProfile();
      if (!mounted) return;
      if (_nameController.text.isEmpty) {
        _nameController.text = profile.fullName;
      }
      if (_batchYearController.text.isEmpty) {
        _batchYearController.text = '${profile.batchYear}';
      }
      if (_mobileController.text.isEmpty &&
          profile.phone != null &&
          profile.phone!.isNotEmpty) {
        _mobileController.text = profile.phone!;
      }
      setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _batchYearController.dispose();
    _membershipController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) return;

    final mobileRaw = _mobileController.text.trim();
    final mobileError = validateMobileNumber(
      mobileRaw.isEmpty ? null : mobileRaw,
    );
    if (mobileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mobileError)),
      );
      return;
    }

    Navigator.of(context).pop(
      EventBasicRegistrationResult(
        fullName: name,
        email: email,
        mobile: mobileRaw.isEmpty ? null : normalizeMobileNumber(mobileRaw),
        batchYear: int.tryParse(_batchYearController.text.trim()),
        membershipNumber: _membershipController.text.trim().isEmpty
            ? null
            : _membershipController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        'Register — ${widget.programTitle}',
        style: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.heading,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your details to register for this program.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.bodyText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: mobileNumberInputFormatters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _batchYearController,
                decoration: const InputDecoration(
                  labelText: 'Batch year',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _membershipController,
                decoration: const InputDecoration(
                  labelText: 'Membership number (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
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

Future<void> submitBasicEventRegistration({
  required EventsApiService api,
  required String eventId,
  required String programTrack,
  required EventBasicRegistrationResult details,
}) async {
  await api.submitAttendance(
    eventId: eventId,
    programTracks: [programTrack],
    fullName: details.fullName,
    email: details.email,
    mobile: details.mobile,
    batchYear: details.batchYear,
    membershipNumber: details.membershipNumber,
  );
}
