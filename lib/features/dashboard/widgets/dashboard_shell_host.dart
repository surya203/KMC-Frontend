import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/search/app_search_service.dart';
import 'dashboard_nav_items.dart';
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
  final _searchService = AppSearchService();

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
      searchService: _searchService,
      onSignOut: _signOut,
      child: widget.child,
    );
  }
}

Page<void> dashboardPage({
  required LocalKey key,
  required Widget child,
}) {
  return NoTransitionPage<void>(key: key, child: child);
}
