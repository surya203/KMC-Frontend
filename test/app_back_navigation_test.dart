import 'package:flutter_test/flutter_test.dart';

import 'package:kmc_alumni_connect/core/router/app_back_navigation.dart';

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
}
