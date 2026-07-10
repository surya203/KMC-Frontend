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
    _ensureUserLoaded();
    _loadAlbums();
  }

  Future<void> _ensureUserLoaded() async {
    if (!AuthSession.instance.isAuthenticated) return;
    if (AuthSession.instance.currentUser != null) return;
    try {
      await AuthSession.instance.authService.fetchMe();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  bool get _isSignedIn => AuthSession.instance.isAuthenticated;

  void _handleAlbumAction(String action, GalleryAlbum album) {
    switch (action) {
      case 'view':
      case 'manage':
        context.go('/my-gallery/manage/${album.slug}');
      case 'edit':
        _editAlbum(album);
      case 'delete':
        _deleteAlbum(album);
    }
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
                        return _GalleryAlbumCard(
                          album: album,
                          showMenu: _isSignedIn,
                          onTap: () => context.go('/my-gallery/manage/${album.slug}'),
                          onMenuAction: (action) =>
                              _handleAlbumAction(action, album),
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
    this.showMenu = false,
    this.onMenuAction,
  });

  final GalleryAlbum album;
  final VoidCallback onTap;
  final bool showMenu;
  final void Function(String action)? onMenuAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
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
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showMenu && onMenuAction != null)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  splashRadius: 16,
                  constraints: const BoxConstraints(minWidth: 108, maxWidth: 120),
                  tooltip: 'Album options',
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                  color: AppColors.card,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  offset: const Offset(0, 24),
                  onSelected: onMenuAction,
                  itemBuilder: (context) => [
                    _albumMenuItem(
                      value: 'view',
                      icon: Icons.visibility_outlined,
                      label: 'View',
                    ),
                    _albumMenuItem(
                      value: 'manage',
                      icon: Icons.settings_outlined,
                      label: 'Manage',
                    ),
                    _albumMenuItem(
                      value: 'edit',
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                    ),
                    _albumMenuItem(
                      value: 'delete',
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

PopupMenuItem<String> _albumMenuItem({
  required String value,
  required IconData icon,
  required String label,
  bool isDestructive = false,
}) {
  final color = isDestructive ? AppColors.error : AppColors.heading;
  return PopupMenuItem<String>(
    value: value,
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
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
