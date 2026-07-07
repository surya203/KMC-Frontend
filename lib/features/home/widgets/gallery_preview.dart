import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/cms_service.dart';
import '../../../core/network/gallery_service.dart';
import '../../../core/widgets/safe_asset_image.dart';
import 'section_header.dart';

class _PreviewItem {
  const _PreviewItem({this.assetPath, this.imageUrl, this.route = '/gallery'});

  final String? assetPath;
  final String? imageUrl;
  final String route;
}

class GalleryPreview extends StatefulWidget {
  const GalleryPreview({super.key});

  @override
  State<GalleryPreview> createState() => _GalleryPreviewState();
}

class _GalleryPreviewState extends State<GalleryPreview> {
  static const _columnLayouts = [
    [220.0, 170.0],
    [190.0, 230.0, 160.0],
    [210.0, 250.0],
    [200.0],
  ];

  List<_PreviewItem> _items = [
    for (final album in CmsService.galleryAlbums)
      _PreviewItem(assetPath: album.$2),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final albums = await GalleryService().fetchAlbums();
    final withCovers = [
      for (final album in albums)
        if (album.coverImageUrl != null && album.coverImageUrl!.isNotEmpty)
          _PreviewItem(
            imageUrl: album.coverImageUrl,
            route: '/gallery/${album.slug}',
          ),
    ];
    if (!mounted || withCovers.isEmpty) return;
    setState(() => _items = withCovers);
  }

  @override
  Widget build(BuildContext context) {
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
                _MasonryGallery(items: _items, layouts: _columnLayouts)
              else
                _MobileGallery(items: _items),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasonryGallery extends StatelessWidget {
  const _MasonryGallery({
    required this.items,
    required this.layouts,
  });

  final List<_PreviewItem> items;
  final List<List<double>> layouts;

  @override
  Widget build(BuildContext context) {
    final columns = <List<(_PreviewItem, double)>>[];
    var imageIndex = 0;

    for (final heights in layouts) {
      final columnItems = <(_PreviewItem, double)>[];
      for (final height in heights) {
        if (imageIndex >= items.length) break;
        columnItems.add((items[imageIndex], height));
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
                    item: columns[col][row].$1,
                    height: columns[col][row].$2,
                    onTap: () => context.go(columns[col][row].$1.route),
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
  const _MobileGallery({required this.items});

  final List<_PreviewItem> items;

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
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _GalleryImage(
          item: items[index],
          height: 180,
          onTap: () => context.go(items[index].route),
        );
      },
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({
    required this.item,
    required this.height,
    required this.onTap,
  });

  final _PreviewItem item;
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
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: AppColors.muted,
                    child: Icon(
                      Icons.photo_outlined,
                      color: AppColors.mutedText,
                    ),
                  ),
                )
              : SafeAssetImage(
                  assetPath: item.assetPath ?? '',
                  fit: BoxFit.cover,
                  expandToFill: true,
                ),
        ),
      ),
    );
  }
}
