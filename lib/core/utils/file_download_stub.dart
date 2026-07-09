/// Non-web fallback: browser downloads only work on Flutter web.
void downloadBytes(
  List<int> bytes,
  String filename, {
  String mimeType = 'text/csv',
}) {
  // No-op outside the browser.
}
