import 'package:web/web.dart' as web;

void openPayuHostedCheckout({
  required String actionUrl,
  required Map<String, String> fields,
}) {
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
}
