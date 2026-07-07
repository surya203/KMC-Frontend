import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/cms_service.dart';
import '../../../core/network/gallery_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/cover_image.dart';
import '../../../core/widgets/media_lightbox.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../../core/widgets/safe_asset_image.dart';
import '../../home/widgets/footer_section.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _service = GalleryService();
  List<GalleryAlbum> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final albums = await _service.fetchAlbums();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fallback = CmsService.galleryAlbums;
    final columns = MediaQuery.of(context).size.width > 1100
        ? 4
        : MediaQuery.of(context).size.width > 700
            ? 3
            : 2;

    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            PageHero(
              eyebrow: 'Gallery',
              title: HeadingStyles.pageHeroTitleWidget(
                context,
                regular: 'Decades of ',
                italic: 'memories.',
              ),
              subtitle:
                  'Reunions, convocations, ceremonies, and the quiet everyday '
                  'moments that shaped a campus.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 72),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: _albums.isNotEmpty
                              ? _albums.length
                              : fallback.length,
                          itemBuilder: (context, index) {
                            if (_albums.isNotEmpty) {
                              final album = _albums[index];
                              return _GalleryAlbumCard(
                                title: album.title,
                                imageUrl: album.coverImageUrl,
                                onTap: () =>
                                    context.go('/gallery/${album.slug}'),
                              );
                            }
                            final album = fallback[index];
                            return _GalleryAlbumCard(
                              title: album.$1,
                              imagePath: album.$2,
                            );
                          },
                        ),
                ),
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}

class GalleryAlbumScreen extends StatefulWidget {
  const GalleryAlbumScreen({super.key, required this.slug});

  final String slug;

  @override
  State<GalleryAlbumScreen> createState() => _GalleryAlbumScreenState();
}

class _GalleryAlbumScreenState extends State<GalleryAlbumScreen> {
  final _service = GalleryService();
  GalleryAlbumDetail? _album;
  List<GalleryMedia> _media = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final album = await _service.fetchAlbum(widget.slug);
      final media = await _service.fetchAlbumMedia(widget.slug);
      if (!mounted) return;
      setState(() {
        _album = album;
        _media = media.isNotEmpty ? media : album.media;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _album?.title ?? 'Gallery',
                        style: HeadingStyles.contentColumnHeading,
                      ),
                      if (_album?.description != null) ...[
                        const SizedBox(height: 8),
                        Text(_album!.description!),
                      ],
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _media.length,
                        itemBuilder: (context, index) {
                          final item = _media[index];
                          return Semantics(
                            label: item.caption ?? 'Gallery photo ${index + 1}',
                            button: true,
                            child: InkWell(
                              key: ValueKey('gallery-media-${item.id}'),
                              onTap: () => MediaLightbox.show(
                                context,
                                imageUrl: item.url,
                                caption: item.caption,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: item.url,
                                  fit: BoxFit.cover,
                                  height: 180,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _GalleryAlbumCard extends StatelessWidget {
  const _GalleryAlbumCard({
    required this.title,
    this.imageUrl,
    this.imagePath,
    this.onTap,
  });

  final String title;
  final String? imageUrl;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CoverImage(imageUrl: imageUrl, height: double.infinity)
            else
              SafeAssetImage(
                assetPath: imagePath!,
                fit: BoxFit.cover,
                expandToFill: true,
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
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
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
