import 'dart:async';
import 'dart:js_interop';

@JS('Razorpay')
extension type Razorpay._(JSObject _) implements JSObject {
  external Razorpay(JSObject options);
  external void open();
}

Future<void> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String currency,
  required String name,
  required String email,
  required void Function() onSuccess,
  required void Function(String message) onDismiss,
}) async {
  final completer = Completer<void>();

  void successHandler(JSAny _) {
    onSuccess();
    if (!completer.isCompleted) completer.complete();
  }

  void dismissHandler(JSAny _) {
    onDismiss('Payment cancelled.');
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

  Razorpay(options as JSObject).open();
  return completer.future;
}
