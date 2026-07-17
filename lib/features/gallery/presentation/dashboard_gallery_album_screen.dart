import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/network/gallery_api_service.dart';
import '../../../core/utils/download_file.dart';
import '../../../core/utils/open_external_url.dart';
import '../widgets/gallery_album_dialogs.dart';

class DashboardGalleryAlbumScreen extends StatefulWidget {
  const DashboardGalleryAlbumScreen({
    super.key,
    required this.slug,
    this.basePath = '/my-gallery',
    this.allowDriveLinks = false,
  });

  final String slug;

  /// Route prefix for back navigation (`/my-gallery` or `/admin/gallery`).
  final String basePath;

  /// When true (member gallery), users can add/edit/delete Google Drive links.
  final bool allowDriveLinks;

  @override
  State<DashboardGalleryAlbumScreen> createState() =>
      _DashboardGalleryAlbumScreenState();
}

class _DashboardGalleryAlbumScreenState
    extends State<DashboardGalleryAlbumScreen> {
  final _api = GalleryApiService();
  GalleryAlbumDetail? _album;
  List<GalleryMediaItem> _media = [];
  String? _error;
  bool _loading = true;
  bool _busy = false;
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
        _error = friendlyApiError(e);
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

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addDriveLink() async {
    final album = _album;
    if (album == null) return;

    final values = await showDriveLinkDialog(context);
    if (values == null) return;

    await _runBusy(() async {
      await _api.addDriveLink(
        albumId: album.id,
        title: values.title,
        url: values.url,
        linkType: values.linkType,
      );
      await _loadAlbum();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drive link added.')),
      );
    });
  }

  Future<void> _editDriveLink(GalleryExternalLink link) async {
    final album = _album;
    if (album == null) return;

    final values = await showDriveLinkDialog(
      context,
      initialTitle: link.title,
      initialUrl: link.url,
      initialLinkType: link.linkType,
    );
    if (values == null) return;

    await _runBusy(() async {
      await _api.updateDriveLink(
        albumId: album.id,
        linkId: link.id,
        title: values.title,
        url: values.url,
        linkType: values.linkType,
      );
      await _loadAlbum();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drive link updated.')),
      );
    });
  }

  Future<void> _deleteDriveLink(GalleryExternalLink link) async {
    final album = _album;
    if (album == null) return;

    final confirmed = await confirmDelete(
      context,
      title: 'Remove Drive link',
      message: 'Remove "${link.title ?? 'this link'}" from the album?',
    );
    if (!confirmed) return;

    await _runBusy(() async {
      await _api.deleteDriveLink(albumId: album.id, linkId: link.id);
      await _loadAlbum();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drive link removed.')),
      );
    });
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

    return Stack(
      children: [
        SingleChildScrollView(
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
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(int columns) {
    final album = _album!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go(widget.basePath),
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
        const SizedBox(height: 28),
        Text(
          'Photos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'View and download photos uploaded by admin.',
          style: GoogleFonts.inter(color: AppColors.bodyText, fontSize: 13),
        ),
        const SizedBox(height: 16),
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
                    fit: BoxFit.contain,
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
        if (widget.allowDriveLinks) ...[
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Google Drive links',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _busy ? null : _addDriveLink,
                icon: const Icon(Icons.add_link, size: 18),
                label: const Text('Add link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add folder or album links from Google Drive to share with others.',
            style: GoogleFonts.inter(color: AppColors.bodyText, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (album.externalLinks.isEmpty)
            Text(
              'No Drive links yet.',
              style: GoogleFonts.inter(color: AppColors.bodyText),
            )
          else
            ...album.externalLinks.map(_buildDriveLinkTile),
        ],
      ],
    );
  }

  Widget _buildDriveLinkTile(GalleryExternalLink link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            link.linkType == 'drive_album'
                ? Icons.photo_album_outlined
                : Icons.folder_outlined,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.title ?? 'Google Drive',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
                Text(
                  link.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Open',
            onPressed: () => openExternalUrl(link.url),
            icon: const Icon(Icons.open_in_new),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: _busy ? null : () => _editDriveLink(link),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: _busy ? null : () => _deleteDriveLink(link),
            icon: Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
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
  bool _downloading = false;

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

  Future<void> _downloadCurrent() async {
    final item = widget.media[_index];
    setState(() => _downloading = true);
    final ok = await downloadFromUrl(
      item.imageUrl,
      filename: galleryDownloadFilename(item.imageUrl, caption: item.caption),
    );
    if (!mounted) return;
    setState(() => _downloading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Photo downloaded.' : 'Could not download photo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Download',
                  onPressed: _downloading ? null : _downloadCurrent,
                  icon: _downloading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_outlined,
                          color: Colors.white, size: 26),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ],
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
