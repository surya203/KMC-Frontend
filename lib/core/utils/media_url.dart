import '../config/app_config.dart';

/// Resolves relative media paths from the API into absolute URLs.
///
/// Also rewrites localhost/127.0.0.1 absolute URLs to [AppConfig.apiBaseUrl]
/// so gallery/drugs images work on a phone over LAN.
String? resolveMediaUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return _rewriteLocalhostToApiBase(trimmed);
  }
  if (trimmed.startsWith('/')) {
    return '${AppConfig.apiBaseUrl}$trimmed';
  }
  return '${AppConfig.apiBaseUrl}/$trimmed';
}

String _rewriteLocalhostToApiBase(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return url;
  final host = uri.host.toLowerCase();
  if (host != 'localhost' && host != '127.0.0.1') return url;

  final api = Uri.tryParse(AppConfig.apiBaseUrl);
  if (api == null || api.host.isEmpty) return url;

  return uri
      .replace(
        scheme: api.scheme,
        host: api.host,
        port: api.hasPort ? api.port : null,
      )
      .toString();
}

/// Appends a cache-busting query param so refreshed images load immediately.
String withCacheBust(String url, {int? version}) {
  final v = version ?? DateTime.now().millisecondsSinceEpoch;
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}v=$v';
}
