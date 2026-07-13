import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/profile_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/network/auth_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _authService = AuthSession.instance.authService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailPrefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_emailPrefilled) return;
    final email = GoRouterState.of(context).uri.queryParameters['email'];
    if (email == null || email.isEmpty) return;
    _emailPrefilled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emailController.text = email;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email and password are required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tokens = await _authService.login(email: email, password: password);
      await AuthSession.instance.saveLogin(tokens);
      await _authService.fetchMe();
      await ProfileSession.instance.ensureLoaded(force: true);
      if (!mounted) return;
      context.go(homeRouteForRole(AuthSession.instance.currentUser?.role));
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email first, then tap Forgot password.');
      return;
    }

    final newPassword = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _ForgotPasswordDialog(
        email: email,
        authService: _authService,
      ),
    );

    if (!mounted || newPassword == null) return;
    _passwordController.text = newPassword;
    setState(() => _errorMessage = 'Password updated. You can sign in now.');
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 72),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: PublicBackIcon(),
                      ),
                      const SizedBox(height: 8),
                      Text('MY KMC', style: HeadingStyles.eyebrow),
                      const SizedBox(height: 14),
                      Text(
                        'Sign in',
                        style: HeadingStyles.sectionPageTitle(context).copyWith(
                          fontSize: 40,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Use the email and one-time password shown after membership registration.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.bodyText,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthField(
                              label: 'EMAIL',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              required: true,
                            ),
                            const SizedBox(height: 20),
                            _AuthField(
                              label: 'PASSWORD',
                              controller: _passwordController,
                              obscure: true,
                              required: true,
                              onSubmitted: (_) => _signIn(),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Sign in',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: TextButton(
                                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.heading,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: () => context.go('/membership'),
                                child: Text.rich(
                                  TextSpan(
                                    style: GoogleFonts.inter(
                                      color: AppColors.bodyText,
                                      fontSize: 14,
                                    ),
                                    children: const [
                                      TextSpan(text: 'New member? '),
                                      TextSpan(
                                        text: 'Join MY KMC',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.heading,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({
    required this.email,
    required this.authService,
  });

  final String email;
  final AuthService authService;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _statusMessage;
  bool _busy = false;
  bool _obscureNewPassword = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    setState(() {
      _busy = true;
      _statusMessage = 'Sending reset instructions...';
    });
    try {
      final result = await widget.authService.forgotPassword(email: widget.email);
      if (!mounted) return;
      setState(() {
        _statusMessage = result.message;
        if (result.debugResetToken != null) {
          _tokenController.text = result.debugResetToken!;
        }
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyReset() async {
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    if (token.isEmpty || password.length < 8) {
      setState(() {
        _statusMessage = 'Enter the reset token and a password (8+ characters).';
      });
      return;
    }

    setState(() {
      _busy = true;
      _statusMessage = 'Updating password...';
    });
    try {
      await widget.authService.resetPassword(token: token, newPassword: password);
      if (!mounted) return;
      Navigator.of(context).pop(password);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reset password',
        style: GoogleFonts.fraunces(
          fontSize: 42,
          fontWeight: FontWeight.w600,
          color: AppColors.heading,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email: ${widget.email}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.heading,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _requestReset,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Send reset link',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Reset token',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                  tooltip: _obscureNewPassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedText,
                    size: 20,
                  ),
                ),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusMessage!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _applyReset,
          child: const Text('Set new password'),
        ),
      ],
    );
  }
}

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.onSubmitted,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool required;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscure;

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
              TextSpan(text: widget.label),
              if (widget.required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: isPassword && _obscured,
          keyboardType: widget.keyboardType,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.muted,
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
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.mutedText,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
