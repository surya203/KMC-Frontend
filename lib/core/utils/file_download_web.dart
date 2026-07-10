import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadTextFile({
  required String fileName,
  required String content,
  String mimeType = 'text/plain',
}) async {
  final blobParts = [content.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

Future<void> downloadBytes(
  List<int> bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) async {
  final blobParts = [Uint8List.fromList(bytes).toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
