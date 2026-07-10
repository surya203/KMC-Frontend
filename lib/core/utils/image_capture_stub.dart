import 'dart:typed_data';

import 'package:flutter/material.dart';

class CapturedImage {
  const CapturedImage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

Future<CapturedImage?> captureImageFromCamera() async => null;

Future<CapturedImage?> captureImageWithLivePreview(BuildContext context) async =>
    null;
