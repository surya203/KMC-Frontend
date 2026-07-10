import 'package:flutter/services.dart';

/// Input formatters: digits only, max 10 characters.
final List<TextInputFormatter> mobileNumberInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
];

/// Strips non-digits from [value].
String normalizeMobileNumber(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

/// Returns an error message, or null when valid.
String? validateMobileNumber(String? value, {bool required = false}) {
  final digits = normalizeMobileNumber(value ?? '');
  if (digits.isEmpty) {
    return required ? 'Enter a 10-digit mobile number.' : null;
  }
  if (digits.length != 10) {
    return 'Mobile number must be exactly 10 digits.';
  }
  return null;
}
