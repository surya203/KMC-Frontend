import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/safe_asset_image.dart';

class DashboardNavItem {
  const DashboardNavItem(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}

const dashboardNavItems = <DashboardNavItem>[
  DashboardNavItem('Dashboard', Icons.grid_view_rounded, '/dashboard'),
  DashboardNavItem('My Profile', Icons.person_outline_rounded, '/my-profile'),
  DashboardNavItem('Membership', Icons.workspace_premium_outlined, '/my-membership'),
  DashboardNavItem('Events', Icons.event_outlined, '/my-events'),
  DashboardNavItem('Gallery', Icons.photo_library_outlined, '/my-gallery'),
  DashboardNavItem('Announcements', Icons.campaign_outlined, '/announcements'),
  DashboardNavItem('Connect', Icons.people_outline_rounded, '/connect'),
  DashboardNavItem('Payments', Icons.payments_outlined, '/my-payments'),
  DashboardNavItem('Settings', Icons.settings_outlined, '/settings'),
];

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.currentPath,
    required this.title,
    required this.child,
    required this.onSignOut,
    required this.searchController,
    this.profileName,
    this.onSearchTap,
  });

  final String currentPath;
  final String title;
  final Widget child;
  final VoidCallback onSignOut;
  final TextEditingController searchController;
  final String? profileName;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F4),
      drawer: isDesktop
          ? null
          : Drawer(
              child: DashboardSidebar(
                currentPath: currentPath,
                onSignOut: onSignOut,
              ),
            ),
      body: Builder(
        builder: (scaffoldContext) => Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 228,
                child: DashboardSidebar(
                  currentPath: currentPath,
                  onSignOut: onSignOut,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  DashboardTopBar(
                    title: title,
                    searchController: searchController,
                    profileName: profileName,
                    onMenuTap: isDesktop
                        ? null
                        : () => Scaffold.of(scaffoldContext).openDrawer(),
                    onSearchTap: onSearchTap ?? () => context.go('/connect'),
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

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.currentPath,
    required this.onSignOut,
  });

  final String currentPath;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(
                children: [
                  const SafeAssetImage(
                    assetPath: AppAssets.logo,
                    width: 38,
                    height: 38,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KMC',
                        style: GoogleFonts.fraunces(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'ALUMNI CONNECT',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0x33FFFFFF), height: 1),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final item in dashboardNavItems)
                    _SidebarNavTile(
                      item: item,
                      active: item.path == currentPath,
                      currentPath: currentPath,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x66FFFFFF)),
                  minimumSize: const Size.fromHeight(42),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.active,
    required this.currentPath,
  });

  final DashboardNavItem item;
  final bool active;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.secondary : Colors.transparent;
    final fg = active ? AppColors.primary : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.white.withValues(alpha: 0.08),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          onTap: () {
            if (item.path == currentPath) return;
            context.go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: fg),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    color: fg,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearchTap,
    this.profileName,
    this.onMenuTap,
  });

  final String title;
  final TextEditingController searchController;
  final VoidCallback onSearchTap;
  final String? profileName;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final initial = (profileName?.isNotEmpty == true)
        ? profileName!.trim()[0].toUpperCase()
        : 'K';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (onMenuTap != null)
            IconButton(onPressed: onMenuTap, icon: const Icon(Icons.menu)),
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
              fontSize: 30,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 280,
            child: TextField(
              controller: searchController,
              onSubmitted: (_) => onSearchTap(),
              decoration: InputDecoration(
                hintText: 'Search alumni, events...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => context.go('/announcements'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(initial, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
