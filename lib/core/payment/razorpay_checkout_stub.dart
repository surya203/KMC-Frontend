Future<void> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String currency,
  required String name,
  required String email,
  required void Function() onSuccess,
  required void Function(String message) onDismiss,
}) {
  throw UnsupportedError('Razorpay checkout is only available on web.');
}
