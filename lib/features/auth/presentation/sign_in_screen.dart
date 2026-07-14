import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/profile_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/network/auth_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/utils/phone_country_codes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/mobile_number_field.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

enum _SignInMethod { email, membershipNumber, phone }

class _LoginMethodOption {
  const _LoginMethodOption({
    required this.method,
    required this.label,
    required this.shortLabel,
    required this.icon,
  });

  final _SignInMethod method;
  final String label;
  final String shortLabel;
  final IconData icon;
}

const _loginMethodOptions = [
  _LoginMethodOption(
    method: _SignInMethod.email,
    label: 'Email',
    shortLabel: 'Email',
    icon: Icons.mail_outline_rounded,
  ),
  _LoginMethodOption(
    method: _SignInMethod.membershipNumber,
    label: 'Membership No.',
    shortLabel: 'Member ID',
    icon: Icons.badge_outlined,
  ),
  _LoginMethodOption(
    method: _SignInMethod.phone,
    label: 'Phone',
    shortLabel: 'Phone',
    icon: Icons.phone_outlined,
  ),
];

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _authService = AuthSession.instance.authService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dialCodeController = TextEditingController(text: '+91');
  final _phoneController = TextEditingController();
  final _membershipNumberController = TextEditingController();
  _SignInMethod _signInMethod = _SignInMethod.email;
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
    _dialCodeController.dispose();
    _phoneController.dispose();
    _membershipNumberController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password is required.');
      return;
    }

    switch (_signInMethod) {
      case _SignInMethod.email:
        final email = _emailController.text.trim();
        if (email.isEmpty) {
          setState(() => _errorMessage = 'Email and password are required.');
          return;
        }
        await _attemptLogin(
          () => _authService.login(email: email, password: password),
        );
      case _SignInMethod.membershipNumber:
        final membershipNumber = _membershipNumberController.text.trim();
        if (membershipNumber.isEmpty) {
          setState(
            () => _errorMessage = 'Membership number and password are required.',
          );
          return;
        }
        await _attemptLogin(
          () => _authService.login(
            membershipNumber: membershipNumber,
            password: password,
          ),
        );
      case _SignInMethod.phone:
        final phone = normalizeMobileNumber(_phoneController.text);
        final dialCode = normalizeDialCode(_dialCodeController.text) ?? '+91';
        final phoneError = validateInternationalMobile(
          dialCode: dialCode,
          localNumber: phone,
          required: true,
        );
        if (phoneError != null) {
          setState(() => _errorMessage = phoneError);
          return;
        }
        await _attemptLogin(
          () => _authService.login(
            phone: phone,
            phoneCountryCode: dialCode,
            password: password,
          ),
        );
    }
  }

  Future<void> _attemptLogin(Future<AuthTokens> Function() login) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tokens = await login();
      await _completeSignIn(tokens);
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

  String get _helperText {
    switch (_signInMethod) {
      case _SignInMethod.email:
        return 'Use the email and password shown after membership registration.';
      case _SignInMethod.membershipNumber:
        return 'Enter your membership number from your dashboard or welcome email.';
      case _SignInMethod.phone:
        return 'Use the mobile number you registered with, plus your password.';
    }
  }

  Future<void> _completeSignIn(AuthTokens tokens) async {
    await AuthSession.instance.saveLogin(tokens);
    await AuthSession.instance.refreshCurrentUser();
    await ProfileSession.instance.ensureLoaded(force: true);
    if (!mounted) return;
    context.go(homeRouteForRole(currentUserRole));
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
                  constraints: const BoxConstraints(maxWidth: 520),
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
                        'Choose how you\'d like to sign in, then enter your password.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.bodyText,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LoginMethodSelector(
                              selected: _signInMethod,
                              onChanged: (method) {
                                setState(() {
                                  _signInMethod = method;
                                  _errorMessage = null;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.04),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                key: ValueKey(_signInMethod),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F6FB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          _loginMethodOptions
                                              .firstWhere(
                                                (option) =>
                                                    option.method == _signInMethod,
                                              )
                                              .icon,
                                          size: 18,
                                          color: AppColors.heading,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _helperText,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              height: 1.45,
                                              color: AppColors.bodyText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (_signInMethod == _SignInMethod.email)
                                    _AuthField(
                                      label: 'EMAIL',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      required: true,
                                    )
                                  else if (_signInMethod ==
                                      _SignInMethod.membershipNumber)
                                    _AuthField(
                                      label: 'MEMBERSHIP NUMBER',
                                      controller: _membershipNumberController,
                                      hintText: 'e.g. 2022sooraj0007',
                                      textCapitalization: TextCapitalization.none,
                                      required: true,
                                    )
                                  else
                                    MobileNumberField(
                                      dialCodeController: _dialCodeController,
                                      numberController: _phoneController,
                                    ),
                                ],
                              ),
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
                            if (_signInMethod == _SignInMethod.email) ...[
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
                            ],
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

class _LoginMethodSelector extends StatelessWidget {
  const _LoginMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  final _SignInMethod selected;
  final ValueChanged<_SignInMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < _loginMethodOptions.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _LoginMethodCard(
                  option: _loginMethodOptions[i],
                  selected: selected == _loginMethodOptions[i].method,
                  onTap: () => onChanged(_loginMethodOptions[i].method),
                  expanded: true,
                ),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < _loginMethodOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _LoginMethodCard(
                  option: _loginMethodOptions[i],
                  selected: selected == _loginMethodOptions[i].method,
                  onTap: () => onChanged(_loginMethodOptions[i].method),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LoginMethodCard extends StatelessWidget {
  const _LoginMethodCard({
    required this.option,
    required this.selected,
    required this.onTap,
    this.expanded = false,
  });

  final _LoginMethodOption option;
  final bool selected;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: expanded ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 16 : 12,
            vertical: expanded ? 14 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(
                      option.icon,
                      size: 20,
                      color: selected ? Colors.white : AppColors.heading,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.heading,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign in with ${option.label.toLowerCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.82)
                                  : AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: selected ? Colors.white : AppColors.mutedText,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option.icon,
                      size: 22,
                      color: selected ? Colors.white : AppColors.heading,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      option.shortLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.heading,
                      ),
                    ),
                  ],
                ),
        ),
      ),
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
    this.hintText,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool required;
  final String? hintText;
  final TextCapitalization textCapitalization;

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
          textCapitalization: widget.textCapitalization,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: GoogleFonts.inter(
              color: AppColors.mutedText,
              fontSize: 14,
            ),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
