import '../config/app_config.dart';

/// Build one or more candidate public URLs for a profile photo path/URL.
///
/// Handles absolute URLs and legacy relative storage keys that may live in
/// `gallery`, `verification-documents`, or `profile-photos`.
List<String> profilePhotoUrlCandidates(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return const [];

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return _alternatePublicBucketUrls(value);
  }

  final base = AppConfig.supabaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (base.isEmpty) return const [];

  final clean = value.replaceFirst(RegExp(r'^/+'), '');
  // Gallery first: uploads often land there when other buckets reject files.
  final buckets = <String>{
    'gallery',
    AppConfig.storageBucket,
    'verification-documents',
    'profile-photos',
  }.where((b) => b.trim().isNotEmpty).toList();

  return [
    for (final bucket in buckets)
      '$base/storage/v1/object/public/$bucket/$clean',
  ];
}

List<String> _alternatePublicBucketUrls(String url) {
  const marker = '/storage/v1/object/public/';
  final idx = url.indexOf(marker);
  if (idx < 0) return [url];
  final rest = url.substring(idx + marker.length);
  final slash = rest.indexOf('/');
  if (slash < 0) return [url];
  final key = rest.substring(slash + 1);
  final prefix = url.substring(0, idx + marker.length);
  final buckets = <String>{
    url.substring(idx + marker.length, idx + marker.length + slash),
    'gallery',
    AppConfig.storageBucket,
    'verification-documents',
    'profile-photos',
  }.where((b) => b.trim().isNotEmpty);

  final out = <String>[url];
  for (final bucket in buckets) {
    final candidate = '$prefix$bucket/$key';
    if (!out.contains(candidate)) out.add(candidate);
  }
  return out;
}
