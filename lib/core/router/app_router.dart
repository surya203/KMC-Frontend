import 'package:go_router/go_router.dart';

import '../auth/auth_session.dart';
import '../auth/role_utils.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_drugs_screen.dart';
import '../../features/admin/presentation/admin_event_registrations_screen.dart';
import '../../features/admin/presentation/admin_events_screen.dart';
import '../../features/admin/presentation/admin_members_screen.dart';
import '../../features/admin/presentation/admin_verifications_screen.dart';
import '../../features/admin/widgets/admin_shell.dart';
import '../../features/admin/widgets/admin_shell_host.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/drugs/presentation/drug_details_screen.dart';
import '../../features/dashboard/presentation/announcements_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/dashboard_connect_screen.dart';
import '../../features/dashboard/presentation/dashboard_gallery_screen.dart';
import '../../features/dashboard/presentation/dashboard_events_screen.dart';
import '../../features/dashboard/presentation/my_payments_screen.dart';
import '../../features/dashboard/presentation/my_membership_screen.dart';
import '../../features/dashboard/presentation/settings_screen.dart';
import '../../features/dashboard/presentation/my_profile_screen.dart';
import '../../features/dashboard/widgets/dashboard_shell_host.dart';
import '../../features/directory/presentation/directory_screen.dart';
import '../../features/directory/presentation/profile_detail_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/dashboard_event_detail_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/gallery/presentation/dashboard_gallery_album_screen.dart';
import '../../features/gallery/presentation/dashboard_gallery_manage_screen.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/membership/presentation/membership_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../widgets/public_layout.dart';

bool _requiresAuth(String location) {
  return location.startsWith('/dashboard') ||
      location.startsWith('/admin') ||
      location == '/announcements' ||
      location.startsWith('/my-events') ||
      location == '/my-profile' ||
      location == '/my-membership' ||
      location == '/my-payments' ||
      location.startsWith('/my-gallery') ||
      location == '/connect' ||
      location == '/member/alumni-roll' ||
      location.startsWith('/member/profiles/') ||
      location == '/alumni-roll' ||
      location == '/directory' ||
      location.startsWith('/profiles/') ||
      location == '/settings';
}

bool _canAccessAdminPath(String location, String? role) {
  if (!isStaffRole(role)) return false;
  if (location == '/admin' || location.startsWith('/admin/analytics')) {
    return canViewAdminAnalytics(role);
  }
  if (location.startsWith('/admin/verifications')) {
    return canReviewVerifications(role);
  }
  if (location.startsWith('/admin/members')) {
    return canManageMembers(role);
  }
  if (location.startsWith('/admin/events')) {
    return canManageEvents(role);
  }
  if (location.startsWith('/admin/gallery')) {
    return canManageGallery(role);
  }
  if (location.startsWith('/admin/drugs')) {
    return canManageDrugs(role);
  }
  return isStaffRole(role);
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: AuthSession.instance,
  redirect: (context, state) {
    var location = state.matchedLocation;
    final isAuthenticated = AuthSession.instance.isAuthenticated;
    final role = currentUserRole;

    if (location == '/splash') return null;

    // Convert legacy public URLs into member URLs first, then auth-check.
    if (location == '/alumni-roll' || location == '/directory') {
      location = '/member/alumni-roll';
    } else if (location.startsWith('/profiles/')) {
      final id = location.split('/').last;
      if (id.isNotEmpty) location = '/member/profiles/$id';
    }

    if (_requiresAuth(location) && !isAuthenticated) {
      return '/auth';
    }

    if (location.startsWith('/admin')) {
      if (!isAuthenticated) return '/auth';
      if (!_canAccessAdminPath(location, role)) {
        if (canReviewVerifications(role)) return '/admin/verifications';
        return '/dashboard';
      }
    }

    if (location.startsWith('/my-events') && canManageEvents(role)) {
      return '/admin/events';
    }

    if (location == '/admin' &&
        isAuthenticated &&
        !canViewAdminAnalytics(role) &&
        canReviewVerifications(role)) {
      return '/admin/verifications';
    }

    if (location == '/auth' && isAuthenticated) {
      return homeRouteForRole(role);
    }

    // Keep users on member URLs (never stay on legacy public paths).
    final original = state.matchedLocation;
    if (original == '/alumni-roll' || original == '/directory') {
      return '/member/alumni-roll';
    }
    if (original.startsWith('/profiles/')) {
      final id = original.split('/').last;
      if (id.isNotEmpty) return '/member/profiles/$id';
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
    // Legacy public URLs — always go into the authenticated member area.
    GoRoute(
      path: '/alumni-roll',
      redirect: (context, state) => '/member/alumni-roll',
    ),
    GoRoute(
      path: '/directory',
      redirect: (context, state) => '/member/alumni-roll',
    ),
    GoRoute(
      path: '/profiles/:id',
      redirect: (context, state) =>
          '/member/profiles/${state.pathParameters['id']}',
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
      path: '/drugs/:id',
      builder: (context, state) => PublicLayout(
        showFooter: false,
        child: DrugDetailsScreen(
          drugId: state.pathParameters['id']!,
        ),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShellHost(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          pageBuilder: (context, state) => adminPage(
            key: state.pageKey,
            child: const AdminDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/verifications',
          pageBuilder: (context, state) => adminPage(
            key: state.pageKey,
            child: const AdminVerificationsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/members',
          pageBuilder: (context, state) => adminPage(
            key: state.pageKey,
            child: const AdminMembersScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/events',
          pageBuilder: (context, state) => adminPage(
            key: state.pageKey,
            child: const AdminEventsScreen(),
          ),
          routes: [
            GoRoute(
              path: ':eventId',
              pageBuilder: (context, state) {
                final extra = state.extra;
                final title = extra is String && extra.trim().isNotEmpty
                    ? extra.trim()
                    : 'Event';
                return adminPage(
                  key: state.pageKey,
                  child: AdminEventRegistrationsScreen(
                    eventId: state.pathParameters['eventId']!,
                    eventTitle: title,
                  ),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/admin/gallery',
          pageBuilder: (context, state) => adminPage(
            key: state.pageKey,
            child: const DashboardGalleryScreen(
              basePath: '/admin/gallery',
              canManage: true,
            ),
          ),
          routes: [
            GoRoute(
              path: 'album/:slug',
              pageBuilder: (context, state) => adminPage(
                key: state.pageKey,
                child: DashboardGalleryAlbumScreen(
                  slug: state.pathParameters['slug']!,
                  basePath: '/admin/gallery',
                ),
              ),
            ),
            GoRoute(
              path: 'manage/:slug',
              pageBuilder: (context, state) => adminPage(
                key: state.pageKey,
                child: DashboardGalleryManageScreen(
                  slug: state.pathParameters['slug']!,
                  basePath: '/admin/gallery',
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/admin/drugs',
          pageBuilder: (context, state) => adminPage(
            key: state.pageKey,
            child: const AdminDrugsScreen(),
          ),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => DashboardShellHost(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/my-profile',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const MyProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/my-membership',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const MyMembershipScreen(),
          ),
        ),
        GoRoute(
          path: '/my-payments',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const MyPaymentsScreen(),
          ),
        ),
        GoRoute(
          path: '/announcements',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const AnnouncementsScreen(),
          ),
        ),
        GoRoute(
          path: '/my-events',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const DashboardEventsScreen(),
          ),
          routes: [
            GoRoute(
              path: ':slug',
              pageBuilder: (context, state) => dashboardPage(
                key: state.pageKey,
                child: DashboardEventDetailScreen(
                  slug: state.pathParameters['slug']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/my-gallery',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const DashboardGalleryScreen(),
          ),
          routes: [
            GoRoute(
              path: 'album/:slug',
              pageBuilder: (context, state) => dashboardPage(
                key: state.pageKey,
                child: DashboardGalleryAlbumScreen(
                  slug: state.pathParameters['slug']!,
                  allowDriveLinks: true,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/connect',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const DashboardConnectScreen(),
          ),
        ),
        GoRoute(
          path: '/member/alumni-roll',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const DirectoryScreen(embeddedInDashboard: true),
          ),
        ),
        GoRoute(
          path: '/member/profiles/:id',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: ProfileDetailScreen(
              profileId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/dashboard/drugs/:id',
          pageBuilder: (context, state) => dashboardPage(
            key: state.pageKey,
            child: DrugDetailsScreen(
              drugId: state.pathParameters['id']!,
            ),
          ),
        ),
      ],
    ),
  ],
);
