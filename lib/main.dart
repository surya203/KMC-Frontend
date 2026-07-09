import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/auth/auth_session.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/kmc_scroll_behavior.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await dotenv.load(fileName: '.env', isOptional: true);
  configureRouter();
  await authSession.bootstrap();
  await GoogleFonts.pendingFonts([
    GoogleFonts.fraunces(fontWeight: FontWeight.w600),
    GoogleFonts.fraunces(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
    ),
    GoogleFonts.inter(),
    GoogleFonts.inter(fontWeight: FontWeight.w600),
    GoogleFonts.inter(fontWeight: FontWeight.w700),
  ]);
  runApp(const KMCApp());
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
    );
  }
}
