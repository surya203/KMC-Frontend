import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// True when the Razorpay checkout.js script is loaded in index.html.
bool get razorpayAvailable =>
    !web.window.getProperty('Razorpay'.toJS).isUndefinedOrNull;

/// Opens the Razorpay checkout modal. Resolves true when payment succeeds,
/// false when the user dismisses the modal or checkout is unavailable.
Future<bool> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String currency,
  String name = 'KMC Alumni Connect',
  String? description,
  String? prefillEmail,
}) {
  final ctor = web.window.getProperty('Razorpay'.toJS);
  if (ctor.isUndefinedOrNull) {
    return Future.value(false);
  }

  final completer = Completer<bool>();

  final options = JSObject()
    ..setProperty('key'.toJS, keyId.toJS)
    ..setProperty('amount'.toJS, amountPaise.toJS)
    ..setProperty('currency'.toJS, currency.toJS)
    ..setProperty('order_id'.toJS, orderId.toJS)
    ..setProperty('name'.toJS, name.toJS);

  if (description != null) {
    options.setProperty('description'.toJS, description.toJS);
  }
  if (prefillEmail != null && prefillEmail.isNotEmpty) {
    final prefill = JSObject()..setProperty('email'.toJS, prefillEmail.toJS);
    options.setProperty('prefill'.toJS, prefill);
  }

  options.setProperty(
    'handler'.toJS,
    ((JSAny? response) {
      if (!completer.isCompleted) completer.complete(true);
    }).toJS,
  );

  final modal = JSObject()
    ..setProperty(
      'ondismiss'.toJS,
      (() {
        if (!completer.isCompleted) completer.complete(false);
      }).toJS,
    );
  options.setProperty('modal'.toJS, modal);

  final rzp = (ctor as JSFunction).callAsConstructor<JSObject>(options);
  rzp.callMethod('open'.toJS);

  return completer.future;
}
