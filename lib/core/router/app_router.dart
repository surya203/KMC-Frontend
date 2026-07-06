import 'package:go_router/go_router.dart';

import '../auth/auth_session.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/dashboard/presentation/announcements_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/my_events_screen.dart';
import '../../features/directory/presentation/directory_screen.dart';
import '../../features/directory/presentation/profile_detail_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/membership/presentation/membership_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

bool _requiresAuth(String location) {
  return location.startsWith('/dashboard') ||
      location == '/announcements' ||
      location == '/my-events';
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: AuthSession.instance,
  redirect: (context, state) {
    final location = state.matchedLocation;
    final isAuthenticated = AuthSession.instance.isAuthenticated;

    if (location == '/splash') return null;

    if (_requiresAuth(location) && !isAuthenticated) {
      return '/auth';
    }

    if (location == '/auth' && isAuthenticated) {
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
      path: '/directory',
      builder: (context, state) => const DirectoryScreen(),
    ),
    GoRoute(
      path: '/profiles/:id',
      builder: (context, state) => ProfileDetailScreen(
        profileId: state.pathParameters['id']!,
      ),
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
    ),
    GoRoute(
      path: '/announcements',
      builder: (context, state) => const AnnouncementsScreen(),
    ),
    GoRoute(
      path: '/my-events',
      builder: (context, state) => const MyEventsScreen(),
    ),
  ],
);
