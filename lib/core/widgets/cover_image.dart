import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import 'safe_asset_image.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    this.imageUrl,
    this.fallbackAsset = AppAssets.eventBanner,
    this.height = 240,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String fallbackAsset;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return SizedBox(
        height: height,
        child: SafeAssetImage(
          assetPath: fallbackAsset,
          fit: fit,
          expandToFill: true,
        ),
      );
    }

    return SizedBox(
      height: height,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: double.infinity,
        placeholder: (_, _) => Container(color: AppColors.muted),
        errorWidget: (_, _, _) => SafeAssetImage(
          assetPath: fallbackAsset,
          fit: fit,
          expandToFill: true,
        ),
      ),
    );
  }
}
