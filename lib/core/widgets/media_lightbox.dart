import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen image viewer for gallery album media (handbook MediaLightbox).
class MediaLightbox extends StatelessWidget {
  const MediaLightbox({
    super.key,
    required this.imageUrl,
    this.caption,
  });

  final String imageUrl;
  final String? caption;

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? caption,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => MediaLightbox(imageUrl: imageUrl, caption: caption),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
          if (caption != null && caption!.isNotEmpty)
            Positioned(
              left: 0,
              right: 48,
              bottom: 0,
              child: Text(
                caption!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              key: const ValueKey('gallery-lightbox-close'),
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
