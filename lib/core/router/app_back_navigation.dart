import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'app_route_history.dart';
import 'app_router.dart';

/// Closes an open drawer first, then changes route via [appRouter].
///
/// Using [appRouter.go] after [Navigator.pop] avoids the common mobile bug
/// where [BuildContext] from a closing drawer is unmounted and [context.go]
/// never runs. Website desktop nav does not use a drawer, so this only
/// showed up in the APK.
GoRouter routerFor(BuildContext context) {
  try {
    return GoRouter.of(context);
  } catch (_) {
    return appRouter;
  }
}

void navigateAppPath(BuildContext context, String path) {
  // Capture the router before the drawer pops — that context can unmount.
  final router = routerFor(context);
  final current = router.state.uri.path;
  final scaffold = Scaffold.maybeOf(context);
  final drawerOpen = scaffold?.isDrawerOpen ?? false;

  if (drawerOpen) {
    Navigator.of(context).pop();
  }

  if (path == current) return;

  void go() => router.go(path);

  if (drawerOpen) {
    WidgetsBinding.instance.addPostFrameCallback((_) => go());
    return;
  }
  go();
}

/// Canonical in-app Back: one step only.
///
/// 1) Pop dialogs / local routes when the Navigator can pop
/// 2) Otherwise go to the immediately previous recorded screen
/// 3) Otherwise go to the logical parent (not a multi-step jump)
/// 4) Otherwise go home `/`
void navigatePublicBack(BuildContext context) {
  navigateAppBack(context);
}

/// Same as [navigatePublicBack] — use for every Back control in the app.
void navigateAppBack(BuildContext context) {
  if (_handlingAppBack) return;
  _handlingAppBack = true;
  try {
    final router = routerFor(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    final previous = AppRouteHistory.instance.takeBack();
    if (previous != null) {
      router.go(previous);
      return;
    }

    final path = router.state.uri.path;
    final parent = parentRouteForPath(path);
    if (parent != null && parent != path) {
      router.go(parent);
      return;
    }

    if (path != '/') {
      router.go('/');
    }
  } finally {
    _handlingAppBack = false;
  }
}

/// Phone navigation-bar Back. Screens use [GoRouter.go], so Android has no
/// stack and would close the app. Web keeps the browser history.
bool _handlingSystemBack = false;
bool _handlingAppBack = false;

Future<bool> handleAppSystemBack() async {
  if (kIsWeb) return false;
  if (_handlingSystemBack) return true;
  _handlingSystemBack = true;
  try {
    if (appRouter.canPop()) {
      appRouter.pop();
      return true;
    }

    final previous = AppRouteHistory.instance.takeBack();
    if (previous != null) {
      appRouter.go(previous);
      return true;
    }

    final path = appRouter.state.uri.path;
    final parent = parentRouteForPath(path);
    if (parent != null && parent != path) {
      appRouter.go(parent);
      return true;
    }

    SystemNavigator.pop();
    return true;
  } finally {
    _handlingSystemBack = false;
  }
}

/// Parent screen for in-app Back when there is no Navigator or history.
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
class AppSystemBackScope extends StatefulWidget {
  const AppSystemBackScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppSystemBackScope> createState() => _AppSystemBackScopeState();
}

class _AppSystemBackScopeState extends State<AppSystemBackScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    AppRouteHistory.instance.attach(appRouter);
    // Register before the router so the phone Back button is handled here
    // and Android does not finish the activity.
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() {
    return handleAppSystemBack();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
