import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/gallery_api_service.dart';

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

  int _columnCount(double width) {
    if (width > 1100) return 4;
    if (width > 700) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _columnCount(MediaQuery.sizeOf(context).width);

    return SingleChildScrollView(
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
                    'No albums yet. Check back soon.',
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
                        onTap: () => context.go('/gallery/${album.slug}'),
                      );
                    },
                  ),
              ],
            ),
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
