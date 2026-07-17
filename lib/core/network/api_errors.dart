bool isSessionExpiredError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('invalid or expired token') ||
      message.contains('session expired') ||
      message.contains('not signed in') ||
      message.contains('unauthorized');
}

/// True for flaky network / backend-restart errors worth auto-retrying.
bool isTransientNetworkError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('could not reach') ||
      message.contains('connection') ||
      message.contains('timeout') ||
      message.contains('socket') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('gallery request failed') ||
      message.contains('xmlhttprequest error');
}

/// Retries [action] a few times on transient network failures.
Future<T> withNetworkRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
}) async {
  Object? lastError;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e) {
      lastError = e;
      final canRetry =
          attempt < maxAttempts - 1 && isTransientNetworkError(e);
      if (!canRetry) rethrow;
      await Future<void>.delayed(
        Duration(milliseconds: 400 * (attempt + 1)),
      );
    }
  }
  throw lastError!;
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

  if (lower.contains('could not reach') ||
      lower.contains('connection') ||
      lower.contains('timeout') ||
      lower.contains('xmlhttprequest')) {
    return 'Could not reach the server. Check that the backend is running, '
        'then tap Retry.';
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
