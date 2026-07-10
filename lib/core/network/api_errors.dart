bool isSessionExpiredError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('invalid or expired token') ||
      message.contains('session expired') ||
      message.contains('not signed in') ||
      message.contains('unauthorized');
}

String friendlyApiError(Object error) {
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (isSessionExpiredError(error)) {
    return 'Your session has expired. Please sign in again to continue.';
  }
  return raw;
}
