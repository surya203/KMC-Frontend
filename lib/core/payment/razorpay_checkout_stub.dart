class RazorpayPaymentResult {
  const RazorpayPaymentResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

Future<void> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String currency,
  required String name,
  required String email,
  required void Function(RazorpayPaymentResult result) onSuccess,
  required void Function(String message) onDismiss,
  void Function(String message)? onFailed,
}) {
  throw UnsupportedError('Razorpay checkout is only available on web.');
}
