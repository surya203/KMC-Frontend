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

/// President, VP, Secretary, Treasurer, or Admin can start an Executive Committee DM.
bool canStartExecutiveDm(String? role) =>
    role != null && (officerRoles.contains(role) || role == 'admin');

/// President, Vice President, Secretary, and Treasurer can post to General Group.
bool canPostToGeneralGroup(String? role) {
  return role != null && officerRoles.contains(role);
}

const financeCouncilViewRoles = {
  'president',
  'vice_president',
  'treasurer',
  'admin',
};

const financeCouncilPostRoles = {
  'president',
  'vice_president',
  'treasurer',
};

/// Finance Council: President, VP, Treasurer chat; Admin view-only.
bool canViewFinanceCouncil(String? role) =>
    role != null && financeCouncilViewRoles.contains(role);

bool canPostToFinanceCouncil(String? role) =>
    role != null && financeCouncilPostRoles.contains(role);

String financeCouncilRoleLabel(String? role) {
  if (role == null) return 'Member';
  switch (role) {
    case 'president':
      return 'President';
    case 'vice_president':
      return 'Vice President';
    case 'treasurer':
      return 'Treasurer';
    case 'admin':
      return 'Admin';
    default:
      return 'Member';
  }
}

String generalGroupRoleLabel(String? role) {
  if (role == null) return 'Member';
  switch (role) {
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

String homeRouteForRole(String? role) {
  if (canViewAdminAnalytics(role)) return '/admin';
  if (canReviewVerifications(role)) return '/admin/verifications';
  return '/dashboard';
}

String? get currentUserRole => AuthSession.instance.currentUser?.role;

bool get canStartExecutiveDmUser => canStartExecutiveDm(currentUserRole);

bool get isAnnouncementPublisherUser =>
    isAnnouncementPublisher(currentUserRole);

bool get isAdminUser => isAdminRole(currentUserRole);

bool canEditAnnouncementForUser(String authorId) => canEditAnnouncement(
      authorId,
      AuthSession.instance.currentUser?.id,
      currentUserRole,
    );
