import 'auth_session.dart';
import 'jwt_role.dart';

/// Staff roles that can access the admin area.
const staffRoles = {'admin', 'staff', 'verifier', 'executive'};

const officerRoles = {
  'president',
  'vice_president',
  'secretary',
  'treasurer',
};

const announcementPublisherRoles = {
  'admin',
  'executive',
  ...officerRoles,
};

/// Prefer `/auth/me` role; fall back to JWT claim when user profile is not loaded yet.
String? resolveUserRole([String? role]) {
  final fromArg = role?.trim();
  if (fromArg != null && fromArg.isNotEmpty) return fromArg;

  final rawUserRole = AuthSession.instance.currentUser?.role;
  final fromUser = rawUserRole?.trim();
  if (fromUser != null && fromUser.isNotEmpty) return fromUser;

  return roleFromAccessToken();
}

bool isStaffRole(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && staffRoles.contains(resolved);
}

bool isAdminRole(String? role) => resolveUserRole(role) == 'admin';

bool canViewAdminAnalytics(String? role) => resolveUserRole(role) == 'admin';

bool canReviewVerifications(String? role) {
  final resolved = resolveUserRole(role);
  return resolved == 'admin' || resolved == 'verifier' || resolved == 'staff';
}

bool canManageMembers(String? role) => resolveUserRole(role) == 'admin';

bool canManageGallery(String? role) => resolveUserRole(role) == 'admin';

bool canManageEvents(String? role) => resolveUserRole(role) == 'admin';

bool canManageDrugs(String? role) => resolveUserRole(role) == 'admin';

bool isAnnouncementPublisher(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && announcementPublisherRoles.contains(resolved);
}

/// President, Vice President, Secretary, and Treasurer can post to General Group.
bool canPostToGeneralGroup(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && officerRoles.contains(resolved);
}

String generalGroupRoleLabel(String? role) {
  final resolved = resolveUserRole(role);
  if (resolved == null) return 'Member';
  switch (resolved) {
    case 'president':
      return 'President';
    case 'vice_president':
      return 'Vice President';
    case 'secretary':
      return 'Secretary';
    case 'treasurer':
      return 'Treasurer';
    case 'admin':
      return 'Admin';
    default:
      return 'Member';
  }
}

bool canEditAnnouncement(String? authorId, String? currentUserId, String? role) {
  if (isAdminRole(role)) return true;
  if (!isAnnouncementPublisher(role)) return false;
  return authorId == currentUserId;
}

/// Post-login / splash destination for every role (including admin).
String homeRouteForRole(String? role) => '/dashboard';

/// Staff console entry from Settings (admin analytics or verification queue).
String staffConsoleRouteForRole(String? role) {
  if (canViewAdminAnalytics(role)) return '/admin';
  if (canReviewVerifications(role)) return '/admin/verifications';
  return '/dashboard';
}

String? get currentUserRole => resolveUserRole();

bool get isAnnouncementPublisherUser =>
    isAnnouncementPublisher(currentUserRole);

bool get isAdminUser => isAdminRole(currentUserRole);

bool canEditAnnouncementForUser(String authorId) => canEditAnnouncement(
      authorId,
      AuthSession.instance.currentUser?.id,
      currentUserRole,
    );
