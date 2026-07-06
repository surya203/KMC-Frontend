import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_service.dart';
import '../../../core/widgets/page_intro.dart';
import '../../../core/widgets/public_layout.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _submitting = false;
  bool _obscure = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenController.text = widget.initialToken!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
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
      final message = await _authService.resetPassword(
        token: _tokenController.text.trim(),
        newPassword: _passwordController.text,
      );
      setState(() => _successMessage = message);
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Could not reset password.');
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
                  title: 'Reset password',
                  subtitle:
                      'Paste the reset token from your email and choose a new password.',
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
                          _banner(
                            _errorMessage!,
                            isError: true,
                            key: const ValueKey('reset-password-error'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_successMessage != null) ...[
                          _banner(
                            _successMessage!,
                            isError: false,
                            key: const ValueKey('reset-password-success'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            key: const ValueKey('reset-password-go-sign-in'),
                            onPressed: () => context.go('/auth'),
                            child: const Text('Go to sign in'),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _label('RESET TOKEN'),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const ValueKey('reset-password-token-field'),
                          controller: _tokenController,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Reset token is required'
                                  : null,
                          decoration: _decoration(),
                        ),
                        const SizedBox(height: 16),
                        _label('NEW PASSWORD'),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const ValueKey('reset-password-new-field'),
                          controller: _passwordController,
                          obscureText: _obscure,
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                          decoration: _decoration().copyWith(
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          key: const ValueKey('reset-password-submit'),
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
                                  'Set new password',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            key: const ValueKey('reset-password-back'),
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

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: AppColors.mutedText,
      ),
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _banner(String message, {required bool isError, Key? key}) {
    final color = isError ? AppColors.error : AppColors.secondary;
    return Container(
      key: key,
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
