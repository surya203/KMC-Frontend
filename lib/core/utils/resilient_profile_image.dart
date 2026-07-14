import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'profile_photo_url.dart';

/// Loads a profile photo and retries alternate storage-bucket URLs on failure.
class ResilientProfileImage extends StatefulWidget {
  const ResilientProfileImage({
    super.key,
    required this.photoUrl,
    required this.width,
    required this.height,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? photoUrl;
  final double width;
  final double height;
  final Widget fallback;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  State<ResilientProfileImage> createState() => _ResilientProfileImageState();
}

class _ResilientProfileImageState extends State<ResilientProfileImage> {
  late List<String> _candidates;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _candidates = profilePhotoUrlCandidates(widget.photoUrl);
  }

  @override
  void didUpdateWidget(covariant ResilientProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _candidates = profilePhotoUrlCandidates(widget.photoUrl);
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty || _index >= _candidates.length) {
      return widget.fallback;
    }

    final image = CachedNetworkImage(
      imageUrl: _candidates[_index],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorWidget: (context, url, error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_index < _candidates.length - 1) {
            setState(() => _index += 1);
          }
        });
        if (_index >= _candidates.length - 1) {
          return widget.fallback;
        }
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }
    return image;
  }
}
