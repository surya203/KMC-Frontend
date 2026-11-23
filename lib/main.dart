import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/auth/auth_session.dart';
import 'core/auth/profile_session.dart';
import 'core/router/app_back_navigation.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/kmc_scroll_behavior.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await dotenv.load(fileName: '.env', isOptional: true);
  // Tokens come from local storage. Profile, /auth/me, and Google Fonts
  // stay off this path so a slow network cannot hold a blank page.
  await AuthSession.instance.initialize();
  runApp(const KMCApp());
  unawaited(_warmAfterFirstFrame());
}

Future<void> _warmAfterFirstFrame() async {
  if (AuthSession.instance.isAuthenticated) {
    unawaited(ProfileSession.instance.ensureLoaded(force: true));
  }
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.fraunces(fontWeight: FontWeight.w600),
      GoogleFonts.fraunces(
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ),
      GoogleFonts.inter(),
      GoogleFonts.inter(fontWeight: FontWeight.w600),
      GoogleFonts.inter(fontWeight: FontWeight.w700),
    ]).timeout(const Duration(seconds: 8));
  } catch (_) {
    // Fall back to platform fonts; the UI is already on screen.
  }
}

class KMCApp extends StatelessWidget {
  const KMCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'KMC Alumni Connect',
      theme: AppTheme.light,
      scrollBehavior: const KmcScrollBehavior(),
      routerConfig: appRouter,
      // Mobile system Back was exiting the app because routes use go() with no
      // stack. Web keeps browser history, so this wrapper is mobile-only.
      builder: (context, child) {
        return AppSystemBackScope(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
