import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/profile_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/business_info.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/network/auth_service.dart';
import '../widgets/dashboard_layout.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _deleting = false;

  static const _confirmPhrase = 'DELETE';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _typedConfirm =>
      _confirmController.text.trim().toUpperCase() == _confirmPhrase;

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      _showMessage('Enter your password to delete your account.');
      return;
    }
    if (!_typedConfirm) {
      _showMessage('Type $_confirmPhrase to confirm account deletion.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: const Text(
          'This permanently deletes your KMC Alumni Connect account and the '
          'personal data associated with it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await AuthSession.instance.deleteAccount(password: password);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Account deleted'),
          content: const Text(
            'Your account has been permanently deleted. You can create a new '
            'account later if you wish.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await ProfileSession.instance.clearForAccountDeletion();
      await AuthSession.instance.clearDraftId();
      await AuthSession.instance.clearSession();
      if (!mounted) return;
      context.go('/auth');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showMessage(friendlyApiError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showMessage(friendlyApiError(e));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = DashboardLayout.isCompact(context);
    final email = AuthSession.instance.currentUser?.email ?? 'your account';

    return SingleChildScrollView(
      padding: DashboardLayout.screenPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permanently delete $email and the personal data stored with it.',
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 14 : 15,
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(DashboardLayout.cardPadding(context) - 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What is deleted',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your login, alumni profile, directory listing, event RSVPs, '
                      'messages, photos, and verification documents are removed. '
                      'You will be signed out and will not be able to use this '
                      'account again.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Payment records needed for legal, tax, or audit purposes '
                      'may be retained in anonymized form by ${BusinessInfo.legalName}.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const Key('delete-account-password'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_deleting,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your current password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('delete-account-confirm-text'),
                      controller: _confirmController,
                      enabled: !_deleting,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Type DELETE to confirm',
                        hintText: 'DELETE',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('delete-account-submit'),
                        onPressed: _deleting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _deleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Delete my account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _deleting ? null : () => context.go('/settings'),
                      child: const Text('Cancel and go back to Settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
