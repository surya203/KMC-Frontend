import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/membership_api_service.dart';
import '../../../core/network/registration_service.dart';
import '../../../core/payment/razorpay_checkout.dart';
import '../../../core/theme/heading_styles.dart';
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
  String? _error;

  List<MembershipPlan> _plans = [];
  MembershipPlan? _selectedPlan;
  RegistrationDraft? _draft;
  CompleteRegistrationResult? _completion;

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _batchYearController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  PlatformFile? _profilePhoto;
  String? _debugOtp;

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
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final plans = await _membershipApi.fetchPlans();
      final draftId = await AuthSession.instance.getDraftId();
      RegistrationDraft? draft;
      if (draftId != null) {
        try {
          draft = await _registration.getDraft(draftId);
        } catch (_) {
          await AuthSession.instance.clearDraftId();
        }
      }
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _selectedPlan = plans.isNotEmpty ? plans.first : null;
        _draft = draft;
        _step = _mapDraftStep(draft);
        _hydrateFromDraft(draft);
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

  int _mapDraftStep(RegistrationDraft? draft) {
    if (draft == null) return 0;
    if (draft.payload['registration_completed'] == true) return 4;
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
    _specializationController.text =
        '${draft.payload['specialization'] ?? draft.payload['degree'] ?? ''}';
    final batchYear = draft.payload['batch_year'];
    _batchYearController.text = batchYear != null ? '$batchYear' : '';
    final planId = draft.payload['plan_id'] as String?;
    if (planId != null) {
      _selectedPlan = _plans.where((p) => p.id == planId).firstOrNull ?? _selectedPlan;
    }
  }

  Future<void> _runStep(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = e.toString());
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

  Future<void> _saveDetailsAndSendOtp() async {
    final draft = _draft;
    if (draft == null) throw Exception('Start from plan selection.');

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final specialization = _specializationController.text.trim();
    final batchYear = int.tryParse(_batchYearController.text.trim());

    if (firstName.isEmpty) throw Exception('Enter your first name.');
    if (lastName.isEmpty) throw Exception('Enter your last name.');
    if (batchYear == null) throw Exception('Enter a valid batch year.');
    if (specialization.isEmpty) throw Exception('Enter your specialization.');
    if (phone.isEmpty) throw Exception('Enter your mobile number.');
    if (email.isEmpty) throw Exception('Enter your email.');

    final updated = await _registration.updateDraft(
      draftId: draft.id,
      step: 2,
      email: email,
      payload: {
        'plan_id': _selectedPlan?.id,
        'first_name': firstName,
        'middle_name': _middleNameController.text.trim(),
        'last_name': lastName,
        'full_name': _fullName,
        'batch_year': batchYear,
        'phone': phone,
        'specialization': specialization,
        'email': email,
      },
    );

    final debugOtp = await _registration.sendOtp(draft.id);
    if (!mounted) return;
    setState(() {
      _draft = updated;
      _step = 2;
      _debugOtp = debugOtp.isEmpty ? null : debugOtp;
    });
  }

  Future<void> _sendOtp() async {
    final draft = _draft;
    if (draft == null) return;
    final debugOtp = await _registration.sendOtp(draft.id);
    setState(() => _debugOtp = debugOtp.isEmpty ? null : debugOtp);
  }

  Future<void> _verifyOtp() async {
    final draft = _draft;
    if (draft == null) return;
    await _registration.verifyOtp(
      draftId: draft.id,
      otp: _otpController.text.trim(),
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
        await AuthSession.instance.clearDraftId();
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
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
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
          phoneController: _phoneController,
          emailController: _emailController,
          profilePhotoName: _profilePhoto?.name,
          onPickPhoto: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              withData: true,
            );
            final file = result?.files.single;
            if (file != null) setState(() => _profilePhoto = file);
          },
          onContinue: () => _runStep(_saveDetailsAndSendOtp),
        ),
      2 => _VerifyStep(
          email: _emailController.text.trim(),
          otpController: _otpController,
          debugOtp: _debugOtp,
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
    final subtitle = plan.slug == 'life'
        ? 'One plan. Every benefit. Lifetime access.'
        : (plan.description ?? 'One plan. Every benefit. Lifetime access.');

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
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.5,
              color: AppColors.bodyText,
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
            label: 'Join for ${plan.displayPrice}',
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

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.batchYearController,
    required this.specializationController,
    required this.phoneController,
    required this.emailController,
    required this.profilePhotoName,
    required this.onPickPhoto,
    required this.onContinue,
  });

  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController batchYearController;
  final TextEditingController specializationController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final String? profilePhotoName;
  final VoidCallback onPickPhoto;
  final VoidCallback onContinue;

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
            controller: firstNameController,
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Middle Name',
            controller: middleNameController,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Last Name',
            controller: lastNameController,
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Batch Year',
            controller: batchYearController,
            keyboard: TextInputType.number,
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Specialization',
            controller: specializationController,
            hint: 'e.g. Cardiology',
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Mobile Number',
            controller: phoneController,
            keyboard: TextInputType.phone,
            required: true,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Email',
            controller: emailController,
            keyboard: TextInputType.emailAddress,
            required: true,
          ),
          const SizedBox(height: 16),
          _ProfilePhotoField(
            fileName: profilePhotoName,
            onPick: onPickPhoto,
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Continue — send OTP',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoField extends StatelessWidget {
  const _ProfilePhotoField({
    required this.fileName,
    required this.onPick,
  });

  final String? fileName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload_outlined, size: 18),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          label: Text(
            fileName ?? 'Choose File  No file chosen',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: fileName != null ? AppColors.heading : AppColors.mutedText,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerifyStep extends StatelessWidget {
  const _VerifyStep({
    required this.email,
    required this.otpController,
    required this.debugOtp,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onUploadDocument,
    required this.onBack,
  });

  final String email;
  final TextEditingController otpController;
  final String? debugOtp;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onUploadDocument;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verify your email', style: GoogleFonts.fraunces(fontSize: 24)),
          const SizedBox(height: 8),
          Text('We will send a 6-digit code to $email', style: GoogleFonts.inter()),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onSendOtp, child: const Text('Send verification code')),
          if (debugOtp != null) ...[
            const SizedBox(height: 12),
            Text('Dev OTP: $debugOtp', style: GoogleFonts.inter(color: AppColors.success)),
          ],
          const SizedBox(height: 16),
          _Field(label: 'Enter OTP', controller: otpController, keyboard: TextInputType.number),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Verify OTP', onPressed: onVerifyOtp),
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
  const _CompleteStep({required this.result, required this.onSignIn});

  final CompleteRegistrationResult? result;
  final VoidCallback onSignIn;

  String get _username {
    final email = result?.email ?? '';
    final at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return email.isNotEmpty ? email : '—';
  }

  @override
  Widget build(BuildContext context) {
    final password = result?.debugPassword;

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
          ] else if (result?.message != null) ...[
            const SizedBox(height: 16),
            Text(
              result!.message,
              style: GoogleFonts.inter(color: AppColors.bodyText),
              textAlign: TextAlign.center,
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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.keyboard,
    this.hint,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? hint;
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
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
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
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboard,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
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
