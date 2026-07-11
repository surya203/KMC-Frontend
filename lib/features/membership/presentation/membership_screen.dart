import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/membership_api_service.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/network/registration_service.dart';
import '../../../core/payment/razorpay_checkout.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/utils/membership_number_format.dart';
import '../../../core/utils/phone_country_codes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/mobile_number_field.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  static const _steps = ['Plan', 'Details', 'Verify', 'Payment', 'Complete'];

  final _registration = RegistrationService();
  final _membershipApi = MembershipApiService();

  int _step = 0;
  bool _loading = false;
  bool _bootstrapping = true;
  String? _error;
  String? _info;

  List<MembershipPlan> _plans = [];
  MembershipPlan? _selectedPlan;
  RegistrationDraft? _draft;
  CompleteRegistrationResult? _completion;

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _batchYearController = TextEditingController();
  final _specializationController = TextEditingController();
  final _practiceLocationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dialCodeController = TextEditingController(text: '+91');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  PlatformFile? _profilePhoto;
  Uint8List? _profilePhotoBytes;
  String? _otpStatusMessage;
  String? _devOtpHint;
  bool _otpSent = false;

  String get _fullName {
    final parts = [
      _firstNameController.text.trim(),
      _middleNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((p) => p.isNotEmpty);
    return parts.join(' ');
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _batchYearController.dispose();
    _specializationController.dispose();
    _practiceLocationController.dispose();
    _phoneController.dispose();
    _dialCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootstrapping = true;
      _error = null;
    });
    try {
      final draftId = await AuthSession.instance.getDraftId();
      Future<RegistrationDraft?> draftFuture;
      if (draftId != null) {
        draftFuture = () async {
          try {
            return await _registration.getDraft(draftId);
          } catch (_) {
            await AuthSession.instance.clearDraftId();
            return null;
          }
        }();
      } else {
        draftFuture = Future<RegistrationDraft?>.value(null);
      }

      final results = await Future.wait<dynamic>([
        _membershipApi.fetchPlans(),
        draftFuture,
      ]);

      final plans = results[0] as List<MembershipPlan>;
      final draft = results[1] as RegistrationDraft?;

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _selectedPlan = plans.isNotEmpty ? plans.first : null;
        _draft = draft;
        _step = _mapDraftStep(draft, _completion);
        _hydrateFromDraft(draft);
        _bootstrapping = false;
      });

      if (draft != null &&
          (draft.payload['registration_completed'] == true || draft.step >= 5)) {
        _restoreCompletionInBackground(draft.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyErrorMessage(e);
        _bootstrapping = false;
      });
    }
  }

  Future<void> _restoreCompletionInBackground(String draftId) async {
    try {
      final completion = await _registration.completeRegistration(draftId);
      if (!mounted) return;
      setState(() {
        _completion = completion;
        _step = 4;
      });
    } catch (_) {
      // Keep the wizard usable even if completion sync is still pending.
    }
  }

  int _mapDraftStep(RegistrationDraft? draft, [CompleteRegistrationResult? completion]) {
    if (draft == null) return 0;
    if (draft.payload['registration_completed'] == true || completion?.completed == true) {
      return 4;
    }
    if (draft.step >= 4) return 3;
    if (draft.verificationToken != null || draft.step >= 3) return 3;
    if (draft.step >= 2) return 2;
    if (draft.step >= 1 && draft.email != null) return 1;
    return 0;
  }

  void _hydrateFromDraft(RegistrationDraft? draft) {
    if (draft == null) return;
    _emailController.text = draft.email ?? '${draft.payload['email'] ?? ''}';
    _firstNameController.text = '${draft.payload['first_name'] ?? ''}';
    _middleNameController.text = '${draft.payload['middle_name'] ?? ''}';
    _lastNameController.text = '${draft.payload['last_name'] ?? ''}';
    if (_firstNameController.text.isEmpty) {
      final fullName = '${draft.payload['full_name'] ?? ''}'.trim();
      if (fullName.isNotEmpty) {
        final parts = fullName.split(RegExp(r'\s+'));
        _firstNameController.text = parts.first;
        if (parts.length > 2) {
          _middleNameController.text = parts.sublist(1, parts.length - 1).join(' ');
          _lastNameController.text = parts.last;
        } else if (parts.length == 2) {
          _lastNameController.text = parts.last;
        }
      }
    }
    _phoneController.text = '${draft.payload['phone'] ?? ''}';
    _dialCodeController.text =
        normalizeDialCode(draft.payload['phone_country_code'] as String?) ??
        '+91';
    _practiceLocationController.text =
        '${draft.payload['practice_location'] ?? draft.payload['location'] ?? draft.payload['city'] ?? ''}';
    _specializationController.text =
        '${draft.payload['specialization'] ?? draft.payload['degree'] ?? ''}';
    final batchYear = draft.payload['batch_year'];
    _batchYearController.text = batchYear != null ? '$batchYear' : '';
    final planId = draft.payload['plan_id'] as String?;
    if (planId != null) {
      _selectedPlan = _plans.where((p) => p.id == planId).firstOrNull ?? _selectedPlan;
    }
    if (_hasPendingOtp(draft)) {
      _otpSent = true;
      _otpStatusMessage ??=
          'Check your email for the 6-digit verification code.';
    }
  }

  Future<void> _runStep(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = _friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePlanStep() async {
    final plan = _selectedPlan;
    if (plan == null) throw Exception('Select a membership plan.');

    if (_draft == null) {
      final draft = await _registration.createDraft(planId: plan.id);
      await AuthSession.instance.saveDraftId(draft.id);
      setState(() {
        _draft = draft;
        _step = 1;
      });
    } else {
      final draft = await _registration.updateDraft(
        draftId: _draft!.id,
        step: 1,
        payload: {'plan_id': plan.id},
      );
      setState(() {
        _draft = draft;
        _step = 1;
      });
    }
  }

  void _applyOtpResult(SendOtpResult result) {
    _otpSent = true;
    final debugOtp = result.debugOtp?.trim();
    if (AppConfig.isDevelopment &&
        debugOtp != null &&
        debugOtp.isNotEmpty) {
      _devOtpHint = debugOtp;
      _otpStatusMessage =
          'Your verification code is ready. Enter it below to continue.';
    } else {
      _devOtpHint = null;
      _otpStatusMessage = result.message;
    }
  }

  Future<void> _startFreshRegistration() async {
    await AuthSession.instance.clearDraftId();
    setState(() {
      _draft = null;
      _step = 0;
      _completion = null;
      _error = null;
      _info = 'Started a new registration.';
      _otpSent = false;
      _otpStatusMessage = null;
      _devOtpHint = null;
      _otpController.clear();
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _batchYearController.clear();
      _specializationController.clear();
      _practiceLocationController.clear();
      _phoneController.clear();
      _dialCodeController.text = '+91';
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _profilePhoto = null;
      _profilePhotoBytes = null;
      _selectedPlan = _plans.isNotEmpty ? _plans.first : null;
    });
  }

  Future<void> _continueToPaymentIfVerified() async {
    final draft = _draft;
    if (draft == null) return;
    final refreshed = await _registration.getDraft(draft.id);
    if (refreshed.verificationToken == null) return;
    setState(() {
      _draft = refreshed;
      _step = 3;
      _error = null;
      _info = 'Your email is already verified. Continue to payment.';
    });
  }

  bool _draftEmailMatchesForm(RegistrationDraft draft) {
    final saved =
        (draft.email ?? '${draft.payload['email'] ?? ''}').trim().toLowerCase();
    return saved == _emailController.text.trim().toLowerCase();
  }

  Future<void> _saveDetailsAndSendOtp() async {
    final draft = _draft;
    if (draft == null) throw Exception('Start from plan selection.');

    if (draft.verificationToken != null && !_draftEmailMatchesForm(draft)) {
      await AuthSession.instance.clearDraftId();
      final plan = _selectedPlan;
      if (plan == null) throw Exception('Select a membership plan.');
      final created = await _registration.createDraft(planId: plan.id);
      await AuthSession.instance.saveDraftId(created.id);
      setState(() {
        _draft = created;
        _error = null;
      });
    }

    final activeDraft = _draft;
    if (activeDraft == null) throw Exception('Start from plan selection.');
    if (activeDraft.verificationToken != null) {
      await _continueToPaymentIfVerified();
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final dialCode = _dialCodeController.text.trim();
    final specialization = _specializationController.text.trim();
    final batchYearText = _batchYearController.text.trim();
    final batchYear = int.tryParse(batchYearText);
    final practiceLocation = _practiceLocationController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty) throw Exception('Enter your first name.');
    if (lastName.isEmpty) throw Exception('Enter your last name.');
    if (batchYearText.isEmpty) {
      throw Exception('Enter your batch year.');
    }
    if (batchYear == null || batchYear < 1950 || batchYear > DateTime.now().year) {
      throw Exception('Enter a valid batch year (e.g. 2015).');
    }
    if (specialization.isEmpty) throw Exception('Enter your specialization.');
    if (practiceLocation.isEmpty) throw Exception('Enter your practice location.');
    final phoneError = validateInternationalMobile(
      dialCode: dialCode,
      localNumber: phone,
      required: true,
    );
    if (phoneError != null) throw Exception(phoneError);
    final emailValidation = _validateEmail(email);
    if (emailValidation != null) throw Exception(emailValidation);
    if (password.isEmpty) throw Exception('Create your password.');
    if (confirmPassword != password) {
      throw Exception('Confirm password must match the password.');
    }

    final updated = await _registration.updateDraft(
      draftId: activeDraft.id,
      step: 2,
      email: email,
      payload: {
        'plan_id': _selectedPlan?.id,
        'first_name': firstName,
        'middle_name': _middleNameController.text.trim(),
        'last_name': lastName,
        'full_name': _fullName,
        'batch_year': batchYear,
        'phone': normalizeMobileNumber(phone),
        'phone_country_code': normalizeDialCode(dialCode) ?? '+91',
        'specialization': specialization,
        'practice_location': practiceLocation,
        'email': email,
        'password': password,
      },
    );

    if (_profilePhotoBytes != null) {
      const maxPhotoBytes = 3 * 1024 * 1024;
      if (_profilePhotoBytes!.length > maxPhotoBytes) {
        throw Exception('Profile photo must be 3 MB or smaller.');
      }
      await _registration.uploadDraftPhoto(
        draftId: activeDraft.id,
        fileName: _profilePhoto?.name ?? 'profile-photo.jpg',
        bytes: _profilePhotoBytes!,
      );
    }

    try {
      final otpResult = await _registration.sendOtp(activeDraft.id);
      if (!mounted) return;
      setState(() {
        _draft = updated;
        _step = 2;
        _applyOtpResult(otpResult);
        _info = null;
      });
    } on RegistrationException catch (e) {
      if (!mounted) return;
      if (e.isAlreadyVerified) {
        await _continueToPaymentIfVerified();
        return;
      }
      if (e.isOtpCooldown) {
        final refreshed = await _registration.getDraft(activeDraft.id);
        if (_hasPendingOtp(refreshed)) {
          setState(() {
            _draft = refreshed;
            _step = 2;
            _otpSent = true;
            _otpStatusMessage = _otpCooldownInfoMessage(e);
            _info = _otpCooldownInfoMessage(e);
            _error = null;
          });
          return;
        }
      }
      rethrow;
    }
  }

  Future<void> _sendOtp() async {
    final draft = _draft;
    if (draft == null) return;
    try {
      final otpResult = await _registration.sendOtp(draft.id);
      setState(() {
        _applyOtpResult(otpResult);
        _info = null;
      });
    } on RegistrationException catch (e) {
      if (e.isAlreadyVerified) {
        await _continueToPaymentIfVerified();
        return;
      }
      if (e.isOtpCooldown) {
        setState(() {
          _otpSent = true;
          _info = _otpCooldownInfoMessage(e);
          _error = null;
        });
        return;
      }
      rethrow;
    }
  }

  Future<void> _verifyOtp() async {
    final draft = _draft;
    if (draft == null) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6 || int.tryParse(otp) == null) {
      throw Exception('Enter the 6-digit code from your email.');
    }
    await _registration.verifyOtp(
      draftId: draft.id,
      otp: otp,
    );
    final refreshed = await _registration.getDraft(draft.id);
    setState(() {
      _draft = refreshed;
      _step = 3;
    });
  }

  Future<void> _uploadDocument() async {
    final draft = _draft;
    if (draft == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.first;
    if (file == null || file.bytes == null) {
      throw Exception('No document selected.');
    }
    await _registration.uploadVerificationDocument(
      draftId: draft.id,
      fileName: file.name,
      bytes: file.bytes!,
    );
    final refreshed = await _registration.getDraft(draft.id);
    setState(() {
      _draft = refreshed;
      _step = 3;
    });
  }

  Future<void> _startPayment() async {
    final draft = _draft;
    if (draft == null) return;

    final checkout = await _membershipApi.createCheckout(draft.id);
    final email = _emailController.text.trim();
    final keyId = checkout.keyId;

    if (keyId.isEmpty) {
      await _pollCompletion(draft.id);
      return;
    }

    await openRazorpayCheckout(
      keyId: keyId,
      orderId: checkout.orderId,
      amountPaise: checkout.amountPaise,
      currency: checkout.currency,
      name: _fullName,
      email: email,
      onSuccess: () async {
        await _pollCompletion(draft.id);
      },
      onDismiss: (message) {
        if (mounted) setState(() => _error = message);
      },
    );
  }

  Future<void> _pollCompletion(String draftId) async {
    setState(() => _loading = true);
    for (var i = 0; i < 8; i++) {
      try {
        final result = await _registration.completeRegistration(draftId);
        if (!mounted) return;
        setState(() {
          _completion = result;
          _step = 4;
          _loading = false;
        });
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    if (mounted) {
      setState(() {
        _error = 'Payment received but registration is still processing. Try again shortly.';
        _loading = false;
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
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 72),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      Text('MY KMC', style: HeadingStyles.eyebrow),
                      const SizedBox(height: 14),
                      HeadingStyles.sectionTitleWidget(
                        context,
                        regular: 'Join the Alumni ',
                        italic: 'Network',
                      ),
                      const SizedBox(height: 40),
                      _StepperRow(steps: _steps, currentStep: _step),
                      const SizedBox(height: 40),
                      if (_info != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _info!,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                              if (_error!.toLowerCase().contains('already verified')) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _loading ? null : _continueToPaymentIfVerified,
                                      child: const Text('Continue to payment'),
                                    ),
                                    TextButton(
                                      onPressed: _loading ? null : _startFreshRegistration,
                                      child: const Text('Start new registration'),
                                    ),
                                  ],
                                ),
                              ] else if (_plans.isEmpty) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _bootstrapping ? null : _bootstrap,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Try again'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (_bootstrapping)
                        const _PlanStepSkeleton()
                      else if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        _buildStepContent(),
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

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.bytes!.length > 3 * 1024 * 1024) {
      setState(() => _error = 'Profile photo must be 3 MB or smaller.');
      return;
    }
    setState(() {
      _profilePhoto = file;
      _profilePhotoBytes = file.bytes;
      _error = null;
    });
  }

  Future<void> _captureProfilePhoto() async {
    final captured = await captureImageWithLivePreview(context);
    if (captured == null) return;
    if (captured.bytes.length > 3 * 1024 * 1024) {
      setState(() => _error = 'Profile photo must be 3 MB or smaller.');
      return;
    }
    setState(() {
      _profilePhoto = PlatformFile(
        name: captured.fileName,
        size: captured.bytes.length,
        bytes: captured.bytes,
      );
      _profilePhotoBytes = captured.bytes;
      _error = null;
    });
  }

  void _removeProfilePhoto() {
    setState(() {
      _profilePhoto = null;
      _profilePhotoBytes = null;
      _error = null;
    });
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _PlanStep(
          plans: _plans,
          selected: _selectedPlan,
          onSelect: (plan) => setState(() => _selectedPlan = plan),
          onContinue: () => _runStep(_savePlanStep),
        ),
      1 => _DetailsStep(
          firstNameController: _firstNameController,
          middleNameController: _middleNameController,
          lastNameController: _lastNameController,
          batchYearController: _batchYearController,
          specializationController: _specializationController,
          practiceLocationController: _practiceLocationController,
          phoneController: _phoneController,
          dialCodeController: _dialCodeController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          profilePhotoBytes: _profilePhotoBytes,
          profilePhotoName: _profilePhoto?.name,
          onCapturePhoto: _captureProfilePhoto,
          onPickPhoto: _pickProfilePhoto,
          onRemovePhoto: _removeProfilePhoto,
          onContinue: () => _runStep(_saveDetailsAndSendOtp),
        ),
      2 => _VerifyStep(
          email: _emailController.text.trim(),
          otpController: _otpController,
          otpSent: _otpSent,
          statusMessage: _otpStatusMessage,
          devOtpHint: _devOtpHint,
          onSendOtp: () => _runStep(_sendOtp),
          onVerifyOtp: () => _runStep(_verifyOtp),
          onUploadDocument: () => _runStep(_uploadDocument),
          onBack: () => setState(() => _step = 1),
        ),
      3 => _PaymentStep(
          plan: _selectedPlan,
          onBack: () => setState(() => _step = 2),
          onPay: () => _runStep(_startPayment),
        ),
      _ => _CompleteStep(
          result: _completion,
          fullName: _fullName,
          batchYear: int.tryParse(_batchYearController.text.trim()),
          membershipApi: _membershipApi,
          onSignIn: () {
            final email = _completion?.email ?? _emailController.text.trim();
            if (email.isNotEmpty) {
              context.go('/auth?email=${Uri.encodeComponent(email)}');
            } else {
              context.go('/auth');
            }
          },
        ),
    };
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({required this.steps, required this.currentStep});

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 28),
                color: i <= currentStep ? AppColors.primary : AppColors.border,
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: i < currentStep
                    ? AppColors.secondary
                    : i == currentStep
                        ? AppColors.primary
                        : AppColors.muted,
                child: i < currentStep
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: i == currentStep
                              ? Colors.white
                              : AppColors.mutedText,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                steps[i],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: i == currentStep ? FontWeight.w700 : FontWeight.w500,
                  color: i <= currentStep ? AppColors.heading : AppColors.mutedText,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PlanStepSkeleton extends StatelessWidget {
  const _PlanStepSkeleton();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 48),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            height: 52,
            width: 140,
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 120),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 20),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.plans,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
  });

  final List<MembershipPlan> plans;
  final MembershipPlan? selected;
  final ValueChanged<MembershipPlan> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Text(
        'No membership plans available.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: AppColors.bodyText),
      );
    }

    final plan = selected ?? plans.first;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            plan.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.displayPrice,
                style: GoogleFonts.fraunces(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'one-time',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          for (final benefit in plan.benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.heading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Please Join',
            onPressed: () {
              onSelect(plan);
              onContinue();
            },
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatefulWidget {
  const _DetailsStep({
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.batchYearController,
    required this.specializationController,
    required this.practiceLocationController,
    required this.phoneController,
    required this.dialCodeController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.profilePhotoBytes,
    required this.profilePhotoName,
    required this.onCapturePhoto,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onContinue,
  });

  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController batchYearController;
  final TextEditingController specializationController;
  final TextEditingController practiceLocationController;
  final TextEditingController phoneController;
  final TextEditingController dialCodeController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Uint8List? profilePhotoBytes;
  final String? profilePhotoName;
  final Future<void> Function() onCapturePhoto;
  final Future<void> Function() onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onContinue;

  @override
  State<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<_DetailsStep> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your details',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 24),
          _FormField(
            label: 'First Name',
            controller: widget.firstNameController,
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Middle Name',
            controller: widget.middleNameController,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Last Name',
            controller: widget.lastNameController,
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Batch Year',
            controller: widget.batchYearController,
            keyboard: TextInputType.number,
            hint: '2015',
            required: true,
            helperText: 'Year of graduation or completion',
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Specialization',
            controller: widget.specializationController,
            hint: 'e.g. Cardiology',
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Practice Location',
            controller: widget.practiceLocationController,
            hint: 'Hospital or clinic where you practice',
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Email Address',
            controller: widget.emailController,
            keyboard: TextInputType.emailAddress,
            hint: 'name@example.com',
            required: true,
            helperText: 'Use your active email for OTP and login',
          ),
          const SizedBox(height: 16),
          MobileNumberField(
            dialCodeController: widget.dialCodeController,
            numberController: widget.phoneController,
          ),
          const SizedBox(height: 16),
          AutofillGroup(
            child: Column(
              children: [
                _PasswordFormField(
                  label: 'Create Password',
                  controller: widget.passwordController,
                  required: true,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  onToggleVisibility: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                const SizedBox(height: 16),
                _PasswordFormField(
                  label: 'Confirm Password',
                  controller: widget.confirmPasswordController,
                  required: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose any password you prefer. Enter the same password in both fields.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _ProfilePhotoField(
            photoBytes: widget.profilePhotoBytes,
            fileName: widget.profilePhotoName,
            onCapture: widget.onCapturePhoto,
            onUpload: widget.onPickPhoto,
            onRemove: widget.onRemovePhoto,
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Continue — send OTP',
            onPressed: widget.onContinue,
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoField extends StatefulWidget {
  const _ProfilePhotoField({
    required this.photoBytes,
    required this.fileName,
    required this.onCapture,
    required this.onUpload,
    required this.onRemove,
  });

  final Uint8List? photoBytes;
  final String? fileName;
  final Future<void> Function() onCapture;
  final Future<void> Function() onUpload;
  final VoidCallback onRemove;

  @override
  State<_ProfilePhotoField> createState() => _ProfilePhotoFieldState();
}

class _ProfilePhotoFieldState extends State<_ProfilePhotoField> {
  Future<void> _handleMenuAction(_PhotoMenuAction action) async {
    switch (action) {
      case _PhotoMenuAction.capture:
        await widget.onCapture();
      case _PhotoMenuAction.upload:
        await widget.onUpload();
      case _PhotoMenuAction.remove:
        widget.onRemove();
    }
  }

  Future<void> _openPhotoSheet(BuildContext context) async {
    final hasPhoto = widget.photoBytes != null;
    final selected = await showModalBottomSheet<_PhotoMenuAction>(
      context: context,
      backgroundColor: const Color(0xFFF4F4F6),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PhotoSheetGroup(
                  children: [
                    _PhotoSheetAction(
                      icon: Icons.photo_camera_outlined,
                      label: 'Camera',
                      onTap: () => Navigator.pop(context, _PhotoMenuAction.capture),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8E8ED)),
                    _PhotoSheetAction(
                      icon: Icons.photo_outlined,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(context, _PhotoMenuAction.upload),
                    ),
                    if (hasPhoto) ...[
                      const Divider(height: 1, color: Color(0xFFE8E8ED)),
                      _PhotoSheetAction(
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        destructive: true,
                        onTap: () =>
                            Navigator.pop(context, _PhotoMenuAction.remove),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _PhotoSheetGroup(
                  children: [
                    _PhotoSheetAction(
                      label: 'Cancel',
                      centered: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    await _handleMenuAction(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFILE PICTURE (OPTIONAL)',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _openPhotoSheet(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(28),
                          image: hasPhoto
                              ? DecorationImage(
                                  image: MemoryImage(widget.photoBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: hasPhoto
                            ? null
                            : const Icon(
                                Icons.person_outline_rounded,
                                size: 28,
                                color: AppColors.mutedText,
                              ),
                      ),
                      if (!hasPhoto)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPhoto ? 'Change photo' : 'Add photo',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.heading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPhoto
                              ? (widget.fileName ?? 'Photo added')
                              : 'Camera or gallery',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: hasPhoto
                                ? AppColors.success
                                : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedText.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _PhotoMenuAction { capture, upload, remove }

class _PhotoSheetGroup extends StatelessWidget {
  const _PhotoSheetGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class _PhotoSheetAction extends StatelessWidget {
  const _PhotoSheetAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
    this.centered = false,
  });

  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.primary;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: centered
              ? Center(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 22, color: color),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: color,
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

class _VerifyStep extends StatelessWidget {
  const _VerifyStep({
    required this.email,
    required this.otpController,
    required this.otpSent,
    required this.statusMessage,
    required this.devOtpHint,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onUploadDocument,
    required this.onBack,
  });

  final String email;
  final TextEditingController otpController;
  final bool otpSent;
  final String? statusMessage;
  final String? devOtpHint;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onUploadDocument;
  final VoidCallback onBack;

  Future<void> _copyDevOtp(BuildContext context) async {
    final code = devOtpHint;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test code copied')),
    );
  }

  void _fillDevOtp() {
    final code = devOtpHint;
    if (code == null || code.isEmpty) return;
    otpController.text = code;
  }

  @override
  Widget build(BuildContext context) {
    final showDevOtp =
        devOtpHint != null && devOtpHint!.isNotEmpty && AppConfig.isDevelopment;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verify your email', style: GoogleFonts.fraunces(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            otpSent
                ? 'We sent a 6-digit verification code to $email'
                : 'We will send a 6-digit code to $email',
            style: GoogleFonts.inter(),
          ),
          const SizedBox(height: 8),
          Text(
            showDevOtp
                ? 'If the email has not arrived yet, use the verification code shown below.'
                : otpSent
                    ? 'Check your inbox and spam folder, then enter the code below.'
                    : 'Tap the button below to receive your verification code.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 20),
          if (!otpSent)
            OutlinedButton(
              onPressed: onSendOtp,
              child: const Text('Send verification code'),
            ),
          if (statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              statusMessage!,
              style: GoogleFonts.inter(
                color: showDevOtp ? AppColors.secondary : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showDevOtp) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    'YOUR VERIFICATION CODE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    devOtpHint!,
                    style: GoogleFonts.fraunces(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _copyDevOtp(context),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy code'),
                      ),
                      TextButton.icon(
                        onPressed: _fillDevOtp,
                        icon: const Icon(Icons.input_rounded, size: 18),
                        label: const Text('Fill field'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (otpSent) ...[
            const SizedBox(height: 16),
            _Field(
              label: 'Enter 6-digit code',
              controller: otpController,
              keyboard: TextInputType.number,
              maxLength: 6,
              hintText: '000000',
            ),
            const SizedBox(height: 16),
            _PrimaryButton(label: 'Verify code', onPressed: onVerifyOtp),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSendOtp,
              child: const Text('Resend code'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onUploadDocument,
            child: const Text('Upload document instead (PDF/JPG/PNG)'),
          ),
          TextButton(onPressed: onBack, child: const Text('Back')),
        ],
      ),
    );
  }
}

class _PaymentStep extends StatefulWidget {
  const _PaymentStep({
    required this.plan,
    required this.onBack,
    required this.onPay,
  });

  final MembershipPlan? plan;
  final VoidCallback onBack;
  final VoidCallback onPay;

  @override
  State<_PaymentStep> createState() => _PaymentStepState();
}

enum _PaymentMethod { upi, card, bank }

class _PaymentStepState extends State<_PaymentStep> {
  _PaymentMethod _method = _PaymentMethod.upi;
  final _upiController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  bool get _isDemo =>
      AppConfig.razorpayKeyId.isEmpty || AppConfig.env == 'development';

  String get _price => widget.plan?.displayPrice ?? '₹1,000';

  String get _planLabel =>
      'MY KMC — ${widget.plan?.name ?? 'Life Membership'}';

  String get _payLabel => switch (_method) {
        _PaymentMethod.upi => 'Pay $_price via UPI',
        _PaymentMethod.card => 'Pay $_price via Card',
        _PaymentMethod.bank => 'Pay $_price via Bank transfer',
      };

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Payment',
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              if (_isDemo) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Demo — no real charge',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _planLabel,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.heading,
                    ),
                  ),
                ),
                Text(
                  _price,
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _PaymentMethodTabs(
            selected: _method,
            onChanged: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_method) {
              _PaymentMethod.upi => _buildUpiPanel(key: const ValueKey('upi')),
              _PaymentMethod.card =>
                _buildCardPanel(key: const ValueKey('card')),
              _PaymentMethod.bank =>
                _buildBankPanel(key: const ValueKey('bank')),
            },
          ),
          const SizedBox(height: 28),
          _PrimaryButton(label: _payLabel, onPressed: widget.onPay),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onBack,
            child: Text(
              'Back',
              style: GoogleFonts.inter(color: AppColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiPanel({required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPI ID',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _upiController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'yourname@okhdfcbank',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "You'll get a collect request on your UPI app.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPanel({required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaymentInputLabel('Card number'),
          const SizedBox(height: 8),
          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            decoration: _paymentInputDecoration(hint: '4242 4242 4242 4242'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PaymentInputLabel('Expiry'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cardExpiryController,
                      decoration: _paymentInputDecoration(hint: 'MM / YY'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PaymentInputLabel('CVV'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cardCvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: _paymentInputDecoration(hint: '•••'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Secured by Razorpay. Your card details are encrypted.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankPanel({required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BankDetailRow(label: 'Account name', value: 'KMC Alumni Association'),
          const SizedBox(height: 12),
          _BankDetailRow(label: 'Bank', value: 'State Bank of India'),
          const SizedBox(height: 12),
          _BankDetailRow(label: 'Account no.', value: 'XXXX XXXX 1234'),
          const SizedBox(height: 12),
          _BankDetailRow(label: 'IFSC', value: 'SBIN0001234'),
          const SizedBox(height: 14),
          Text(
            'Use your registered email as payment reference. Membership activates after verification.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _paymentInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _PaymentMethodTabs extends StatelessWidget {
  const _PaymentMethodTabs({
    required this.selected,
    required this.onChanged,
  });

  final _PaymentMethod selected;
  final ValueChanged<_PaymentMethod> onChanged;

  static const _tabs = [
    (_PaymentMethod.upi, 'UPI'),
    (_PaymentMethod.card, 'Card'),
    (_PaymentMethod.bank, 'Bank transfer'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 4 : 0),
                child: _PaymentTab(
                  label: _tabs[i].$2,
                  selected: selected == _tabs[i].$1,
                  onTap: () => onChanged(_tabs[i].$1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentTab extends StatelessWidget {
  const _PaymentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.bodyText,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentInputLabel extends StatelessWidget {
  const _PaymentInputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.mutedText,
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  const _BankDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.mutedText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompleteStep extends StatelessWidget {
  const _CompleteStep({
    required this.result,
    required this.fullName,
    required this.batchYear,
    required this.membershipApi,
    required this.onSignIn,
  });

  final CompleteRegistrationResult? result;
  final String fullName;
  final int? batchYear;
  final MembershipApiService membershipApi;
  final VoidCallback onSignIn;

  String get _username {
    final email = result?.email ?? '';
    final at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return email.isNotEmpty ? email : '—';
  }

  Future<void> _openReceipt() async {
    final url = result?.receiptUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final password = result?.debugPassword;
    final receiptUrl = result?.receiptUrl;
    final receiptId = result?.receiptId;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.heading,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to MY KMC',
            style: GoogleFonts.fraunces(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your membership is active. Save these login details — they\'re shown only once.',
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: AppColors.bodyText,
            ),
            textAlign: TextAlign.center,
          ),
          if (result?.membershipNumber != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _CredentialRow(
                    label: 'MEMBERSHIP NO.',
                    value: MembershipNumberFormat.displayOrFallback(
                      storedMembershipNumber: result!.membershipNumber,
                      batchYear: batchYear,
                      fullName: fullName,
                    ),
                  ),
                  if (result?.receiptNumber != null) ...[
                    const SizedBox(height: 16),
                    _CredentialRow(
                      label: 'RECEIPT NO.',
                      value: result!.receiptNumber!,
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      receiptUrl != null && receiptUrl.isNotEmpty
                          ? Icons.check_circle
                          : Icons.schedule,
                      color: receiptUrl != null && receiptUrl.isNotEmpty
                          ? AppColors.success
                          : AppColors.bodyText,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        receiptUrl != null && receiptUrl.isNotEmpty
                            ? 'Payment receipt ready'
                            : 'Generating your payment receipt...',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Download your official PDF receipt with membership details, receipt ID, and transaction number.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.bodyText,
                  ),
                ),
                if (receiptId != null && receiptId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Receipt ID: $receiptId',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.heading,
                    ),
                  ),
                ],
                if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openReceipt,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Download PDF receipt'),
                  ),
                ],
              ],
            ),
          ),
          if (password != null) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _CredentialRow(
                    label: 'USERNAME',
                    value: _username,
                  ),
                  const SizedBox(height: 16),
                  _CredentialRow(
                    label: 'PASSWORD',
                    value: password,
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.mutedText,
                      ),
                      children: [
                        const TextSpan(text: 'Sign in at '),
                        TextSpan(
                          text: '/auth',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.heading,
                          ),
                        ),
                        const TextSpan(
                          text: ' with email and the password above.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              result?.message.isNotEmpty == true
                  ? result!.message
                  : 'Your membership is active. Use the password you created during registration. '
                      'If you forgot it, use Forgot password on the login page.',
              style: GoogleFonts.inter(color: AppColors.bodyText),
              textAlign: TextAlign.center,
            ),
          ],
          if (result?.receiptHtml != null || result?.paymentId != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final receiptNumber = result?.receiptNumber ?? 'KMC-RCP';
                if (result?.receiptHtml != null) {
                  await downloadTextFile(
                    fileName: '$receiptNumber.html',
                    content: result!.receiptHtml!,
                    mimeType: 'text/html',
                  );
                  return;
                }
                if (result?.paymentId != null) {
                  try {
                    final html = await membershipApi.fetchPaymentReceiptHtml(
                      result!.paymentId!,
                    );
                    await downloadTextFile(
                      fileName: '$receiptNumber.html',
                      content: html,
                      mimeType: 'text/html',
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download payment receipt'),
            ),
          ],
          const SizedBox(height: 28),
          _PrimaryButton(label: 'Go to login', onPressed: onSignIn),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_outlined, size: 18),
                color: AppColors.mutedText,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Copy',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _PasswordFormField extends StatelessWidget {
  const _PasswordFormField({
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.autofillHints,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final Iterable<String>? autofillHints;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.mutedText,
            ),
            children: [
              TextSpan(text: label.toUpperCase()),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autofillHints: autofillHints,
          enableSuggestions: false,
          autocorrect: false,
          enableInteractiveSelection: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              tooltip: obscureText ? 'Show password' : 'Hide password',
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.mutedText,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.keyboard,
    this.hint,
    this.required = false,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? hint;
  final bool required;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.mutedText,
            ),
            children: [
              TextSpan(text: label.toUpperCase()),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.mutedText,
            ),
            helperText: helperText,
            helperStyle: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.mutedText,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

String? _validateEmail(String email) {
  if (email.isEmpty) return 'Enter your email address.';
  final normalized = email.trim();
  final emailPattern = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  if (!emailPattern.hasMatch(normalized)) {
    return 'Enter a valid email like name@example.com.';
  }
  return null;
}

String _friendlyErrorMessage(Object error) {
  if (error is RegistrationException) {
    if (error.isAlreadyVerified) {
      return 'This registration was already verified. Continue to payment, '
          'or start a new registration for a different doctor.';
    }
    return sanitizeUserFacingMessage(error.message);
  }
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  final lower = raw.toLowerCase();

  if (lower.contains('invalid email')) {
    return 'Enter a valid email like name@example.com.';
  }
  if (lower.contains('value_error') && lower.contains('email')) {
    return 'Email format is invalid. Use format name@example.com.';
  }
  if (lower.contains('confirm password must match')) {
    return raw;
  }
  if (lower.startsWith('password must')) {
    return raw;
  }
  if (lower.contains('profile photo')) {
    return raw;
  }
  if (lower.contains('failed to upload profile photo')) {
    return raw;
  }
  if (lower.contains('membership request failed') ||
      lower.contains('cannot reach the server') ||
      lower.contains('taking too long')) {
    return raw;
  }
  return sanitizeUserFacingMessage(raw);
}

bool _hasPendingOtp(RegistrationDraft draft) {
  final payload = draft.payload;
  if (payload['otp_hash'] == null && payload['otp_sent_at'] == null) {
    return false;
  }
  final expiresRaw = payload['otp_expires_at'];
  if (expiresRaw == null) return payload['otp_sent_at'] != null;
  try {
    final expiry = DateTime.parse('$expiresRaw'.replaceFirst('Z', ''));
    final now = DateTime.now().toUtc();
    final expiryUtc = expiry.isUtc ? expiry : expiry.toUtc();
    return expiryUtc.isAfter(now);
  } catch (_) {
    return payload['otp_sent_at'] != null;
  }
}

String _otpCooldownInfoMessage(RegistrationException e) {
  final wait = e.retryAfterSeconds;
  if (wait != null && wait > 0) {
    return 'A verification code was already sent. You can request a new one in ${wait}s.';
  }
  return 'A verification code was already sent. Check your email inbox.';
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboard,
    this.maxLength,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final int? maxLength;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLength: maxLength,
      inputFormatters: maxLength != null
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: maxLength != null ? '' : null,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
