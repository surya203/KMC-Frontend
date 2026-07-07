import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import 'dashboard_shell.dart';

/// Keeps sidebar + top bar mounted while only the inner [child] swaps.
class DashboardShellHost extends StatefulWidget {
  const DashboardShellHost({super.key, required this.child});

  final Widget child;

  @override
  State<DashboardShellHost> createState() => _DashboardShellHostState();
}

class _DashboardShellHostState extends State<DashboardShellHost> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await AuthSession.instance.clearSession();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return DashboardShell(
      currentPath: location,
      title: dashboardTitleForPath(location),
      searchController: _searchController,
      onSignOut: _signOut,
      child: widget.child,
    );
  }
}

String dashboardTitleForPath(String path) {
  for (final item in dashboardNavItems) {
    if (item.path == path) return item.label;
  }
  return 'Dashboard';
}

Page<void> dashboardPage({
  required LocalKey key,
  required Widget child,
}) {
  return NoTransitionPage<void>(key: key, child: child);
}
