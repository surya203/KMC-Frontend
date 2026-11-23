import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'payu_checkout_result.dart';

/// Opens PayU Hosted Checkout inside an in-app WebView (Android / iOS).
/// Completes when PayU redirects to the merchant return URL containing `payu=`.
///
/// Cards / netbanking need full HTTPS navigation (3DS, bank pages). UPI apps
/// use custom schemes (`upi://`, `phonepe://`, …) which we open externally.
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
    _controller = WebViewController.fromPlatformCreationParams(
      _platformParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            final result = _parsePayuReturn(url);
            if (result != null) _complete(result);
          },
          onNavigationRequest: (request) {
            final result = _parsePayuReturn(request.url);
            if (result != null) {
              _complete(result);
              return NavigationDecision.prevent;
            }
            if (_isExternalPaymentScheme(request.url)) {
              _openExternalPaymentUrl(request.url);
              return NavigationDecision.prevent;
            }
            // Allow PayU + bank ACS / netbanking HTTPS pages in-WebView.
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            final result = _parsePayuReturn(url);
            if (result != null) _complete(result);
          },
        ),
      );

    _configurePlatformWebView(_controller);

    _controller.loadHtmlString(
      _buildAutoSubmitHtml(widget.actionUrl, widget.fields),
      baseUrl: widget.actionUrl,
    );
  }

  PlatformWebViewControllerCreationParams _platformParams() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    }
    return const PlatformWebViewControllerCreationParams();
  }

  Future<void> _configurePlatformWebView(WebViewController controller) async {
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      await AndroidWebViewController.enableDebugging(kDebugMode);
      await platform.setMediaPlaybackRequiresUserGesture(false);
      // Third-party cookies help some bank / 3DS flows inside WebView.
      final cookies = AndroidWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
      );
      await cookies.setAcceptThirdPartyCookies(platform, true);
    } else if (platform is WebKitWebViewController) {
      await platform.setAllowsBackForwardNavigationGestures(true);
    }
  }

  void _complete(PayuCheckoutLaunchResult result) {
    if (_finishing || !mounted) return;
    _finishing = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _goBackOrCancel() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      const PayuCheckoutLaunchResult(outcome: 'cancelled'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBackOrCancel();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Secure payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackOrCancel,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop(
                const PayuCheckoutLaunchResult(outcome: 'cancelled'),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const IgnorePointer(
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
        ],
      ),
    ),
    );
  }
}

bool _isExternalPaymentScheme(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme.isEmpty ||
      scheme == 'http' ||
      scheme == 'https' ||
      scheme == 'about' ||
      scheme == 'data' ||
      scheme == 'blob') {
    return false;
  }
  // UPI / wallet app deep links (and Android intent://).
  return true;
}

Future<void> _openExternalPaymentUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // User may not have the UPI app installed; stay on PayU page.
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
  String? reason = uri.queryParameters['reason'];

  // Flutter hash routes: https://host/#/membership?payu=success&draft_id=…
  final fragment = uri.fragment;
  if ((outcome == null || outcome.isEmpty) && fragment.contains('payu=')) {
    final fragUri = Uri.parse(
      fragment.startsWith('/') ? 'app:$fragment' : 'app:/$fragment',
    );
    outcome = fragUri.queryParameters['payu'] ?? outcome;
    draftId = fragUri.queryParameters['draft_id'] ?? draftId;
    reason = fragUri.queryParameters['reason'] ?? reason;
  }

  if (outcome == null || outcome.isEmpty) return null;
  return PayuCheckoutLaunchResult(
    outcome: outcome,
    draftId: draftId,
    reason: reason,
  );
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
