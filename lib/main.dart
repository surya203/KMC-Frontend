import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/auth/auth_session.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  configureRouter();
  await authSession.bootstrap();
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
      routerConfig: appRouter,
    );
  }
}
