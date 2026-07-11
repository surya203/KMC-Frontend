import 'package:flutter/services.dart';

import 'phone_country_codes.dart';

/// Input formatters: digits only, max 10 characters.
final List<TextInputFormatter> mobileNumberInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
];

List<TextInputFormatter> mobileNumberInputFormattersFor(
  PhoneCountryCode country,
) {
  return [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(country.localMaxLength),
  ];
}

/// Strips non-digits from [value].
String normalizeMobileNumber(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

/// Returns an error message, or null when valid.
String? validateMobileNumber(String? value, {bool required = false}) {
  return validateMobileNumberForCountry(
    value,
    phoneCountryCodes.first,
    required: required,
  );
}

String? validateDialCode(String? value, {bool required = false}) {
  final normalized = normalizeDialCode(value);
  if (normalized == null) {
    return required ? 'Enter a valid country code like +91.' : null;
  }
  return null;
}

String? validateInternationalMobile({
  required String? dialCode,
  required String? localNumber,
  bool required = false,
}) {
  final dialError = validateDialCode(dialCode, required: required);
  if (dialError != null) return dialError;
  final country = phoneCountryFromDialCode(dialCode);
  return validateMobileNumberForCountry(
    localNumber,
    country,
    required: required,
  );
}

String? validateMobileNumberForCountry(
  String? value,
  PhoneCountryCode country, {
  bool required = false,
}) {
  final digits = normalizeMobileNumber(value ?? '');
  if (digits.isEmpty) {
    return required ? 'Enter your mobile number.' : null;
  }
  if (digits.length < country.localMinLength ||
      digits.length > country.localMaxLength) {
    if (country.localMinLength == country.localMaxLength) {
      return 'Mobile number must be exactly ${country.localMaxLength} digits.';
    }
    return 'Mobile number must be ${country.localMinLength}-${country.localMaxLength} digits.';
  }
  return null;
}

String formatPhoneWithCountryCode({
  required String dialCode,
  required String localNumber,
}) {
  final digits = normalizeMobileNumber(localNumber);
  if (digits.isEmpty) return dialCode;
  return '$dialCode $digits';
}

/// Normalizes a LinkedIn profile URL to https form, or null when empty.
String? normalizeLinkedInUrl(String value) {
  var trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.contains('linkedin.com')) {
    trimmed = 'https://www.linkedin.com/in/$trimmed';
  } else if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    trimmed = 'https://$trimmed';
  }
  return trimmed;
}

/// Returns an error message, or null when valid.
String? validateLinkedInUrl(String? value, {bool required = false}) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) {
    return required ? 'Enter your LinkedIn profile URL.' : null;
  }

  final normalized = normalizeLinkedInUrl(trimmed);
  final uri = Uri.tryParse(normalized ?? '');
  if (uri == null ||
      !uri.hasScheme ||
      !uri.host.toLowerCase().contains('linkedin.com')) {
    return 'Enter a valid LinkedIn URL (e.g. https://www.linkedin.com/in/your-name).';
  }

  final path = uri.path.toLowerCase();
  if (!path.contains('/in/') &&
      !path.contains('/company/') &&
      !path.contains('/pub/')) {
    return 'Use a profile link like https://www.linkedin.com/in/your-name.';
  }

  return null;
}
