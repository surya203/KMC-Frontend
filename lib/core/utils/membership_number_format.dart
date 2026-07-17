/// Formats stored membership numbers (e.g. KMC-000001) for display as
/// `{batch}{firstName}{sequence}` → `2021keerthana001`.
class MembershipNumberFormat {
  MembershipNumberFormat._();

  static const _sequenceDigits = 3;
  static const _nameTitles = {
    'dr',
    'mr',
    'mrs',
    'ms',
    'miss',
    'prof',
    'professor',
    'shri',
    'smt',
    'sri',
  };

  static String? display({
    required String? storedMembershipNumber,
    required int? batchYear,
    required String? fullName,
  }) {
    final batch = batchYear;
    final firstName = _firstName(fullName);
    final sequence = _sequence(storedMembershipNumber);

    if (batch != null && firstName.isNotEmpty && sequence != null) {
      return '$batch$firstName${sequence.toString().padLeft(_sequenceDigits, '0')}';
    }

    return null;
  }

  static String displayOrFallback({
    required String? storedMembershipNumber,
    required int? batchYear,
    required String? fullName,
    String fallback = '—',
  }) {
    return display(
          storedMembershipNumber: storedMembershipNumber,
          batchYear: batchYear,
          fullName: fullName,
        ) ??
        fallback;
  }

  static String _normalizeNameToken(String token) {
    return token.toLowerCase().trim().replaceAll(RegExp(r'\.+$'), '');
  }

  static String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    for (final part in fullName.trim().split(RegExp(r'\s+'))) {
      final normalized = _normalizeNameToken(part);
      if (_nameTitles.contains(normalized)) continue;
      return normalized;
    }
    return '';
  }

  /// Avatar letter from the real first name (skips Dr./Mr./etc.).
  static String avatarInitial(String? fullName) {
    final first = _firstName(fullName);
    if (first.isEmpty) return 'A';
    return first[0].toUpperCase();
  }

  /// Up to [max] initials from name parts after skipping titles.
  static String avatarInitials(String? fullName, {int max = 2}) {
    if (fullName == null || fullName.trim().isEmpty) return 'A';
    final parts = <String>[];
    for (final part in fullName.trim().split(RegExp(r'\s+'))) {
      final normalized = _normalizeNameToken(part);
      if (normalized.isEmpty || _nameTitles.contains(normalized)) continue;
      parts.add(normalized);
      if (parts.length >= max) break;
    }
    if (parts.isEmpty) return 'A';
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  static int? _sequence(String? membershipNumber) {
    final raw = membershipNumber?.trim();
    if (raw == null || raw.isEmpty) return null;

    if (raw.startsWith('KMC-')) {
      return int.tryParse(raw.substring(4));
    }

    final match = RegExp(r'\d+').firstMatch(raw);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}
