import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_session.dart';

/// In-app location history so Android/iOS Back matches website browser Back.
///
/// Screens use [GoRouter.go], which does not push a Navigator stack. Web still
/// has window history; mobile does not unless we record it here.
class AppRouteHistory {
  AppRouteHistory({bool Function()? isAuthenticated})
      : _isAuthenticated = isAuthenticated ??
            (() => AuthSession.instance.isAuthenticated);

  static final AppRouteHistory instance = AppRouteHistory();

  final bool Function() _isAuthenticated;

  final List<String> _stack = <String>[];
  String? current;
  bool _ignoreNext = false;
  bool _attached = false;

  static const _maxStack = 64;

  void attach(GoRouter router) {
    if (_attached) return;
    _attached = true;
    void sync() {
      final path = _currentPath(router);
      if (path != null) record(path);
    }

    sync();
    router.routerDelegate.addListener(sync);
  }

  String? _currentPath(GoRouter router) {
    final matches = router.routerDelegate.currentConfiguration.matches;
    if (matches.isEmpty) return null;
    return router.state.uri.path;
  }

  void record(String path) {
    if (path.isEmpty || path == '/splash') return;
    if (path == current) return;

    if (_ignoreNext) {
      current = path;
      return;
    }

    if (current != null) {
      _stack.add(current!);
      if (_stack.length > _maxStack) {
        _stack.removeAt(0);
      }
    }
    current = path;
  }

  bool get canGoBack => _nextUsable() != null;

  String? takeBack() {
    while (_stack.isNotEmpty) {
      final prev = _stack.removeLast();
      if (_isUnusable(prev)) continue;
      _ignoreNext = true;
      current = prev;
      _scheduleReleaseIgnore();
      return prev;
    }
    return null;
  }

  void clear() {
    _stack.clear();
    current = null;
    _ignoreNext = false;
  }

  /// Call after a back [GoRouter.go] in tests (no frame scheduled).
  void completeBackTransition() {
    _ignoreNext = false;
  }

  void _scheduleReleaseIgnore() {
    try {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _ignoreNext = false;
      });
    } catch (_) {
      // Unit tests may record history without a Flutter binding.
    }
  }

  String? _nextUsable() {
    for (var i = _stack.length - 1; i >= 0; i--) {
      if (!_isUnusable(_stack[i])) return _stack[i];
    }
    return null;
  }

  bool _isUnusable(String path) {
    if (path == '/splash') return true;
    final authed = _isAuthenticated();
    if (path == '/auth' && authed) return true;
    if (_isMemberPath(path) && !authed) return true;
    return false;
  }

  bool _isMemberPath(String path) {
    return path.startsWith('/dashboard') ||
        path.startsWith('/admin') ||
        path.startsWith('/my-') ||
        path.startsWith('/member/') ||
        path == '/announcements' ||
        path == '/connect' ||
        path == '/settings' ||
        path.startsWith('/settings/');
  }
}
