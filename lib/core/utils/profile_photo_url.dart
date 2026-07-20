import '../config/app_config.dart';

/// Build candidate public URLs for a profile photo path/URL.
///
/// Prefers API `/media/{bucket}/...` (local Postgres mode). Also keeps
/// legacy Supabase public object URLs when [AppConfig.supabaseUrl] is set.
List<String> profilePhotoUrlCandidates(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return const [];

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return _expandAbsolute(value);
  }

  final clean = value.replaceFirst(RegExp(r'^/+'), '');
  final buckets = <String>{
    'gallery',
    AppConfig.storageBucket,
    'verification-documents',
    'profile-photos',
  }.where((b) => b.trim().isNotEmpty).toList();

  final apiBase = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final out = <String>[
    for (final bucket in buckets) '$apiBase/media/$bucket/$clean',
  ];

  final supabaseBase = AppConfig.supabaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (supabaseBase.isNotEmpty) {
    for (final bucket in buckets) {
      out.add('$supabaseBase/storage/v1/object/public/$bucket/$clean');
    }
  }
  return out;
}

List<String> _expandAbsolute(String url) {
  final out = <String>[url];
  const supabaseMarker = '/storage/v1/object/public/';
  final sIdx = url.indexOf(supabaseMarker);
  if (sIdx >= 0) {
    final rest = url.substring(sIdx + supabaseMarker.length);
    final slash = rest.indexOf('/');
    if (slash > 0) {
      final key = rest.substring(slash + 1);
      final apiBase = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      for (final bucket in {
        rest.substring(0, slash),
        'gallery',
        AppConfig.storageBucket,
        'profile-photos',
      }.where((b) => b.trim().isNotEmpty)) {
        final candidate = '$apiBase/media/$bucket/$key';
        if (!out.contains(candidate)) out.add(candidate);
      }
    }
  }
  const mediaMarker = '/media/';
  final mIdx = url.indexOf(mediaMarker);
  if (mIdx >= 0) {
    final rest = url.substring(mIdx + mediaMarker.length);
    final slash = rest.indexOf('/');
    if (slash > 0) {
      final key = rest.substring(slash + 1);
      final apiBase = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      for (final bucket in {
        rest.substring(0, slash),
        'gallery',
        AppConfig.storageBucket,
        'profile-photos',
      }.where((b) => b.trim().isNotEmpty)) {
        final candidate = '$apiBase/media/$bucket/$key';
        if (!out.contains(candidate)) out.add(candidate);
      }
    }
  }
  return out;
}
