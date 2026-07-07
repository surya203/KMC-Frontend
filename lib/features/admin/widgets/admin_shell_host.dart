import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import 'admin_shell.dart';

class AdminShellHost extends StatelessWidget {
  const AdminShellHost({super.key, required this.child});

  final Widget child;

  Future<void> _signOut(BuildContext context) async {
    await AuthSession.instance.clearSession();
    if (!context.mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return AdminShell(
      currentPath: location,
      title: adminTitleForPath(location),
      onSignOut: () => _signOut(context),
      child: child,
    );
  }
}
