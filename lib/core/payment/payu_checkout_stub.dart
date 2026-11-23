// Unused when mobile/web implementations are selected via payu_checkout.dart.
// Kept so older imports do not break during refactors.
import 'package:flutter/widgets.dart';

import 'payu_checkout_result.dart';

Future<PayuCheckoutLaunchResult?> openPayuHostedCheckout({
  required String actionUrl,
  required Map<String, String> fields,
  BuildContext? context,
}) async {
  throw UnsupportedError(
    'PayU checkout requires web or mobile implementation.',
  );
}
