import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/gallery_api_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _api = GalleryApiService();
  List<GalleryAlbum> _albums = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final albums = await _api.fetchAlbums();
      if (!mounted) return;
      setState(() {
        _albums = albums;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        )
                      : _error != null
                          ? _ErrorState(message: _error!, onRetry: _loadAlbums)
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
                              itemCount: _albums.length,
                              itemBuilder: (context, index) {
                                final album = _albums[index];
                                return _GalleryAlbumCard(
                                  album: album,
                                  onTap: () =>
                                      context.go('/gallery/${album.slug}'),
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
  final _api = GalleryApiService();
  GalleryAlbumDetail? _album;
  List<GalleryMediaItem> _media = [];
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = false;
  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = false;
    });
    try {
      final album = await _api.fetchAlbumBySlug(widget.slug);
      final mediaPage = await _api.fetchAlbumMediaPage(
        widget.slug,
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _album = album;
        _media = mediaPage.items.isNotEmpty ? mediaPage.items : album.media;
        _page = mediaPage.page;
        _hasMore = mediaPage.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreMedia() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final mediaPage = await _api.fetchAlbumMediaPage(
        widget.slug,
        page: _page + 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _media = [..._media, ...mediaPage.items];
        _page = mediaPage.page;
        _hasMore = mediaPage.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _openLightbox(int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _GalleryLightbox(
        media: _media,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.of(context).size.width > 900 ? 3 : 2;

    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: TextButton.icon(
                    onPressed: () => context.go('/gallery'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('All albums'),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 72),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        )
                      : _error != null
                          ? _ErrorState(message: _error!, onRetry: _loadAlbum)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _album!.title,
                                  style: HeadingStyles.sectionPageTitle(context),
                                ),
                                if (_album!.description != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _album!.description!,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: AppColors.bodyText,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemCount: _media.length,
                                  itemBuilder: (context, index) {
                                    final item = _media[index];
                                    return InkWell(
                                      onTap: () => _openLightbox(index),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: AppColors.muted,
                                            child: const Icon(Icons.broken_image),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (_hasMore) ...[
                                  const SizedBox(height: 24),
                                  Center(
                                    child: _loadingMore
                                        ? const CircularProgressIndicator()
                                        : OutlinedButton(
                                            onPressed: _loadMoreMedia,
                                            child: const Text('Load more photos'),
                                          ),
                                  ),
                                ],
                              ],
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

class _GalleryAlbumCard extends StatelessWidget {
  const _GalleryAlbumCard({required this.album, required this.onTap});

  final GalleryAlbum album;
  final VoidCallback onTap;

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
            if (album.coverImageUrl != null)
              CachedNetworkImage(
                imageUrl: album.coverImageUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: AppColors.muted,
                ),
              )
            else
              Container(color: AppColors.muted),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    if (album.mediaCount > 0)
                      Text(
                        '${album.mediaCount} photos',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryLightbox extends StatefulWidget {
  const _GalleryLightbox({
    required this.media,
    required this.initialIndex,
  });

  final List<GalleryMediaItem> media;
  final int initialIndex;

  @override
  State<_GalleryLightbox> createState() => _GalleryLightboxState();
}

class _GalleryLightboxState extends State<_GalleryLightbox> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.media[_index];
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              final media = widget.media[index];
              return InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: media.imageUrl,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
          if (item.caption != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                item.caption!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, style: GoogleFonts.inter(color: AppColors.bodyText)),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
