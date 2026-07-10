import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/gallery_api_service.dart';
import '../../../core/utils/download_file.dart';
import '../../../core/utils/open_external_url.dart';
import '../widgets/gallery_album_dialogs.dart';

class DashboardGalleryManageScreen extends StatefulWidget {
  const DashboardGalleryManageScreen({super.key, required this.slug});

  final String slug;

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

  Future<void> _uploadPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    await _runBusy(() async {
      await _api.uploadAlbumMedia(
        albumId: _album!.id,
        files: result.files,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos uploaded.')),
      );
    });
  }

  Future<void> _editAlbum() async {
    final album = _album;
    if (album == null) return;

    final values = await showEditAlbumDialog(
      context,
      initialTitle: album.title,
      initialDescription: album.description,
    );
    if (values == null) return;

    await _runBusy(() async {
      await _api.updateAlbum(
        albumId: album.id,
        title: values.title,
        description: values.description,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album updated.')),
      );
    });
  }

  Future<void> _deletePhoto(GalleryMediaItem item) async {
    final album = _album;
    if (album == null) return;

    final confirmed = await confirmDelete(
      context,
      title: 'Delete photo',
      message: 'Remove this photo from the album?',
    );
    if (!confirmed) return;

    await _runBusy(() async {
      await _api.deleteMedia(albumId: album.id, mediaId: item.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted.')),
      );
    });
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
      await _load();
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
      await _load();
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
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drive link removed.')),
      );
    });
  }

  Future<void> _downloadPhoto(GalleryMediaItem item) async {
    final ok = await downloadFromUrl(
      item.imageUrl,
      filename: galleryDownloadFilename(item.imageUrl, caption: item.caption),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Please try again.')),
      );
    }
  }

  void _openLightbox(int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _ManageLightbox(
        media: _media,
        initialIndex: initialIndex,
        onDownload: _downloadPhoto,
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
                      ? _ErrorBanner(message: _error!, onRetry: _load)
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
          onPressed: () => context.go('/my-gallery'),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/gallery/${album.slug}'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View album'),
                ),
                OutlinedButton.icon(
                  onPressed: _editAlbum,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadPhotos,
                  icon: const Icon(Icons.upload_outlined, size: 18),
                  label: const Text('Upload photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Photos (${album.mediaCount})',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 12),
        if (_media.isEmpty)
          Text(
            'No photos yet. Upload images to get started.',
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
              return Stack(
                fit: StackFit.expand,
                children: [
                  Material(
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
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconAction(
                          icon: Icons.download_outlined,
                          tooltip: 'Download',
                          onPressed: () => _downloadPhoto(item),
                        ),
                        const SizedBox(width: 4),
                        _IconAction(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          onPressed: () => _deletePhoto(item),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        if (_hasMore) ...[
          const SizedBox(height: 20),
          Center(
            child: _loadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: _loadMoreMedia,
                    child: const Text('Load more photos'),
                  ),
          ),
        ],
        const SizedBox(height: 32),
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
            OutlinedButton.icon(
              onPressed: _addDriveLink,
              icon: const Icon(Icons.add_link, size: 18),
              label: const Text('Add link'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (album.externalLinks.isEmpty)
          Text(
            'No Drive links yet. Add a folder or album link from Google Drive.',
            style: GoogleFonts.inter(color: AppColors.bodyText),
          )
        else
          ...album.externalLinks.map(_buildDriveLinkTile),
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
            onPressed: () => _editDriveLink(link),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _deleteDriveLink(link),
            icon: Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _ManageLightbox extends StatefulWidget {
  const _ManageLightbox({
    required this.media,
    required this.initialIndex,
    required this.onDownload,
  });

  final List<GalleryMediaItem> media;
  final int initialIndex;
  final Future<void> Function(GalleryMediaItem item) onDownload;

  @override
  State<_ManageLightbox> createState() => _ManageLightboxState();
}

class _ManageLightboxState extends State<_ManageLightbox> {
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
            child: Row(
              children: [
                IconButton(
                  onPressed: () => widget.onDownload(item),
                  icon: const Icon(Icons.download_outlined,
                      color: Colors.white, size: 24),
                  tooltip: 'Download',
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ],
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
