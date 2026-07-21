import 'auth_session.dart';
import 'jwt_role.dart';
import '../network/auth_service.dart';

/// Roles that can access the admin area (legacy `executive` kept for old accounts).
const staffRoles = {'admin', 'staff', 'executive'};

/// Executive Committee designation (assignable; labeled "Executive").
const ecMemberRole = 'ec_member';

/// Alumni account roles (member dashboard; not officers/admin).
const alumniRoles = {ecMemberRole, 'member', 'staff'};

/// Roles assignable in Admin → Members (verifier and legacy `executive` removed).
const assignableUserRoles = [
  'member',
  ecMemberRole,
  'staff',
  'president',
  'vice_president',
  'secretary',
  'joint_secretary',
  'finance_secretary',
  'treasurer',
  'editor',
  'admin',
];

const _userRoleLabels = <String, String>{
  'member': 'Member',
  ecMemberRole: 'Executive Member',
  'staff': 'NRI Alumni',
  'executive': 'Executive Member', // legacy role=executive rows
  'president': 'President',
  'vice_president': 'Vice President',
  'secretary': 'General Secretary',
  'joint_secretary': 'Joint Secretary',
  'finance_secretary': 'Finance Secretary',
  'treasurer': 'Treasurer',
  'editor': 'Editor',
  'admin': 'Admin',
};

const officerRoles = {
  'president',
  'vice_president',
  'secretary',
  'joint_secretary',
  'finance_secretary',
  'treasurer',
  'editor',
};

/// Officers + Executive (`ec_member`; legacy `executive`) + admin — EC group chat.
const executiveCommitteeRoles = {
  ...officerRoles,
  ecMemberRole,
  'executive',
  'admin',
};

const announcementPublisherRoles = {
  'admin',
  ecMemberRole,
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

bool isEcMemberRole(String? role) => resolveUserRole(role) == ecMemberRole;

/// Prefer the `is_ec_member` flag from `/auth/me` (works for EC presidents too).
bool isEcMemberUser([AuthUser? user]) {
  final u = user ?? AuthSession.instance.currentUser;
  if (u == null) return false;
  return u.isEcMember || u.role == ecMemberRole || u.role == 'executive';
}

bool isAlumniRole(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && alumniRoles.contains(resolved);
}

String userRoleLabel(String? role) {
  final resolved = resolveUserRole(role);
  if (resolved == null) return 'Alumni Member';
  return _userRoleLabels[resolved] ??
      resolved.replaceAll('_', ' ').split(' ').map((part) {
        if (part.isEmpty) return part;
        return '${part[0].toUpperCase()}${part.substring(1)}';
      }).join(' ');
}

bool canViewAdminAnalytics(String? role) => resolveUserRole(role) == 'admin';

bool canReviewVerifications(String? role) {
  final resolved = resolveUserRole(role);
  // Verifier role removed — admin and NRI Alumni (staff) only.
  return resolved == 'admin' || resolved == 'staff';
}

bool canManageMembers(String? role) => resolveUserRole(role) == 'admin';

bool canManageGallery(String? role) => resolveUserRole(role) == 'admin';

bool canManageEvents(String? role) => resolveUserRole(role) == 'admin';

bool canManageDrugs(String? role) => resolveUserRole(role) == 'admin';

bool isAnnouncementPublisher(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && announcementPublisherRoles.contains(resolved);
}

/// President, VP, Secretary, Treasurer, or Admin can start an Executive Committee DM.
bool canStartExecutiveDm(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null &&
      (officerRoles.contains(resolved) || resolved == 'admin');
}

/// EC group chat: officers, Executive (`ec_member`), legacy `executive`, and admin.
bool canViewExecutiveCommittee(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && executiveCommitteeRoles.contains(resolved);
}

bool canPostToExecutiveCommittee(String? role) =>
    canViewExecutiveCommittee(role);

String executiveCommitteeRoleLabel(String? role) {
  final resolved = resolveUserRole(role);
  if (resolved == null) return 'Member';
  switch (resolved) {
    case 'president':
      return 'President';
    case 'vice_president':
      return 'Vice President';
    case 'secretary':
      return 'General Secretary';
    case 'joint_secretary':
      return 'Joint Secretary';
    case 'finance_secretary':
      return 'Finance Secretary';
    case 'treasurer':
      return 'Treasurer';
    case 'editor':
      return 'Editor';
    case 'staff':
      return 'NRI Alumni';
    case 'ec_member':
    case 'executive':
      return 'Executive Member';
    case 'admin':
      return 'Admin';
    default:
      return userRoleLabel(resolved);
  }
}

/// President, Vice President, Secretary, and Treasurer can post to General Group.
bool canPostToGeneralGroup(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && officerRoles.contains(resolved);
}

const financeCouncilViewRoles = {
  'president',
  'vice_president',
  'secretary',
  'finance_secretary',
  'treasurer',
  'admin',
};

const financeCouncilPostRoles = {
  'president',
  'vice_president',
  'secretary',
  'finance_secretary',
  'treasurer',
};

/// Finance Council: President, VP, Secretary, Treasurer chat; Admin view-only.
bool canViewFinanceCouncil(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && financeCouncilViewRoles.contains(resolved);
}

bool canPostToFinanceCouncil(String? role) {
  final resolved = resolveUserRole(role);
  return resolved != null && financeCouncilPostRoles.contains(resolved);
}

String financeCouncilRoleLabel(String? role) {
  final resolved = resolveUserRole(role);
  if (resolved == null) return 'Member';
  switch (resolved) {
    case 'president':
      return 'President';
    case 'vice_president':
      return 'Vice President';
    case 'secretary':
      return 'General Secretary';
    case 'finance_secretary':
      return 'Finance Secretary';
    case 'treasurer':
      return 'Treasurer';
    case 'admin':
      return 'Admin';
    default:
      return userRoleLabel(resolved);
  }
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
      return 'General Secretary';
    case 'finance_secretary':
      return 'Finance Secretary';
    case 'treasurer':
      return 'Treasurer';
    case 'admin':
      return 'Admin';
    default:
      return userRoleLabel(resolved);
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

bool get canStartExecutiveDmUser => canStartExecutiveDm(currentUserRole);

bool get isAnnouncementPublisherUser =>
    isAnnouncementPublisher(currentUserRole);

bool get isAdminUser => isAdminRole(currentUserRole);

bool canEditAnnouncementForUser(String authorId) => canEditAnnouncement(
      authorId,
      AuthSession.instance.currentUser?.id,
      currentUserRole,
    );
