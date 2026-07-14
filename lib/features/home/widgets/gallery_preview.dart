import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/gallery_api_service.dart';
import 'section_header.dart';

/// Home gallery masonry — API-driven album covers from the gallery service.
class GalleryPreview extends StatefulWidget {
  const GalleryPreview({super.key});

  @override
  State<GalleryPreview> createState() => _GalleryPreviewState();
}

class _GalleryPreviewState extends State<GalleryPreview> {
  final _api = GalleryApiService();
  List<GalleryAlbum> _albums = [];
  bool _loading = true;

  static const _columnLayouts = [
    [280.0, 200.0],
    [280.0, 240.0],
    [280.0, 260.0],
    [280.0, 180.0],
  ];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await _api.fetchAlbums();
      if (!mounted) return;
      setState(() {
        _albums = albums.take(8).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 0),
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
                actionBesideTitle: true,
              ),
              const SizedBox(height: 32),
              if (_loading)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_albums.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Text(
                    'Gallery albums will appear here soon.',
                    style: GoogleFonts.inter(color: AppColors.bodyText),
                  ),
                )
              else if (width > 900)
                _MasonryGallery(albums: _albums, layouts: _columnLayouts)
              else
                _MobileGallery(albums: _albums),
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

  final List<GalleryAlbum> albums;
  final List<List<double>> layouts;

  @override
  Widget build(BuildContext context) {
    final columns = <List<(GalleryAlbum, double)>>[];
    var imageIndex = 0;

    for (final heights in layouts) {
      final columnItems = <(GalleryAlbum, double)>[];
      for (final height in heights) {
        if (imageIndex >= albums.length) break;
        columnItems.add((albums[imageIndex], height));
        imageIndex++;
      }
      if (columnItems.isNotEmpty) columns.add(columnItems);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var col = 0; col < columns.length; col++) ...[
          if (col > 0) const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var row = 0; row < columns[col].length; row++) ...[
                  if (row > 0) const SizedBox(height: 16),
                  _GalleryImage(
                    title: columns[col][row].$1.title,
                    imageUrl: columns[col][row].$1.coverImageUrl,
                    height: columns[col][row].$2,
                    onTap: () =>
                        context.go('/gallery/${columns[col][row].$1.slug}'),
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

  final List<GalleryAlbum> albums;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 420 ? 1 : 2;
    // Taller tiles so full vertical photos fit on phones.
    final aspectRatio = columns == 1 ? 0.75 : 0.8;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return _GalleryImage(
          title: album.title,
          imageUrl: album.coverImageUrl,
          onTap: () => context.go('/gallery/${album.slug}'),
        );
      },
    );
  }
}

class _GalleryImage extends StatefulWidget {
  const _GalleryImage({
    required this.title,
    required this.imageUrl,
    required this.onTap,
    this.height,
  });

  final String title;
  final String? imageUrl;
  final double? height;
  final VoidCallback onTap;

  @override
  State<_GalleryImage> createState() => _GalleryImageState();
}

class _GalleryImageState extends State<_GalleryImage> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _hovered = pressed),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.03 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  child: ColoredBox(
                    color: AppColors.muted,
                    child: widget.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.center,
                            errorWidget: (context, url, error) =>
                                const SizedBox.expand(),
                          )
                        : const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
