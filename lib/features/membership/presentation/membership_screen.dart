import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/registration_draft_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/membership_service.dart';
import '../../../core/network/registration_service.dart';
import '../../../core/payments/razorpay_checkout.dart';
import '../../../core/widgets/page_intro.dart';
import '../../../core/widgets/public_layout.dart';
import '../widgets/completion_step.dart';
import '../widgets/details_form.dart';
import '../widgets/payment_step.dart';
import '../widgets/plan_card.dart';
import '../widgets/registration_stepper.dart';
import '../widgets/verification_step.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  static const _steps = ['Plan', 'Details', 'Verify', 'Payment', 'Complete'];

  final _membershipService = MembershipService();
  final _registrationService = RegistrationService();
  final _draftStorage = RegistrationDraftStorage();
  final _detailsFormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _batchYearController = TextEditingController();
  final _phoneController = TextEditingController();
  final _degreeController = TextEditingController(text: 'MBBS');
  final _otpController = TextEditingController();

  List<MembershipPlan> _plans = [];
  MembershipPlan? _selectedPlan;
  String? _draftId;
  int _currentStep = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _uploadingDocument = false;
  bool _emailVerified = false;
  String? _debugOtp;
  String? _otpSentMessage;
  String? _errorMessage;
  CheckoutResult? _checkout;
  CompleteRegistrationResult? _completionResult;
  String? _completionPendingMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _batchYearController.dispose();
    _phoneController.dispose();
    _degreeController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final plans = await _membershipService.fetchPlans();
      final savedDraftId = await _draftStorage.getDraftId();
      final savedStep = await _draftStorage.getWizardStep();

      MembershipPlan? selected;
      RegistrationDraft? draft;

      if (savedDraftId != null) {
        try {
          draft = await _registrationService.getDraft(savedDraftId);
          _draftId = draft.id;
        } catch (_) {
          await _draftStorage.clear();
        }
      }

      if (draft != null) {
        _emailController.text = draft.email ?? '';
        _fullNameController.text = '${draft.payload['full_name'] ?? ''}';
        _batchYearController.text = '${draft.payload['batch_year'] ?? ''}';
        _phoneController.text = '${draft.payload['phone'] ?? ''}';
        _degreeController.text = '${draft.payload['degree'] ?? 'MBBS'}';
      }

      final verified = draft?.verificationToken != null;

      for (final plan in plans) {
        if (draft?.payload['plan_id'] == plan.id) {
          selected = plan;
          break;
        }
      }
      selected ??= plans.isNotEmpty ? plans.first : null;

      setState(() {
        _plans = plans;
        _selectedPlan = selected;
        _emailVerified = verified;
        _currentStep = _resolveStep(savedStep, draft, verified);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _plans = [MembershipPlan.fallback];
        _selectedPlan = MembershipPlan.fallback;
        _loading = false;
      });
    }
  }

  int _resolveStep(int? savedStep, RegistrationDraft? draft, bool verified) {
    if (verified) return 3;
    if (savedStep != null) {
      return savedStep.clamp(0, _steps.length - 1);
    }
    if (draft == null) return 0;
    return draft.step >= 2 ? 1 : 0;
  }

  Future<void> _persistStep(int step) async {
    if (_draftId != null) {
      await _draftStorage.saveDraft(draftId: _draftId!, step: step);
    }
  }

  Future<void> _onPlanContinue() async {
    final plan = _selectedPlan;
    if (plan == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final draft = _draftId == null
          ? await _registrationService.createDraft(
              step: 1,
              payload: {'plan_id': plan.id},
            )
          : await _registrationService.updateDraft(
              draftId: _draftId!,
              step: 1,
              payload: {'plan_id': plan.id},
            );

      _draftId = draft.id;
      await _draftStorage.saveDraft(draftId: draft.id, step: 1);
      setState(() => _currentStep = 1);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _onDetailsContinue() async {
    if (!_detailsFormKey.currentState!.validate() || _draftId == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final draft = await _registrationService.updateDraft(
        draftId: _draftId!,
        step: 2,
        email: _emailController.text.trim(),
        payload: {
          'plan_id': _selectedPlan?.id,
          'full_name': _fullNameController.text.trim(),
          'batch_year': int.parse(_batchYearController.text.trim()),
          'degree': _degreeController.text.trim(),
          'password': _passwordController.text,
          if (_phoneController.text.trim().isNotEmpty)
            'phone': _phoneController.text.trim(),
        },
      );

      await _draftStorage.saveDraft(draftId: draft.id, step: 2);
      setState(() {
        _currentStep = 2;
        _emailVerified = draft.verificationToken != null;
      });
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_draftId == null) return;
    setState(() {
      _sendingOtp = true;
      _errorMessage = null;
      _otpSentMessage = null;
    });

    try {
      final result = await _registrationService.sendOtp(_draftId!);
      setState(() {
        _debugOtp = result.debugOtp;
        _otpSentMessage = result.debugOtp != null
            ? '${result.message} Email is not sent until SMTP is configured — use the code below.'
            : result.message;
      });
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_draftId == null) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _verifyingOtp = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationService.verifyOtp(
        draftId: _draftId!,
        otp: otp,
      );
      if (result.verified) {
        await _draftStorage.saveDraft(draftId: _draftId!, step: 3);
        setState(() {
          _emailVerified = true;
          _currentStep = 3;
        });
      }
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _uploadVerificationDocument() async {
    if (_draftId == null) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file?.bytes == null) {
      setState(() => _errorMessage = 'No file was selected. Choose a PDF, JPG, or PNG.');
      return;
    }

    setState(() {
      _uploadingDocument = true;
      _errorMessage = null;
    });

    try {
      final result = await _registrationService.uploadVerificationDocument(
        draftId: _draftId!,
        bytes: file!.bytes!,
        filename: file.name,
      );
      if (result.verified) {
        await _draftStorage.saveDraft(draftId: _draftId!, step: 3);
        setState(() {
          _emailVerified = true;
          _currentStep = 3;
          _otpSentMessage = null;
        });
      } else {
        setState(() => _errorMessage = result.message);
      }
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _uploadingDocument = false);
    }
  }

  Future<void> _preparePayment() async {
    if (_draftId == null) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    CheckoutResult? checkout;
    try {
      checkout = await _registrationService.createCheckout(_draftId!);
      setState(() => _checkout = checkout);
    } on ApiException catch (error) {
      // Payment service may be unconfigured in dev; completion step will
      // report the pending state.
      setState(() {
        _errorMessage = error.message;
        _submitting = false;
      });
      await _goToCompletion();
      return;
    }

    if (!mounted) return;

    if (razorpayAvailable && checkout.keyId.isNotEmpty) {
      final paid = await openRazorpayCheckout(
        keyId: checkout.keyId,
        orderId: checkout.orderId,
        amountPaise: checkout.amountPaise,
        currency: checkout.currency,
        description: _selectedPlan?.name ?? 'Membership',
        prefillEmail: _emailController.text.trim(),
      );
      if (!mounted) return;
      if (!paid) {
        setState(() {
          _submitting = false;
          _errorMessage =
              'Payment was cancelled. You can try again when ready.';
        });
        return;
      }
    }

    setState(() => _submitting = false);
    await _goToCompletion();
  }

  Future<void> _goToCompletion() async {
    await _persistStep(4);
    setState(() => _currentStep = 4);
    await _checkCompletion();
  }

  Future<void> _checkCompletion() async {
    if (_draftId == null) return;

    setState(() {
      _submitting = true;
      _completionPendingMessage = null;
    });

    try {
      final result = await _registrationService.completeRegistration(_draftId!);
      setState(() {
        _completionResult = result;
        if (result.completed) {
          _draftStorage.clear();
        }
      });
    } on ApiException catch (error) {
      setState(() {
        _completionResult = null;
        _completionPendingMessage = error.message;
      });
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() {
      _currentStep -= 1;
      _errorMessage = null;
    });
    _persistStep(_currentStep);
  }

  bool _canGoNext() {
    if (_submitting ||
        _sendingOtp ||
        _verifyingOtp ||
        _uploadingDocument) {
      return false;
    }
    switch (_currentStep) {
      case 1:
        return true;
      case 2:
        return _emailVerified;
      default:
        return false;
    }
  }

  Future<void> _goNext() async {
    switch (_currentStep) {
      case 1:
        await _onDetailsContinue();
        return;
      case 2:
        if (!_emailVerified) {
          setState(() {
            _errorMessage =
                'Verify your email or upload a document before continuing.';
          });
          return;
        }
        await _persistStep(3);
        if (!mounted) return;
        setState(() {
          _currentStep = 3;
          _errorMessage = null;
        });
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      showFooter: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      const PageIntro(title: 'Join the Alumni Network'),
                      const SizedBox(height: 36),
                      RegistrationStepper(
                        steps: _steps,
                        currentStep: _currentStep,
                      ),
                      const SizedBox(height: 36),
                      if (_errorMessage != null && _currentStep < 4) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildStepContent(),
                      if (_currentStep > 0 && _currentStep < 4) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            TextButton(
                              key: const ValueKey('membership-back-button'),
                              onPressed: _goBack,
                              child: const Text('Back'),
                            ),
                            const Spacer(),
                            if (_currentStep < 3)
                              TextButton(
                                key: const ValueKey('membership-next-button'),
                                onPressed: _canGoNext() ? _goNext : null,
                                child: const Text('Next'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        final plan = _selectedPlan ?? MembershipPlan.fallback;
        return Column(
          children: [
            PlanCard(
              plan: plan,
              selected: true,
              onSelect: () {},
            ),
            if (_plans.length > 1) ...[
              const SizedBox(height: 12),
              for (final item in _plans.where((p) => p.id != plan.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlanCard(
                    plan: item,
                    selected: false,
                    onSelect: () => setState(() => _selectedPlan = item),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('membership-join-button'),
                onPressed: _submitting ? null : _onPlanContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Continue with ${plan.displayPrice}'),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            DetailsForm(
              formKey: _detailsFormKey,
              fullNameController: _fullNameController,
              emailController: _emailController,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              batchYearController: _batchYearController,
              phoneController: _phoneController,
              degreeController: _degreeController,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('membership-details-continue'),
                onPressed: _submitting ? null : _onDetailsContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save and continue'),
              ),
            ),
          ],
        );
      case 2:
        return VerificationStep(
          email: _emailController.text.trim(),
          otpController: _otpController,
          onSendOtp: _sendOtp,
          onVerifyOtp: _verifyOtp,
          onUploadDocument: _emailVerified ? null : _uploadVerificationDocument,
          uploadingDocument: _uploadingDocument,
          sending: _sendingOtp,
          verifying: _verifyingOtp,
          debugOtp: _debugOtp,
          otpSentMessage: _otpSentMessage,
          errorMessage: _errorMessage,
          verified: _emailVerified,
        );
      case 3:
        return PaymentStep(
          plan: _selectedPlan ?? MembershipPlan.fallback,
          checkout: _checkout,
          onContinue: _preparePayment,
          loading: _submitting,
          errorMessage: _errorMessage,
        );
      case 4:
      default:
        return CompletionStep(
          result: _completionResult,
          pendingMessage: _completionPendingMessage,
          onRetry: _checkCompletion,
          retrying: _submitting,
        );
    }
  }
}
