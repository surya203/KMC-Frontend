import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kmc_alumni_connect/core/utils/image_capture.dart';

void main() {
  test('empty camera bytes are rejected', () {
    expect(
      capturedImageFromPickerResult(
        bytes: Uint8List(0),
        fileName: 'camera-photo.jpg',
      ),
      isNull,
    );
  });

  test('camera bytes become a captured image with a fallback file name', () {
    final image = capturedImageFromPickerResult(
      bytes: Uint8List.fromList(const [1, 2, 3, 4]),
      fileName: '  ',
    );

    expect(image, isNotNull);
    expect(image!.bytes, const [1, 2, 3, 4]);
    expect(image.fileName, 'camera-photo.jpg');
  });

  test('keeps a real camera file name', () {
    final image = capturedImageFromPickerResult(
      bytes: Uint8List.fromList(const [9]),
      fileName: 'front-cam.jpg',
    );

    expect(image!.fileName, 'front-cam.jpg');
  });

  test('maps camera permission denial to a clear message', () {
    final message = cameraCaptureFailureMessage(
      PlatformException(code: 'camera_access_denied', message: 'denied'),
    );

    expect(message.toLowerCase(), contains('permission'));
    expect(message.toLowerCase(), contains('camera'));
  });

  test('maps a missing camera to a clear message', () {
    final message = cameraCaptureFailureMessage(
      PlatformException(code: 'camera_unavailable', message: 'none'),
    );

    expect(message.toLowerCase(), contains('camera'));
  });

  test('release AndroidManifest declares camera permission and capture query', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, contains('android.permission.CAMERA'));
    expect(manifest, contains('android.media.action.IMAGE_CAPTURE'));
    expect(manifest, isNot(contains('READ_MEDIA_IMAGES')));
  });

  test('pubspec includes image_picker for native camera capture', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('image_picker:'));
  });
}
