import 'dart:async';
import 'dart:js_interop';

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

@JS('Razorpay')
extension type Razorpay._(JSObject _) implements JSObject {
  external Razorpay(JSObject options);
  external void open();
  external void on(String event, JSFunction handler);
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
}) async {
  final completer = Completer<void>();

  void successHandler(JSAny response) {
    final data = _asStringMap(response);
    final paymentId = '${data['razorpay_payment_id'] ?? ''}'.trim();
    final paidOrderId = '${data['razorpay_order_id'] ?? ''}'.trim();
    final signature = '${data['razorpay_signature'] ?? ''}'.trim();

    if (paymentId.isEmpty || paidOrderId.isEmpty || signature.isEmpty) {
      const message =
          'Payment succeeded but verification data was incomplete.';
      onFailed?.call(message);
      onDismiss(message);
      if (!completer.isCompleted) completer.complete();
      return;
    }

    onSuccess(
      RazorpayPaymentResult(
        paymentId: paymentId,
        orderId: paidOrderId,
        signature: signature,
      ),
    );
    if (!completer.isCompleted) completer.complete();
  }

  void dismissHandler(JSAny _) {
    onDismiss('Payment cancelled.');
    if (!completer.isCompleted) completer.complete();
  }

  void failedHandler(JSAny response) {
    final data = _asStringMap(response);
    final error = data['error'];
    var message = 'Payment failed. Please try again.';
    if (error is Map) {
      final description = '${error['description'] ?? ''}'.trim();
      final reason = '${error['reason'] ?? ''}'.trim();
      if (description.isNotEmpty) {
        message = description;
      } else if (reason.isNotEmpty) {
        message = reason;
      }
    }
    onFailed?.call(message);
    onDismiss(message);
    if (!completer.isCompleted) completer.complete();
  }

  final options = <String, Object?>{
    'key': keyId,
    'amount': amountPaise,
    'currency': currency,
    'name': name,
    'description': 'KMC Alumni Life Membership',
    'order_id': orderId,
    'prefill': {'email': email, 'name': name},
    'theme': {'color': '#1e3a5f'},
    'handler': successHandler.toJS,
    'modal': {'ondismiss': dismissHandler.toJS},
  }.jsify();

  if (options == null) {
    onDismiss('Could not start Razorpay checkout.');
    return;
  }

  final rzp = Razorpay(options as JSObject);
  rzp.on('payment.failed', failedHandler.toJS);
  rzp.open();
  return completer.future;
}

Map<String, dynamic> _asStringMap(JSAny? value) {
  if (value == null) return const {};
  final dartified = value.dartify();
  if (dartified is Map) {
    return Map<String, dynamic>.from(dartified);
  }
  return const {};
}
