import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/cms_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../../core/widgets/safe_asset_image.dart';
import '../../home/widgets/footer_section.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final albums = CmsService.galleryAlbums;
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
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
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

class _GalleryAlbumCard extends StatelessWidget {
  const _GalleryAlbumCard({
    required this.title,
    required this.imagePath,
  });

  final String title;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeAssetImage(
            assetPath: imagePath,
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
    );
  }
}
