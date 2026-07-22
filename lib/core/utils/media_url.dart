import '../config/app_config.dart';

/// Resolves relative media paths from the API into absolute URLs.
///
/// Rewrites absolute URLs to [AppConfig.apiBaseUrl] when:
/// - host is localhost/127.0.0.1 (phone-over-LAN), or
/// - path is `/media/...` (stale PUBLIC_API_BASE_URL / old LAN IP).
String? resolveMediaUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return _rewriteToApiBaseIfNeeded(trimmed);
  }
  if (trimmed.startsWith('/')) {
    return '${AppConfig.apiBaseUrl}$trimmed';
  }
  return '${AppConfig.apiBaseUrl}/$trimmed';
}

String _rewriteToApiBaseIfNeeded(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return url;

  final api = Uri.tryParse(AppConfig.apiBaseUrl);
  if (api == null || api.host.isEmpty) return url;

  final host = uri.host.toLowerCase();
  final apiHost = api.host.toLowerCase();
  final apiPort = api.hasPort ? api.port : null;
  final sameOrigin = host == apiHost &&
      (apiPort == null || uri.hasPort == false || uri.port == apiPort);
  if (sameOrigin) return url;

  final isLoopback = host == 'localhost' || host == '127.0.0.1';
  final isApiMedia = uri.path.startsWith('/media/');
  if (!isLoopback && !isApiMedia) return url;

  return uri
      .replace(
        scheme: api.scheme,
        host: api.host,
        port: apiPort,
      )
      .toString();
}

/// Appends a cache-busting query param so refreshed images load immediately.
String withCacheBust(String url, {int? version}) {
  final v = version ?? DateTime.now().millisecondsSinceEpoch;
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}v=$v';
}
