import 'package:web/web.dart' as web;

/// After PayU returns to `/#/membership?payu=…`, clean browser history so Back
/// does not revisit `/payu-response` or re-run payment handling.
///
/// Backend already uses `location.replace` for the callback. Here we only
/// [replaceState] the hash (strip `payu=`) — no extra [pushState], so Back is
/// one step and does not feel sticky or slow.
void scrubPayuReturnBrowserHistory() {
  final loc = web.window.location;
  final hash = loc.hash;
  final search = loc.search;
  final hasPayu = hash.contains('payu=') || search.contains('payu=');
  if (!hasPayu) return;

  final path = loc.pathname.isEmpty ? '/' : loc.pathname;
  final target = '$path#/membership';
  web.window.history.replaceState(null, '', target);
}
