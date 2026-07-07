import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/role_helpers.dart';
import '../constants/app_colors.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({
    super.key,
    required this.child,
    required this.currentPath,
    this.title = 'Admin',
  });

  final Widget child;
  final String currentPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    final links = <(String, String)>[
      if (canViewAnalytics) ('Analytics', '/admin'),
      if (isVerifierUser) ('Verifications', '/admin/verifications'),
      if (canManageMembers) ('Members', '/admin/members'),
      if (isStaffUser) ('Events', '/admin/events'),
      if (isStaffUser) ('Gallery', '/admin/gallery'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Back to MY KMC'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final link in links)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ChoiceChip(
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
