import 'auth_session.dart';

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

bool isStaffRole(String? role) => role != null && staffRoles.contains(role);

bool isAdminRole(String? role) => role == 'admin';

bool canViewAdminAnalytics(String? role) => role == 'admin';

bool canReviewVerifications(String? role) =>
    role == 'admin' || role == 'verifier' || role == 'staff';

bool canManageMembers(String? role) => role == 'admin';

bool isAnnouncementPublisher(String? role) =>
    role != null && announcementPublisherRoles.contains(role);

bool canEditAnnouncement(String? authorId, String? currentUserId, String? role) {
  if (isAdminRole(role)) return true;
  if (!isAnnouncementPublisher(role)) return false;
  return authorId == currentUserId;
}

String homeRouteForRole(String? role) {
  if (canViewAdminAnalytics(role)) return '/admin';
  if (canReviewVerifications(role)) return '/admin/verifications';
  return '/dashboard';
}

String? get currentUserRole => AuthSession.instance.currentUser?.role;

bool get isAnnouncementPublisherUser =>
    isAnnouncementPublisher(currentUserRole);

bool get isAdminUser => isAdminRole(currentUserRole);

bool canEditAnnouncementForUser(String authorId) => canEditAnnouncement(
      authorId,
      AuthSession.instance.currentUser?.id,
      currentUserRole,
    );
