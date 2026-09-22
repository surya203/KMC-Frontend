import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kmc_alumni_connect/core/widgets/public_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'ENV=test\nAPI_BASE_URL=https://api.kmcalumni.net\nAPI_PREFIX=/api/v1\n',
    );
  });

  testWidgets('mobile public pills navigate like the website', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/about',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const PublicLayout(child: Text('home-page')),
        ),
        GoRoute(
          path: '/about',
          builder: (_, _) => const PublicLayout(child: Text('about-page')),
        ),
        GoRoute(
          path: '/membership',
          builder: (_, _) => const PublicLayout(child: Text('membership-page')),
        ),
        GoRoute(
          path: '/events',
          builder: (_, _) => const PublicLayout(child: Text('events-page')),
        ),
        GoRoute(
          path: '/gallery',
          builder: (_, _) => const PublicLayout(child: Text('gallery-page')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('about-page'), findsOneWidget);
    expect(find.text('About'), findsWidgets);

    await tester.tap(find.text('Events').first);
    await tester.pumpAndSettle();

    expect(find.text('events-page'), findsOneWidget);
    expect(find.text('about-page'), findsNothing);

    await tester.tap(find.text('Home').first);
    await tester.pumpAndSettle();

    expect(find.text('home-page'), findsOneWidget);
  });

  testWidgets('drawer items navigate after closing the menu', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const PublicLayout(child: Text('home-page')),
        ),
        GoRoute(
          path: '/about',
          builder: (_, _) => const PublicLayout(child: Text('about-page')),
        ),
        GoRoute(
          path: '/membership',
          builder: (_, _) => const PublicLayout(child: Text('membership-page')),
        ),
        GoRoute(
          path: '/events',
          builder: (_, _) => const PublicLayout(child: Text('events-page')),
        ),
        GoRoute(
          path: '/gallery',
          builder: (_, _) => const PublicLayout(child: Text('gallery-page')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Gallery'), findsWidgets);

    await tester.tap(find.widgetWithText(ListTile, 'Gallery'));
    await tester.pumpAndSettle();

    expect(find.text('gallery-page'), findsOneWidget);
  });
}
