import 'dart:typed_data';

import 'package:flutter/material.dart';

class CapturedImage {
  const CapturedImage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

CapturedImage? capturedImageFromPickerResult({
  required Uint8List bytes,
  required String fileName,
}) {
  if (bytes.isEmpty) return null;
  final name = fileName.trim().isEmpty ? 'camera-photo.jpg' : fileName.trim();
  return CapturedImage(bytes: bytes, fileName: name);
}

String cameraCaptureFailureMessage(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('camera_access_denied') ||
      (text.contains('permission') && text.contains('camera'))) {
    return 'Camera permission is required to take a photo. Enable Camera in app settings and try again.';
  }
  if (text.contains('camera_unavailable') ||
      text.contains('no available camera') ||
      text.contains('no camera')) {
    return 'No camera is available on this device.';
  }
  return 'Could not open the camera. Please try again or upload a photo.';
}

Future<CapturedImage?> captureImageFromCamera() async => null;

Future<CapturedImage?> captureImageWithLivePreview(BuildContext context) async =>
    null;
