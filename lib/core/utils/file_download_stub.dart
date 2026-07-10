Future<void> downloadTextFile({
  required String fileName,
  required String content,
  String mimeType = 'text/plain',
}) async {
  throw UnsupportedError('Download is only supported on web.');
}

Future<void> downloadBytes(
  List<int> bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) async {
  throw UnsupportedError('Download is only supported on web.');
}
