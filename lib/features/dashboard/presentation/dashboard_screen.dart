import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/widgets/member_layout.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/membership_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = authSession.user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return MemberLayout(
      currentPath: '/dashboard',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardSummary(user: user),
                const SizedBox(height: 20),
                if (user.membership != null)
                  MembershipBadge(membership: user.membership!),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickLink(
                      key: const ValueKey('dashboard-profile-link'),
                      label: 'Edit profile',
                      onTap: () => context.go('/dashboard/profile'),
                    ),
                    _QuickLink(
                      key: const ValueKey('dashboard-announcements-link'),
                      label: 'Announcements',
                      onTap: () => context.go('/dashboard/announcements'),
                    ),
                    _QuickLink(
                      key: const ValueKey('dashboard-my-events-link'),
                      label: 'My events',
                      onTap: () => context.go('/dashboard/events'),
                    ),
                    _QuickLink(
                      key: const ValueKey('dashboard-gallery-link'),
                      label: 'Gallery',
                      onTap: () => context.go('/gallery'),
                    ),
                    _QuickLink(
                      key: const ValueKey('dashboard-browse-events'),
                      label: 'Browse events',
                      onTap: () => context.go('/events'),
                    ),
                    _QuickLink(
                      label: 'Alumni directory',
                      onTap: () => context.go('/profiles'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }
}
