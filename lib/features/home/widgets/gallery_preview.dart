import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/cms_service.dart';
import '../../../core/widgets/safe_asset_image.dart';
import 'section_header.dart';

class GalleryPreview extends StatelessWidget {
  const GalleryPreview({super.key});

  static const _columnLayouts = [
    [220.0, 170.0],
    [190.0, 230.0, 160.0],
    [210.0, 250.0],
    [200.0],
  ];

  @override
  Widget build(BuildContext context) {
    final albums = CmsService.galleryAlbums;
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              SectionHeader(
                eyebrow: 'Gallery',
                center: false,
                regularTitle: 'Decades of ',
                italicTitle: 'memories.',
                actionLabel: 'Open gallery',
                onAction: () => context.go('/gallery'),
              ),
              const SizedBox(height: 32),
              if (width > 900)
                _MasonryGallery(albums: albums, layouts: _columnLayouts)
              else
                _MobileGallery(albums: albums),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasonryGallery extends StatelessWidget {
  const _MasonryGallery({
    required this.albums,
    required this.layouts,
  });

  final List<(String, String)> albums;
  final List<List<double>> layouts;

  @override
  Widget build(BuildContext context) {
    final columns = <List<(String, double)>>[];
    var imageIndex = 0;

    for (final heights in layouts) {
      final columnItems = <(String, double)>[];
      for (final height in heights) {
        if (imageIndex >= albums.length) break;
        columnItems.add((albums[imageIndex].$2, height));
        imageIndex++;
      }
      columns.add(columnItems);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var col = 0; col < columns.length; col++) ...[
          if (col > 0) const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                for (var row = 0; row < columns[col].length; row++) ...[
                  if (row > 0) const SizedBox(height: 12),
                  _GalleryImage(
                    assetPath: columns[col][row].$1,
                    height: columns[col][row].$2,
                    onTap: () => context.go('/gallery'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MobileGallery extends StatelessWidget {
  const _MobileGallery({required this.albums});

  final List<(String, String)> albums;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        return _GalleryImage(
          assetPath: albums[index].$2,
          height: 180,
          onTap: () => context.go('/gallery'),
        );
      },
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({
    required this.assetPath,
    required this.height,
    required this.onTap,
  });

  final String assetPath;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: SafeAssetImage(
            assetPath: assetPath,
            fit: BoxFit.cover,
            expandToFill: true,
          ),
        ),
      ),
    );
  }
}
