import 'package:flutter_test/flutter_test.dart';

import 'package:kmc_alumni_connect/core/router/app_back_navigation.dart';
import 'package:kmc_alumni_connect/core/router/app_route_history.dart';

void main() {
  test('parent routes for nested member screens', () {
    expect(parentRouteForPath('/settings/delete-account'), '/settings');
    expect(parentRouteForPath('/my-events/annual-meet'), '/my-events');
    expect(parentRouteForPath('/member/profiles/abc'), '/member/alumni-roll');
    expect(parentRouteForPath('/settings'), '/dashboard');
    expect(parentRouteForPath('/dashboard'), isNull);
    expect(parentRouteForPath('/'), isNull);
    expect(parentRouteForPath('/auth'), '/');
    expect(parentRouteForPath('/admin/events/1'), '/admin/events');
  });

  test('history records public pages and walks back like the website', () {
    final history = AppRouteHistory(isAuthenticated: () => false);
    history.record('/splash');
    history.record('/');
    history.record('/about');
    history.record('/events');
    history.record('/gallery');

    expect(history.takeBack(), '/events');
    history.completeBackTransition();
    expect(history.takeBack(), '/about');
    history.completeBackTransition();
    expect(history.takeBack(), '/');
    history.completeBackTransition();
    expect(history.takeBack(), isNull);
  });

  test('history skips splash and duplicate locations', () {
    final history = AppRouteHistory(isAuthenticated: () => false);
    history.record('/splash');
    history.record('/');
    history.record('/');
    expect(history.takeBack(), isNull);
  });

  test('history skips auth when already signed in', () {
    final history = AppRouteHistory(isAuthenticated: () => true);
    history.record('/');
    history.record('/auth');
    history.record('/dashboard');

    expect(history.takeBack(), '/');
  });

  test('history skips member routes after sign out', () {
    final history = AppRouteHistory(isAuthenticated: () => false);
    history.record('/');
    history.record('/dashboard');
    history.record('/auth');

    expect(history.takeBack(), '/');
  });
}
