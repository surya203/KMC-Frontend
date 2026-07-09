import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_session.dart';
import '../auth/role_helpers.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import 'safe_asset_image.dart';

class MemberLayout extends StatelessWidget {
  const MemberLayout({
    super.key,
    required this.child,
    this.title,
    this.currentPath = '/dashboard',
  });

  final Widget child;
  final String? title;
  final String currentPath;

  static const _links = [
    ('Overview', '/dashboard'),
    ('Profile', '/dashboard/profile'),
    ('Membership', '/dashboard/membership'),
    ('Announcements', '/dashboard/announcements'),
    ('My events', '/dashboard/events'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = authSession.user;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            SafeAssetImage(
              assetPath: AppAssets.logo,
              height: 36,
              width: 36,
            ),
            const SizedBox(width: 10),
            Text(
              title ?? 'MY KMC',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
          ],
        ),
        actions: [
          if (canAccessAdmin)
            TextButton(
              key: const ValueKey('member-admin-link'),
              onPressed: () => context.go('/admin'),
              child: Text(
                'Admin',
                style: GoogleFonts.inter(color: AppColors.primary),
              ),
            ),
          if (width >= 700 && user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  user.profile?.fullName ?? user.email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.bodyText,
                  ),
                ),
              ),
            ),
          TextButton(
            key: const ValueKey('dashboard-sign-out'),
            onPressed: () async {
              await authSession.signOut();
              if (context.mounted) context.go('/auth');
            },
            child: Text(
              'Sign out',
              style: GoogleFonts.inter(color: AppColors.bodyText),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final link in _links)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ChoiceChip(
                      key: ValueKey('member-nav-${link.$1.toLowerCase().replaceAll(' ', '-')}'),
                      label: Text(link.$1),
                      selected: currentPath == link.$2,
                      onSelected: (_) => context.go(link.$2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: child,
    );
  }
}
