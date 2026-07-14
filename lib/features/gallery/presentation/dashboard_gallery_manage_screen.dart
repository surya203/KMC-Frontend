import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/gallery_api_service.dart';
import '../widgets/gallery_album_dialogs.dart';

/// Admin-only album photo manager: upload and delete photos (no external links).
class DashboardGalleryManageScreen extends StatefulWidget {
  const DashboardGalleryManageScreen({
    super.key,
    required this.slug,
    this.basePath = '/admin/gallery',
  });

  final String slug;

  /// Route prefix for back navigation (`/admin/gallery`).
  final String basePath;

  @override
  State<DashboardGalleryManageScreen> createState() =>
      _DashboardGalleryManageScreenState();
}

class _DashboardGalleryManageScreenState
    extends State<DashboardGalleryManageScreen> {
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
    _load();
  }

  Future<void> _load() async {
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

  Future<void> _loadMore() async {
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

  Future<void> _uploadPhotos() async {
    final album = _album;
    if (album == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    await _runBusy(() async {
      final uploaded = await _api.uploadAlbumMedia(
        albumId: album.id,
        files: result.files,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploaded.length == 1
                ? '1 photo uploaded.'
                : '${uploaded.length} photos uploaded.',
          ),
        ),
      );
    });
  }

  Future<void> _deletePhoto(GalleryMediaItem item) async {
    final album = _album;
    if (album == null) return;

    final confirmed = await confirmDelete(
      context,
      title: 'Delete photo',
      message: 'Remove this photo from the album? This cannot be undone.',
    );
    if (!confirmed) return;

    await _runBusy(() async {
      await _api.deleteMedia(
        albumId: album.id,
        mediaId: item.id,
        asAdmin: true,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted.')),
      );
    });
  }

  int _columnCount(double width) => width > 900 ? 4 : width > 600 ? 3 : 2;

  @override
  Widget build(BuildContext context) {
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
                      ? _ErrorBanner(message: _error!, onRetry: _load)
                      : _buildContent(),
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

  Widget _buildContent() {
    final album = _album!;
    final columns = _columnCount(MediaQuery.sizeOf(context).width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go(widget.basePath),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to gallery'),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 32,
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
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _busy ? null : _uploadPhotos,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text('Upload photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Photos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload images only. These photos appear in the public Gallery for members to view and download.',
          style: GoogleFonts.inter(color: AppColors.bodyText, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (_media.isEmpty)
          Text(
            'No photos yet. Upload images to this album.',
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
              childAspectRatio: 1,
            ),
            itemCount: _media.length,
            itemBuilder: (context, index) {
              final item = _media[index];
              return _PhotoTile(
                item: item,
                onDelete: () => _deletePhoto(item),
              );
            },
          ),
        if (_hasMore) ...[
          const SizedBox(height: 24),
          Center(
            child: _loadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: _loadMore,
                    child: const Text('Load more'),
                  ),
          ),
        ],
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.item, required this.onDelete});

  final GalleryMediaItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.muted,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.imageUrl,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: IconButton(
                tooltip: 'Delete photo',
                iconSize: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.white),
              ),
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
