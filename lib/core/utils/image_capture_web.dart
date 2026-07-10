import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'image_capture_stub.dart';

Future<CapturedImage?> captureImageFromCamera() async => null;

Future<CapturedImage?> captureImageWithLivePreview(BuildContext context) {
  return showDialog<CapturedImage>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _LiveCameraDialog(),
  );
}

class _LiveCameraDialog extends StatefulWidget {
  const _LiveCameraDialog();

  @override
  State<_LiveCameraDialog> createState() => _LiveCameraDialogState();
}

class _LiveCameraDialogState extends State<_LiveCameraDialog> {
  static int _viewCounter = 0;

  late final String _viewType;
  web.MediaStream? _stream;
  web.HTMLVideoElement? _video;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = 'live-camera-${_viewCounter++}';
    _initCamera();
  }

  Future<void> _initCamera() async {
    final video = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..playsInline = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    _video = video;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => video,
    );

    try {
      final mediaDevices = web.window.navigator.mediaDevices;

      final stream = await mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              video: web.MediaTrackConstraints(
                facingMode: 'user'.toJS,
              ),
            ),
          )
          .toDart;
      _stream = stream;
      video.srcObject = stream;

      final completer = Completer<void>();
      video.onloadedmetadata = ((web.Event _) {
        if (!completer.isCompleted) completer.complete();
      }).toJS;
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Camera preview timed out.'),
      );

      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = null;
      });
    } catch (e) {
      _stopStream();
      if (!mounted) return;
      setState(() {
        _ready = false;
        _error = e.toString();
      });
    }
  }

  void _stopStream() {
    final stream = _stream;
    if (stream == null) return;
    final tracks = stream.getTracks().toDart;
    for (final track in tracks) {
      track.stop();
    }
    _stream = null;
  }

  Future<void> _capturePhoto() async {
    final video = _video;
    if (video == null || video.videoWidth == 0 || video.videoHeight == 0) {
      return;
    }

    final canvas = web.HTMLCanvasElement()
      ..width = video.videoWidth
      ..height = video.videoHeight;
    final context2d = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (context2d == null) return;

    context2d.drawImage(video, 0, 0);
    final dataUrl = canvas.toDataURL('image/jpeg', 0.92.toJS);
    final base64 = dataUrl.split(',').last;
    final bytes = Uint8List.fromList(base64Decode(base64));

    _stopStream();
    if (!mounted) return;
    Navigator.of(context).pop(
      CapturedImage(bytes: bytes, fileName: 'camera-photo.jpg'),
    );
  }

  void _close() {
    _stopStream();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Take a photo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: _error != null
                      ? Center(child: Text(_error!))
                      : _ready
                          ? HtmlElementView(viewType: _viewType)
                          : const Center(child: CircularProgressIndicator()),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _close,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _ready ? _capturePhoto : null,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Capture'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
