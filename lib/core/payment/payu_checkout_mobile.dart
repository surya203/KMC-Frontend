import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'payu_checkout_result.dart';

/// Opens PayU Hosted Checkout inside an in-app WebView (Android / iOS).
/// Completes when PayU redirects to the merchant return URL containing `payu=`.
Future<PayuCheckoutLaunchResult?> openPayuHostedCheckout({
  required String actionUrl,
  required Map<String, String> fields,
  BuildContext? context,
}) async {
  final navContext = context;
  if (navContext == null || !navContext.mounted) {
    throw StateError(
      'PayU checkout on mobile requires a BuildContext. '
      'Pass context when calling openPayuHostedCheckout.',
    );
  }

  return Navigator.of(navContext).push<PayuCheckoutLaunchResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PayuCheckoutWebView(
        actionUrl: actionUrl,
        fields: fields,
      ),
    ),
  );
}

class _PayuCheckoutWebView extends StatefulWidget {
  const _PayuCheckoutWebView({
    required this.actionUrl,
    required this.fields,
  });

  final String actionUrl;
  final Map<String, String> fields;

  @override
  State<_PayuCheckoutWebView> createState() => _PayuCheckoutWebViewState();
}

class _PayuCheckoutWebViewState extends State<_PayuCheckoutWebView> {
  late final WebViewController _controller;
  var _finishing = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final result = _parsePayuReturn(request.url);
            if (result != null) {
              _complete(result);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            final result = _parsePayuReturn(url);
            if (result != null) _complete(result);
          },
        ),
      )
      ..loadHtmlString(
        _buildAutoSubmitHtml(widget.actionUrl, widget.fields),
        baseUrl: widget.actionUrl,
      );
  }

  void _complete(PayuCheckoutLaunchResult result) {
    if (_finishing || !mounted) return;
    _finishing = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop(
              const PayuCheckoutLaunchResult(outcome: 'cancelled'),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator.adaptive()),
        ],
      ),
    );
  }
}

PayuCheckoutLaunchResult? _parsePayuReturn(String url) {
  Uri? uri;
  try {
    uri = Uri.parse(url);
  } catch (_) {
    return null;
  }

  String? outcome = uri.queryParameters['payu'];
  String? draftId = uri.queryParameters['draft_id'];

  // Flutter hash routes: https://host/#/membership?payu=success&draft_id=…
  final fragment = uri.fragment;
  if ((outcome == null || outcome.isEmpty) && fragment.contains('payu=')) {
    final fragUri = Uri.parse(
      fragment.startsWith('/') ? 'app:$fragment' : 'app:/$fragment',
    );
    outcome = fragUri.queryParameters['payu'] ?? outcome;
    draftId = fragUri.queryParameters['draft_id'] ?? draftId;
  }

  if (outcome == null || outcome.isEmpty) return null;
  return PayuCheckoutLaunchResult(outcome: outcome, draftId: draftId);
}

String _buildAutoSubmitHtml(String actionUrl, Map<String, String> fields) {
  final buffer = StringBuffer()
    ..writeln('<!DOCTYPE html><html><head><meta charset="utf-8">')
    ..writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    )
    ..writeln('<title>Redirecting to PayU</title></head><body>')
    ..writeln('<p>Redirecting to secure payment…</p>')
    ..writeln('<form id="payu" method="post" action="${_esc(actionUrl)}">');
  for (final entry in fields.entries) {
    buffer.writeln(
      '<input type="hidden" name="${_esc(entry.key)}" value="${_esc(entry.value)}" />',
    );
  }
  buffer
    ..writeln('</form>')
    ..writeln('<script>document.getElementById("payu").submit();</script>')
    ..writeln('</body></html>');
  return buffer.toString();
}

String _esc(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
