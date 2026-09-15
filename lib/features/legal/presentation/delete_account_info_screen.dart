import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/business_info.dart';
import '../widgets/legal_page_scaffold.dart';

class DeleteAccountInfoScreen extends StatelessWidget {
  const DeleteAccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = AuthSession.instance.isAuthenticated;

    return LegalPageScaffold(
      eyebrow: 'Account',
      title: 'Delete your account',
      subtitle:
          'KMC Alumni Connect lets you permanently delete the account you created '
          'in the app.',
      sections: [
        LegalSection(
          heading: 'How to delete your account in the app',
          body: [
            '1. Open KMC Alumni Connect and sign in.',
            '2. Go to Settings.',
            '3. Tap Delete account.',
            '4. Enter your password, type DELETE, and confirm. Your account and '
                'associated personal data are then permanently deleted.',
          ],
        ),
        LegalSection(
          heading: 'What is removed',
          body: [
            'Deleting your account removes your login, alumni profile, directory '
            'listing, event RSVPs, messages, photos, and verification documents.',
            'Payment records required for legal, tax, or audit purposes may be '
            'retained in anonymized form by ${BusinessInfo.legalName}.',
          ],
        ),
        LegalSection(
          heading: signedIn ? 'Continue in Settings' : 'Sign in to continue',
          body: [
            signedIn
                ? 'You are signed in. Use the button below to open the in-app '
                    'account deletion flow.'
                : 'Sign in first, then open Settings and choose Delete account '
                    'to finish the process in the app.',
          ],
        ),
      ],
      trailing: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: ElevatedButton(
          onPressed: () {
            if (signedIn) {
              context.go('/settings/delete-account');
            } else {
              context.go('/auth');
            }
          },
          child: Text(signedIn ? 'Delete my account' : 'Sign in'),
        ),
      ),
    );
  }
}
