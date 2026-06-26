import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/presentation/home_screen.dart';

class KMCApp extends StatelessWidget {
  const KMCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "KMC Alumni Connect",
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}