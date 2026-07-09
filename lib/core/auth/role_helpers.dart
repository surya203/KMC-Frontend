import 'auth_session.dart';

const staffRoles = {'staff', 'admin', 'executive'};
const executiveRoles = {'executive', 'admin'};
const verifierRoles = {'verifier', 'staff', 'admin'};

bool get isStaffUser =>
    staffRoles.contains(authSession.user?.role) ||
    verifierRoles.contains(authSession.user?.role);

bool get isAdminUser => authSession.user?.role == 'admin';

bool get isVerifierUser =>
    verifierRoles.contains(authSession.user?.role);

bool get isExecutiveUser =>
    executiveRoles.contains(authSession.user?.role);

bool get canAccessAdmin => isStaffUser || isVerifierUser;

bool get canManageMembers => isAdminUser;

bool get canViewAnalytics => isAdminUser;
