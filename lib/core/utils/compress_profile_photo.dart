import 'dart:typed_data';
import 'dart:ui' as ui;

/// Resizes profile photos for reliable local storage on web.
Future<Uint8List> compressProfilePhoto(Uint8List bytes) async {
  if (bytes.isEmpty) return bytes;

  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 320,
      targetHeight: 320,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();
    if (byteData != null && byteData.lengthInBytes > 0) {
      return byteData.buffer.asUint8List();
    }
  } catch (_) {
    // Fall back to original bytes when compression fails.
  }
  return bytes;
}

bool looksLikeImageBytes(Uint8List bytes) {
  if (bytes.length < 12) return false;
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return true;
  }
  if (bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46) {
    return true;
  }
  return false;
}
