/// Staff roles that can access the admin area.
const staffRoles = {'admin', 'staff', 'verifier', 'executive'};

bool isStaffRole(String? role) => role != null && staffRoles.contains(role);

bool isAdminRole(String? role) => role == 'admin';

bool canViewAdminAnalytics(String? role) => role == 'admin';

bool canReviewVerifications(String? role) =>
    role == 'admin' || role == 'verifier' || role == 'staff';

bool canManageMembers(String? role) => role == 'admin';

String homeRouteForRole(String? role) {
  if (canViewAdminAnalytics(role)) return '/admin';
  if (canReviewVerifications(role)) return '/admin/verifications';
  return '/dashboard';
}
