/// Non-web fallback: Razorpay checkout is only wired for Flutter web.
bool get razorpayAvailable => false;

Future<bool> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String currency,
  String name = 'KMC Alumni Connect',
  String? description,
  String? prefillEmail,
}) async {
  return false;
}
