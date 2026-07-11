/// Formats stored membership numbers (e.g. KMC-000001) for display as
/// `{batch}{firstName}{sequence}` → `2021keerthana001`.
class MembershipNumberFormat {
  MembershipNumberFormat._();

  static const _sequenceDigits = 3;

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

  static String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    return fullName.trim().split(RegExp(r'\s+')).first.toLowerCase();
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
