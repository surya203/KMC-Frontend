import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.expandToFill = false,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool expandToFill;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: expandToFill ? null : width,
      height: expandToFill ? null : height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _Placeholder(
        width: width,
        height: height,
        expandToFill: expandToFill,
      ),
    );

    Widget child = image;
    if (expandToFill) {
      child = SizedBox.expand(child: image);
    }

    if (borderRadius == null) return child;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    this.width,
    this.height,
    this.expandToFill = false,
  });

  final double? width;
  final double? height;
  final bool expandToFill;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: expandToFill ? null : width,
      height: expandToFill ? null : height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(expandToFill ? 0 : 8),
        border: expandToFill ? null : Border.all(color: AppColors.border),
      ),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.primary.withValues(alpha: 0.5),
        size: (height ?? 48) * 0.4,
      ),
    );

    if (expandToFill) {
      return SizedBox.expand(child: placeholder);
    }

    return placeholder;
  }
}
