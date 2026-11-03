import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kmc_alumni_connect/features/dashboard/presentation/delete_account_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'ENV=test\nAPI_BASE_URL=https://api.kmcalumni.net\nAPI_PREFIX=/api/v1\n',
    );
  });

  testWidgets('delete account screen shows confirmation controls', (tester) async {
    final router = GoRouter(
      initialLocation: '/settings/delete-account',
      routes: [
        GoRoute(
          path: '/settings/delete-account',
          builder: (context, state) => const Scaffold(
            body: DeleteAccountScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: Text('Auth')),
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Delete my account'), findsOneWidget);
    expect(find.byKey(const Key('delete-account-password')), findsOneWidget);
    expect(find.byKey(const Key('delete-account-confirm-text')), findsOneWidget);
    expect(find.textContaining('Permanently delete'), findsWidgets);
  });
}
