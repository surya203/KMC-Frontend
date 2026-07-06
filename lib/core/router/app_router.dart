import 'package:go_router/go_router.dart';

import '../../features/about/presentation/about_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/membership/presentation/membership_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
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
    ),
    GoRoute(
      path: '/gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/membership',
      builder: (context, state) => const MembershipScreen(),
    ),
  ],
);
