import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/drugs_header_card.dart';
import '../../../core/widgets/drugs_sidebar_banner.dart';

class AdminNavItem {
  const AdminNavItem(this.label, this.icon, this.path, this.visible);

  final String label;
  final IconData icon;
  final String path;
  final bool Function(String? role) visible;
}

const adminNavItems = <AdminNavItem>[
  AdminNavItem(
    'Analytics',
    Icons.insights_outlined,
    '/admin',
    canViewAdminAnalytics,
  ),
  AdminNavItem(
    'Verifications',
    Icons.verified_user_outlined,
    '/admin/verifications',
    canReviewVerifications,
  ),
  AdminNavItem(
    'Members',
    Icons.groups_2_outlined,
    '/admin/members',
    canManageMembers,
  ),
  AdminNavItem(
    'Events',
    Icons.event_outlined,
    '/admin/events',
    canManageEvents,
  ),
  AdminNavItem(
    'Gallery',
    Icons.photo_library_outlined,
    '/admin/gallery',
    canManageGallery,
  ),
  AdminNavItem(
    'Drugs',
    Icons.medication_outlined,
    '/admin/drugs',
    canManageDrugs,
  ),
];

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.currentPath,
    required this.title,
    required this.child,
    required this.onSignOut,
  });

  final String currentPath;
  final String title;
  final Widget child;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final role = AuthSession.instance.currentUser?.role;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F4),
      drawer: isDesktop
          ? null
          : Drawer(
              child: _AdminSidebar(
                currentPath: currentPath,
                role: role,
                onSignOut: onSignOut,
              ),
            ),
      body: Builder(
        builder: (scaffoldContext) => Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 228,
                child: _AdminSidebar(
                  currentPath: currentPath,
                  role: role,
                  onSignOut: onSignOut,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    title: title,
                    onMenuTap: isDesktop
                        ? null
                        : () => Scaffold.of(scaffoldContext).openDrawer(),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: const Color(0xFFF7F7F4),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.currentPath,
    required this.role,
    required this.onSignOut,
  });

  final String currentPath;
  final String? role;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final items = adminNavItems.where((item) => item.visible(role)).toList();

    return Container(
      color: const Color(0xFF1A263E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App control',
                    style: GoogleFonts.fraunces(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KMC Alumni Connect',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  children: [
                    for (final item in items)
                      _AdminNavTile(
                        item: item,
                        selected: _isAdminNavSelected(currentPath, item.path),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const DrugsSidebarBanner(),
                  Semantics(
                    button: true,
                    label: 'Open member dashboard',
                    child: TextButton.icon(
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Member view'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Sign out',
                    child: TextButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Sign out'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({required this.item, required this.selected});

  final AdminNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            splashFactory: NoSplash.splashFactory,
            onTap: () {
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              }
              if (selected) return;
              context.go(item.path);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: selected ? AppColors.secondary : Colors.white70,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.label,
                    style: GoogleFonts.inter(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.title, this.onMenuTap});

  final String title;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: ListenableBuilder(
            listenable: AuthSession.instance,
            builder: (context, _) {
              final showDrugs = canManageDrugs(null);

              return Row(
                children: [
                  if (onMenuTap != null)
                    Semantics(
                      button: true,
                      label: 'Open navigation menu',
                      child: IconButton(
                        onPressed: onMenuTap,
                        icon: const Icon(Icons.menu),
                        color: AppColors.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                  ),
                  if (showDrugs) ...[
                    const DrugsHeaderCard(),
                    const SizedBox(width: 10),
                  ],
                  Semantics(
                    button: true,
                    label: 'Notifications',
                    child: IconButton(
                      onPressed: () => context.go('/announcements'),
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

bool _isAdminNavSelected(String currentPath, String itemPath) {
  if (itemPath == '/admin') {
    return currentPath == '/admin' ||
        currentPath.startsWith('/admin/analytics');
  }
  return currentPath == itemPath || currentPath.startsWith('$itemPath/');
}

String adminTitleForPath(String path) {
  if (path.startsWith('/admin/events/') && path != '/admin/events') {
    return 'Registrations';
  }
  for (final item in adminNavItems) {
    if (_isAdminNavSelected(path, item.path)) return item.label;
  }
  return 'Admin';
}

Page<void> adminPage({required LocalKey key, required Widget child}) {
  return NoTransitionPage<void>(key: key, child: child);
}
