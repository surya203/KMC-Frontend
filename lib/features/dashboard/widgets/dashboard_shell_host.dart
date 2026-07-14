import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/profile_session.dart';
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
  final _profileSession = ProfileSession.instance;

  @override
  void initState() {
    super.initState();
    _profileSession.addListener(_onProfileChanged);
    AuthSession.instance.addListener(_onAuthChanged);
    _bootstrapProfile();
  }

  Future<void> _bootstrapProfile() async {
    await AuthSession.instance.ensureReady();
    if (AuthSession.instance.isAuthenticated &&
        AuthSession.instance.currentUser == null) {
      await AuthSession.instance.refreshCurrentUser();
    }
    await _profileSession.ensureLoaded(force: true);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profileSession.removeListener(_onProfileChanged);
    AuthSession.instance.removeListener(_onAuthChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    await ProfileSession.instance.clear();
    await AuthSession.instance.clearSession();
    if (!mounted) return;
    context.go('/auth');
  }

  String? get _profileName {
    final fromProfile = _profileSession.fullName?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return AuthSession.instance.currentUser?.fullName;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final compact = MediaQuery.sizeOf(context).width < 700;

    return DashboardShell(
      currentPath: location,
      title: dashboardTitleForPath(location, compact: compact),
      searchController: _searchController,
      searchService: _searchService,
      onSignOut: _signOut,
      profileName: _profileName,
      profilePhotoUrl: _profileSession.photoUrl,
      profilePhotoBytes: _profileSession.photoBytes,
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
