import 'dart:html' as html;
import 'dart:typed_data';

import 'package:dio/dio.dart';

String _filenameFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return 'photo.jpg';
  final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  if (segment.isNotEmpty) return segment;
  return 'photo.jpg';
}

Future<bool> downloadFromUrl(
  String url, {
  String? filename,
}) async {
  try {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return false;

    final name = filename ?? _filenameFromUrl(url);
    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: objectUrl)
      ..download = name
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(objectUrl);
    return true;
  } catch (_) {
    return false;
  }
}
