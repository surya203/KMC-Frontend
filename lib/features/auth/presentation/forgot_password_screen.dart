import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_service.dart';
import '../../../core/widgets/page_intro.dart';
import '../../../core/widgets/public_layout.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _submitting = false;
  String? _errorMessage;
  String? _successMessage;
  String? _debugResetToken;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _authService.forgotPassword(
        _emailController.text.trim(),
      );
      setState(() {
        _successMessage = result.message;
        _debugResetToken = result.debugResetToken;
      });
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Could not send reset instructions.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      showFooter: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const PageIntro(
                  title: 'Forgot password',
                  subtitle:
                      'Enter your email and we will send reset instructions if an account exists.',
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          _Banner(
                            key: const ValueKey('forgot-password-error'),
                            message: _errorMessage!,
                            isError: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_successMessage != null) ...[
                          _Banner(
                            key: const ValueKey('forgot-password-success'),
                            message: _successMessage!,
                            isError: false,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_debugResetToken != null) ...[
                          _Banner(
                            key: const ValueKey('forgot-password-debug-token'),
                            message: 'Dev reset token: $_debugResetToken',
                            isError: false,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            key: const ValueKey('forgot-password-reset-now'),
                            onPressed: () => context.go(
                              '/auth/reset-password?token=$_debugResetToken',
                            ),
                            child: const Text('Reset password now'),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          'EMAIL',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const ValueKey('forgot-password-email-field'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Email is required';
                            if (!email.contains('@')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.muted,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          key: const ValueKey('forgot-password-submit'),
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
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
                              : Text(
                                  'Send reset link',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            key: const ValueKey('forgot-password-back'),
                            onPressed: () => context.go('/auth'),
                            child: Text(
                              'Back to sign in',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(color: color, fontSize: 14),
      ),
    );
  }
}
