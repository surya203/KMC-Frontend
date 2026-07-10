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
