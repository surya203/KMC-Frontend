export 'download_file_stub.dart'
    if (dart.library.html) 'download_file_web.dart';

String galleryDownloadFilename(String url, {String? caption}) {
  if (caption != null && caption.trim().isNotEmpty) {
    final safe = caption.trim().replaceAll(RegExp(r'[^\w\-. ]'), '_');
    final uri = Uri.tryParse(url);
    final parts = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last.split('.')
        : <String>[];
    final ext = parts.length > 1 ? parts.last : 'jpg';
    if (ext.length <= 5 && ext.isNotEmpty) {
      return '$safe.$ext';
    }
    return '$safe.jpg';
  }

  final uri = Uri.tryParse(url);
  if (uri == null) return 'photo.jpg';
  final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  if (segment.isNotEmpty) return segment;
  return 'photo.jpg';
}
