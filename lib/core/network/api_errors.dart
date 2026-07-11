bool isSessionExpiredError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('invalid or expired token') ||
      message.contains('session expired') ||
      message.contains('not signed in') ||
      message.contains('unauthorized');
}

/// Hides backend/dev jargon from messages shown in the UI.
String sanitizeUserFacingMessage(String message) {
  final lower = message.toLowerCase();

  if (lower.contains('smtp') ||
      lower.contains('email delivery') ||
      lower.contains('email is not fully configured') ||
      lower.contains('.env file') ||
      lower.contains('restart the server') ||
      lower.contains('could not send verification email') ||
      lower.contains('check smtp settings')) {
    return "We couldn't send the verification code to your email right now. "
        'Please try again in a few minutes.';
  }

  if (lower.contains('service unavailable') && lower.contains('email')) {
    return "We couldn't send the verification code to your email right now. "
        'Please try again in a few minutes.';
  }

  return message;
}

String friendlyApiError(Object error) {
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (isSessionExpiredError(error)) {
    return 'Your session has expired. Please sign in again to continue.';
  }
  return sanitizeUserFacingMessage(raw);
}
