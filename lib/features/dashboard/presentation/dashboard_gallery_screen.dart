import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/gallery_api_service.dart';
import '../../gallery/widgets/gallery_album_dialogs.dart';

class DashboardGalleryScreen extends StatefulWidget {
  const DashboardGalleryScreen({super.key});

  @override
  State<DashboardGalleryScreen> createState() => _DashboardGalleryScreenState();
}

class _DashboardGalleryScreenState extends State<DashboardGalleryScreen> {
  final _api = GalleryApiService();

  List<GalleryAlbum> _albums = [];
  String? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  String? get _currentUserId => AuthSession.instance.currentUser?.id;

  bool _isOwner(GalleryAlbum album) {
    final ownerId = album.createdBy;
    final userId = _currentUserId;
    return ownerId != null && userId != null && ownerId == userId;
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

  Future<void> _createAlbum() async {
    final values = await showCreateAlbumDialog(context);
    if (values == null) return;

    setState(() => _busy = true);
    try {
      final album = await _api.createAlbum(
        slug: values.slug,
        title: values.title,
        description: values.description,
      );
      if (!mounted) return;
      await _loadAlbums();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album created.')),
      );
      context.go('/my-gallery/manage/${album.slug}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editAlbum(GalleryAlbum album) async {
    final detail = await _api.fetchAlbumBySlug(album.slug);
    if (!mounted) return;

    final values = await showEditAlbumDialog(
      context,
      initialTitle: detail.title,
      initialDescription: detail.description,
    );
    if (values == null) return;

    setState(() => _busy = true);
    try {
      await _api.updateAlbum(
        albumId: album.id,
        title: values.title,
        description: values.description,
      );
      if (!mounted) return;
      await _loadAlbums();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAlbum(GalleryAlbum album) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete album',
      message:
          'Delete "${album.title}" and all its photos? This cannot be undone.',
    );
    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      await _api.deleteAlbum(album.id);
      if (!mounted) return;
      await _loadAlbums();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAlbumActions(GalleryAlbum album) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View album'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/my-gallery/manage/${album.slug}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Manage photos & Drive'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/my-gallery/manage/${album.slug}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit album'),
                onTap: () {
                  Navigator.pop(context);
                  _editAlbum(album);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete album', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAlbum(album);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width > 1100) return 4;
    if (width > 700) return 3;
    return 2;
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gallery',
                    style: GoogleFonts.fraunces(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Decades of memories from Kakatiya Medical College.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.bodyText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _createAlbum,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('Create album'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _ErrorBanner(message: _error!, onRetry: _loadAlbums)
                  else if (_albums.isEmpty)
                    Text(
                      'No albums yet. Create your first album to share memories.',
                      style: GoogleFonts.inter(color: AppColors.bodyText),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.92,
                      ),
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        final isOwner = _isOwner(album);
                        return _GalleryAlbumCard(
                          album: album,
                          isOwner: isOwner,
                          onTap: () => context.go('/my-gallery/manage/${album.slug}'),
                          onManage: isOwner
                              ? () => _showAlbumActions(album)
                              : null,
                        );
                      },
                    ),
                ],
              ),
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
}

class _GalleryAlbumCard extends StatelessWidget {
  const _GalleryAlbumCard({
    required this.album,
    required this.onTap,
    this.isOwner = false,
    this.onManage,
  });

  final GalleryAlbum album;
  final VoidCallback onTap;
  final bool isOwner;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
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
                errorWidget: (_, _, _) => Container(color: AppColors.muted),
              )
            else
              Container(color: AppColors.muted),
            if (isOwner && onManage != null)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: onManage,
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  tooltip: 'Manage album',
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Text(
                  album.title,
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
          Text(
            message,
            style: GoogleFonts.inter(color: AppColors.bodyText),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
