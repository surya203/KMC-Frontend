import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'payu_checkout_result.dart';

/// Web: classic Hosted Checkout — POST a hidden form to PayU (full navigation).
/// Return is handled when the browser comes back to `/#/membership?payu=…`.
Future<PayuCheckoutLaunchResult?> openPayuHostedCheckout({
  required String actionUrl,
  required Map<String, String> fields,
  // ignore: avoid_unused_constructor_parameters — API parity with mobile
  BuildContext? context,
}) async {
  final form = web.HTMLFormElement()
    ..method = 'POST'
    ..action = actionUrl;
  for (final entry in fields.entries) {
    final input = web.HTMLInputElement()
      ..type = 'hidden'
      ..name = entry.key
      ..value = entry.value;
    form.append(input);
  }
  web.document.body?.append(form);
  form.submit();
  return null;
}
