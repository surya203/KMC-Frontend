import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Mobile system Back currently exits the app because most screens use
/// [GoRouter.go] (no Navigator stack). Web is fine via browser history.
///
/// This handler intercepts Back on iOS/Android and:
/// 1) pops dialogs / pushed routes when possible
/// 2) otherwise goes to a sensible parent screen
/// 3) only exits on true root screens (home / dashboard / splash)
bool handleAppSystemBack(BuildContext context) {
  if (kIsWeb) return false;

  final rootNavigator = Navigator.of(context, rootNavigator: true);
  if (rootNavigator.canPop()) {
    rootNavigator.pop();
    return true;
  }

  if (appRouter.canPop()) {
    appRouter.pop();
    return true;
  }

  final path = appRouter.state.uri.path;
  final parent = parentRouteForPath(path);
  if (parent != null && parent != path) {
    appRouter.go(parent);
    return true;
  }

  // Root screens: allow leaving the app.
  SystemNavigator.pop();
  return true;
}

/// Parent screen for in-app Back when there is no Navigator history.
String? parentRouteForPath(String path) {
  if (path == '/' || path == '/splash' || path == '/dashboard') {
    return null;
  }

  if (path.startsWith('/settings/')) return '/settings';
  if (path.startsWith('/my-events/') && path != '/my-events') {
    return '/my-events';
  }
  if (path.startsWith('/my-gallery/')) return '/my-gallery';
  if (path.startsWith('/member/profiles/')) return '/member/alumni-roll';
  if (path.startsWith('/profiles/')) return '/member/alumni-roll';
  if (path.startsWith('/admin/events/') && path != '/admin/events') {
    return '/admin/events';
  }
  if (path.startsWith('/admin/gallery/')) return '/admin/gallery';
  if (path.startsWith('/dashboard/drugs/')) return '/dashboard';
  if (path.startsWith('/events/') && path != '/events') return '/events';
  if (path.startsWith('/gallery/') && path != '/gallery') return '/gallery';
  if (path.startsWith('/drugs/')) return '/';

  const memberTabs = <String>{
    '/my-profile',
    '/my-membership',
    '/my-payments',
    '/my-events',
    '/my-gallery',
    '/announcements',
    '/connect',
    '/member/alumni-roll',
    '/settings',
  };
  if (memberTabs.contains(path)) return '/dashboard';

  if (path.startsWith('/admin/') && path != '/admin') return '/admin';
  if (path == '/admin') return '/dashboard';

  const publicPages = <String>{
    '/about',
    '/auth',
    '/membership',
    '/terms',
    '/privacy',
    '/delete-account',
    '/refund-policy',
    '/shipping-policy',
    '/contact',
    '/pricing',
    '/events',
    '/gallery',
  };
  if (publicPages.contains(path)) return '/';

  return '/';
}

/// Wraps the app so Android/iOS system Back navigates in-app first.
class AppSystemBackScope extends StatelessWidget {
  const AppSystemBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        handleAppSystemBack(context);
      },
      child: child,
    );
  }
}
