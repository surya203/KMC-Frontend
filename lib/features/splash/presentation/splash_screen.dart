import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/safe_asset_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      await AuthSession.instance.ensureReady();
      if (!mounted) return;
      if (AuthSession.instance.isAuthenticated) {
        context.go(homeRouteForRole(AuthSession.instance.currentUser?.role));
        return;
      }
      context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SafeAssetImage(
              assetPath: AppAssets.logo,
              width: 120,
            ),
            const SizedBox(height: 24),
            const Text(
              'KMC Alumni Connect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
