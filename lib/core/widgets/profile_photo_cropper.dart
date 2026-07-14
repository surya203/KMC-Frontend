import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../utils/compress_profile_photo.dart';

/// Opens a WhatsApp-style circular DP cropper. Returns cropped square bytes
/// or `null` if the user cancels.
Future<Uint8List?> showProfilePhotoCropper(
  BuildContext context, {
  required Uint8List imageBytes,
  String title = 'Move and scale',
}) async {
  if (imageBytes.isEmpty || !looksLikeImageBytes(imageBytes)) {
    return null;
  }

  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ProfilePhotoCropScreen(
        imageBytes: imageBytes,
        title: title,
      ),
    ),
  );
}

/// Pick an image, crop like WhatsApp DP, return a [PlatformFile] ready to upload.
Future<PlatformFile?> pickAndCropProfilePhoto(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: false,
  );
  final file = result?.files.single;
  if (file == null) return null;

  Uint8List? bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    final stream = file.readStream;
    if (stream != null) {
      final chunks = await stream.toList();
      bytes = Uint8List.fromList(chunks.expand((c) => c).toList());
    }
  }
  if (bytes == null || bytes.isEmpty) {
    throw Exception('Could not read image file. Try a smaller JPG or PNG.');
  }

  if (!context.mounted) return null;
  final cropped = await showProfilePhotoCropper(context, imageBytes: bytes);
  if (cropped == null || cropped.isEmpty) return null;

  final name = _croppedFileName(file.name);
  return PlatformFile(name: name, size: cropped.length, bytes: cropped);
}

/// Crop camera / preloaded bytes with the same circular DP UI.
Future<PlatformFile?> cropProfilePhotoFile(
  BuildContext context, {
  required Uint8List bytes,
  String fileName = 'profile-photo.jpg',
}) async {
  if (bytes.isEmpty) return null;
  final cropped = await showProfilePhotoCropper(context, imageBytes: bytes);
  if (cropped == null || cropped.isEmpty) return null;
  final name = _croppedFileName(fileName);
  return PlatformFile(name: name, size: cropped.length, bytes: cropped);
}

String _croppedFileName(String original) {
  final base = original.trim().isEmpty ? 'profile-photo' : original;
  final dot = base.lastIndexOf('.');
  final stem = dot > 0 ? base.substring(0, dot) : base;
  return '${stem}_cropped.jpg';
}

class ProfilePhotoCropScreen extends StatefulWidget {
  const ProfilePhotoCropScreen({
    super.key,
    required this.imageBytes,
    this.title = 'Move and scale',
  });

  final Uint8List imageBytes;
  final String title;

  @override
  State<ProfilePhotoCropScreen> createState() => _ProfilePhotoCropScreenState();
}

class _ProfilePhotoCropScreenState extends State<ProfilePhotoCropScreen> {
  final _controller = CropController();
  bool _cropping = false;
  bool _ready = false;

  Future<void> _finish(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        final compressed = await compressProfilePhoto(croppedImage);
        if (!mounted) return;
        Navigator.of(context).pop(compressed);
      case CropFailure(:final cause):
        if (!mounted) return;
        setState(() => _cropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not crop photo: $cause')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: (!_ready || _cropping)
                ? null
                : () {
                    setState(() => _cropping = true);
                    _controller.crop();
                  },
            child: _cropping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Done',
                    style: GoogleFonts.inter(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              withCircleUi: true,
              interactive: true,
              fixCropRect: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.55),
              progressIndicator: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              onStatusChanged: (status) {
                final ready = status == CropStatus.ready;
                if (ready != _ready && mounted) {
                  setState(() => _ready = ready);
                }
              },
              onCropped: _finish,
              scrollZoomSensitivity: 0.05,
              willUpdateScale: (scale) => scale >= 1 && scale <= 5,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Text(
                'Drag to reposition · Scroll or pinch to zoom',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
