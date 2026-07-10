import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/gallery_api_service.dart';

class DashboardGalleryAlbumScreen extends StatefulWidget {
  const DashboardGalleryAlbumScreen({super.key, required this.slug});

  final String slug;

  @override
  State<DashboardGalleryAlbumScreen> createState() =>
      _DashboardGalleryAlbumScreenState();
}

class _DashboardGalleryAlbumScreenState extends State<DashboardGalleryAlbumScreen> {
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

  @override
  void didUpdateWidget(covariant DashboardGalleryAlbumScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _loadAlbum();
    }
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _openLightbox(int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _AlbumLightbox(
        media: _media,
        initialIndex: initialIndex,
      ),
    );
  }

  int _columnCount(double width) => width > 900 ? 3 : 2;

  @override
  Widget build(BuildContext context) {
    final columns = _columnCount(MediaQuery.sizeOf(context).width);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
                  ? _ErrorBanner(message: _error!, onRetry: _loadAlbum)
                  : _buildContent(columns),
        ),
      ),
    );
  }

  Widget _buildContent(int columns) {
    final album = _album!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/my-gallery'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to gallery'),
        ),
        const SizedBox(height: 8),
        Text(
          album.title,
          style: GoogleFonts.fraunces(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        if (album.description != null) ...[
          const SizedBox(height: 6),
          Text(
            album.description!,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.bodyText,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (_media.isEmpty)
          Text(
            'No photos in this album yet.',
            style: GoogleFonts.inter(color: AppColors.bodyText),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _media.length,
            itemBuilder: (context, index) {
              final item = _media[index];
              return Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openLightbox(index),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
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
    );
  }
}

class _AlbumLightbox extends StatefulWidget {
  const _AlbumLightbox({
    required this.media,
    required this.initialIndex,
  });

  final List<GalleryMediaItem> media;
  final int initialIndex;

  @override
  State<_AlbumLightbox> createState() => _AlbumLightboxState();
}

class _AlbumLightboxState extends State<_AlbumLightbox> {
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: GoogleFonts.inter(color: AppColors.bodyText)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
