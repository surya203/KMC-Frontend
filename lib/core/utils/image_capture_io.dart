import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_capture_stub.dart';

export 'image_capture_stub.dart'
    hide captureImageFromCamera, captureImageWithLivePreview;

Future<CapturedImage?> captureImageFromCamera() => _pickFromNativeCamera();

Future<CapturedImage?> captureImageWithLivePreview(BuildContext context) {
  if (!context.mounted) return Future<CapturedImage?>.value(null);
  return _pickFromNativeCamera();
}

Future<CapturedImage?> _pickFromNativeCamera() async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    throw Exception(
      'Camera capture is only available on the Android and iOS apps.',
    );
  }

  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 92,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    final file = picked ?? await _recoverLostCameraImage(picker);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return capturedImageFromPickerResult(bytes: bytes, fileName: file.name);
  } catch (e) {
    if (e is Exception &&
        e.toString().contains('Camera capture is only available')) {
      rethrow;
    }
    throw Exception(cameraCaptureFailureMessage(e));
  }
}

Future<XFile?> _recoverLostCameraImage(ImagePicker picker) async {
  try {
    final lost = await picker.retrieveLostData();
    if (lost.isEmpty) return null;
    if (lost.file != null) return lost.file;
    final files = lost.files;
    if (files != null && files.isNotEmpty) return files.first;
    return null;
  } catch (_) {
    return null;
  }
}
