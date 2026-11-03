/// Result of a hosted PayU session launched from the app (mobile WebView).
/// Web form-POST navigates the browser away and returns null instead.
class PayuCheckoutLaunchResult {
  const PayuCheckoutLaunchResult({
    required this.outcome,
    this.draftId,
  });

  /// PayU return flag: success | failure | pending | cancelled
  final String outcome;
  final String? draftId;

  bool get isSuccess => outcome == 'success' || outcome == 'pending';
  bool get isFailure => outcome == 'failure';
  bool get isCancelled => outcome == 'cancelled';
}
