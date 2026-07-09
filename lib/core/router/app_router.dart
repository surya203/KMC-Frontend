import 'package:go_router/go_router.dart';

import '../auth/auth_session.dart';
import '../auth/role_helpers.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/admin/presentation/admin_screens.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/dashboard/presentation/dashboard_connect_screen.dart';
import '../../features/dashboard/presentation/dashboard_member_screens.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/my_membership_screen.dart';
import '../../features/dashboard/presentation/my_payments_screen.dart';
import '../../features/dashboard/presentation/settings_screen.dart';
import '../../features/directory/presentation/directory_screen.dart';
import '../../features/directory/presentation/profile_detail_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/events/presentation/member_events_screens.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/membership/presentation/membership_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

late final GoRouter appRouter;

String? _legacyMemberRedirect(String path) {
  switch (path) {
    case '/my-profile':
      return '/dashboard/profile';
    case '/my-events':
      return '/dashboard/events';
    case '/my-gallery':
      return '/gallery';
    case '/announcements':
      return '/dashboard/announcements';
    default:
      return null;
  }
}

void configureRouter() {
  appRouter = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authSession,
    redirect: (context, state) {
      if (!authSession.bootstrapped) return null;

      final path = state.uri.path;
      final legacyRedirect = _legacyMemberRedirect(path);
      if (legacyRedirect != null) return legacyRedirect;

      final isMemberArea =
          path == '/dashboard' || path.startsWith('/dashboard/');
      final isGalleryArea = path == '/gallery' || path.startsWith('/gallery/');
      final isAdminArea = path == '/admin' || path.startsWith('/admin/');
      final isProtectedMemberPage = path == '/my-membership' ||
          path == '/my-payments' ||
          path == '/connect' ||
          path == '/settings';

      if ((isMemberArea || isProtectedMemberPage) &&
          !authSession.isAuthenticated) {
        return '/auth';
      }

      if (isGalleryArea && !authSession.isAuthenticated) {
        return '/auth';
      }

      if (isAdminArea) {
        if (!authSession.isAuthenticated) return '/auth';
        if (!canAccessAdmin) return '/dashboard';
        if (path == '/admin' && !canViewAnalytics) {
          if (isVerifierUser) return '/admin/verifications';
          if (isStaffUser) return '/admin/events';
        }
      }

      if (authSession.isAuthenticated && path == '/auth') {
        return '/dashboard';
      }

      if (authSession.isAuthenticated && path == '/splash') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsScreen(),
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) => EventDetailScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryScreen(),
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) => GalleryAlbumScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profiles',
        builder: (context, state) => const DirectoryScreen(),
        routes: [
          GoRoute(
            path: ':profileId',
            builder: (context, state) => ProfileDetailScreen(
              profileId: state.pathParameters['profileId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/directory',
        redirect: (context, state) => '/profiles',
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/membership',
        builder: (context, state) => const MembershipScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const DashboardProfileScreen(),
          ),
          GoRoute(
            path: 'announcements',
            builder: (context, state) => const DashboardAnnouncementsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => DashboardAnnouncementDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'events',
            builder: (context, state) => const DashboardMyEventsScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (context, state) => MemberEventDetailScreen(
                  slug: state.pathParameters['slug']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const DashboardNotificationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/my-membership',
        builder: (context, state) => const MyMembershipScreen(),
      ),
      GoRoute(
        path: '/my-payments',
        builder: (context, state) => const MyPaymentsScreen(),
      ),
      GoRoute(
        path: '/connect',
        builder: (context, state) => const DashboardConnectScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/announcements',
        redirect: (context, state) => '/dashboard/announcements',
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'verifications',
            builder: (context, state) => const AdminVerificationsScreen(),
          ),
          GoRoute(
            path: 'members',
            builder: (context, state) => const AdminMembersScreen(),
          ),
          GoRoute(
            path: 'events',
            builder: (context, state) => const AdminEventsScreen(),
          ),
        ],
      ),
    ],
  );
}
