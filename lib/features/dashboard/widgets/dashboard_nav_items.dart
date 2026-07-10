import 'package:flutter/material.dart';

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

String dashboardTitleForPath(String path) {
  for (final item in dashboardNavItems) {
    if (item.path == path || path.startsWith('${item.path}/')) {
      return item.label;
    }
  }
  return 'Dashboard';
}

bool dashboardNavItemIsActive(String itemPath, String currentPath) {
  if (itemPath == currentPath) return true;
  return currentPath.startsWith('$itemPath/');
}
