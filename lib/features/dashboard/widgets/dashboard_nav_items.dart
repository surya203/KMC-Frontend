import 'package:flutter/material.dart';

import '../../core/auth/role_utils.dart';

class DashboardNavItem {
  const DashboardNavItem(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}

const dashboardNavItems = <DashboardNavItem>[
  DashboardNavItem('Dashboard', Icons.grid_view_rounded, '/dashboard'),
  DashboardNavItem('My Profile', Icons.person_outline_rounded, '/my-profile'),
  DashboardNavItem('Alumni Member', Icons.badge_outlined, '/member/alumni-roll'),
  DashboardNavItem('Executive Committee', Icons.people_outline_rounded, '/connect'),
  DashboardNavItem('Events', Icons.event_outlined, '/my-events'),
  DashboardNavItem('Announcements', Icons.campaign_outlined, '/announcements'),
  DashboardNavItem('Gallery', Icons.photo_library_outlined, '/my-gallery'),
  DashboardNavItem('Membership', Icons.workspace_premium_outlined, '/my-membership'),
  DashboardNavItem('Payments', Icons.payments_outlined, '/my-payments'),
  DashboardNavItem('Settings', Icons.settings_outlined, '/settings'),
];

String dashboardNavPath(DashboardNavItem item, String? role) {
  if (item.path == '/my-events' && canManageEvents(role)) {
    return '/admin/events';
  }
  return item.path;
}

String dashboardTitleForPath(String path, {bool compact = false}) {
  if (path.startsWith('/dashboard/drugs')) {
    return 'Dashboard';
  }
  if (path == '/connect' || path.startsWith('/connect/')) {
    return 'Executive Committee';
  }
  if (path == '/member/alumni-roll') {
    return 'Alumni Member';
  }
  if (path.startsWith('/member/profiles/')) {
    return 'Alumni Profile';
  }
  for (final item in dashboardNavItems) {
    if (item.path == path || path.startsWith('${item.path}/')) {
      return item.label;
    }
  }
  return 'Dashboard';
}

bool dashboardNavItemIsActive(
  DashboardNavItem item,
  String currentPath, {
  String? role,
}) {
  final itemPath = dashboardNavPath(item, role);
  if (itemPath == currentPath) return true;
  if (itemPath == '/admin/events' &&
      currentPath.startsWith('/admin/events/')) {
    return true;
  }
  return currentPath.startsWith('$itemPath/');
}
