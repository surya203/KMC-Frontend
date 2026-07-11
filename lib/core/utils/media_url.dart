import '../config/app_config.dart';

/// Resolves relative media paths from the API into absolute URLs.
String? resolveMediaUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '${AppConfig.apiBaseUrl}$trimmed';
  }
  return '${AppConfig.apiBaseUrl}/$trimmed';
}

/// Appends a cache-busting query param so refreshed images load immediately.
String withCacheBust(String url, {int? version}) {
  final v = version ?? DateTime.now().millisecondsSinceEpoch;
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}v=$v';
}
