import '../network/membership_api_service.dart';

/// Membership tenure helpers for dashboard and profile displays.
class MembershipTenure {
  MembershipTenure._();

  /// Best available membership start date from API data.
  static DateTime? startDate(MemberMembership? membership) {
    if (membership == null) return null;

    final startedAt = membership.startedAt;
    if (startedAt != null) return startedAt.toLocal();

    final registration = _parseIso(membership.registrationDate);
    if (registration != null) return registration;

    return _parseIso(membership.paymentDate);
  }

  /// Full calendar years since membership started.
  static int? yearsSince(DateTime? start) {
    if (start == null) return null;

    final now = DateTime.now();
    var years = now.year - start.year;
    final beforeAnniversary = now.month < start.month ||
        (now.month == start.month && now.day < start.day);
    if (beforeAnniversary) years--;

    return years.clamp(0, 99);
  }

  /// Label for stat cards, e.g. `3 yrs`, `1 yr`, `< 1 yr`, or `—`.
  static String displayLabel({
    MemberMembership? membership,
    int? batchYearFallback,
  }) {
    final fromMembership = yearsSince(startDate(membership));
    if (fromMembership != null) {
      return _formatYears(fromMembership);
    }

    if (batchYearFallback != null) {
      final fromBatch =
          (DateTime.now().year - batchYearFallback).clamp(0, 99);
      if (fromBatch > 0) return _formatYears(fromBatch);
    }

    return '—';
  }

  static String _formatYears(int years) {
    if (years <= 0) return '< 1 yr';
    if (years == 1) return '1 yr';
    return '$years yrs';
  }

  static DateTime? _parseIso(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
