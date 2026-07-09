import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/hover_link.dart';
import '../../../core/widgets/safe_asset_image.dart';

/// Site footer — matches Lovable client reference (full-width navy block).
class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.footerBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 1000;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _brandColumn()),
                          const SizedBox(width: 28),
                          Expanded(child: _exploreColumn(context)),
                          const SizedBox(width: 28),
                          Expanded(child: _officeColumn()),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _brandColumn(),
                        const SizedBox(height: 20),
                        _exploreColumn(context),
                        const SizedBox(height: 20),
                        _officeColumn(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Container(height: 1, color: Colors.white12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    const copyright = Text(
                      '© 2026 KMC Alumni Association. All rights reserved.',
                      style: TextStyle(color: Color(0xFFB8C2D2), fontSize: 13),
                    );
                    const tagline = Text(
                      'Official Platform · Estd. 1959',
                      style: TextStyle(color: Color(0xFFB8C2D2), fontSize: 13),
                    );

                    if (isWide) {
                      return const Row(
                        children: [copyright, Spacer(), tagline],
                      );
                    }

                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copyright,
                        SizedBox(height: 8),
                        tagline,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeAssetImage(
              assetPath: AppAssets.logo,
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'KMC Alumni Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'ESTD. 1959 · WARANGAL',
                    style: TextStyle(
                      color: Color(0xFFB7C0D1),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'The official alumni engagement platform for Kakatiya Medical College — '
          'uniting alumni batches, doctors, researchers, practicing doctors, '
          'clinical researchers, policy makers and pharmaceutical industry advisors across the world.',
          style: TextStyle(
            color: Color(0xFFD8DEE8),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _exploreColumn(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXPLORE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 12),
        _FooterLink(label: 'About', path: '/about', currentPath: currentPath),
        _FooterLink(label: 'Directory', path: '/directory', currentPath: currentPath),
        _FooterLink(label: 'Events', path: '/events', currentPath: currentPath),
        _FooterLink(label: 'Gallery', path: '/gallery', currentPath: currentPath),
        _FooterLink(label: 'MY KMC', path: '/membership', currentPath: currentPath),
      ],
    );
  }

  Widget _officeColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'OFFICE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
        SizedBox(height: 12),
        FooterInfo('Kakatiya Medical College'),
        SizedBox(height: 6),
        FooterInfo('Rangampet, Warangal — 506007'),
        SizedBox(height: 6),
        FooterInfo('alumni@kmc.edu.in'),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.path,
    required this.currentPath,
  });

  final String label;
  final String path;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return FooterHoverLink(
      label: label,
      isActive: isNavRouteActive(currentPath, path),
      onTap: () => context.go(path),
    );
  }
}

class FooterInfo extends StatelessWidget {
  const FooterInfo(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD7DEE8),
        fontSize: 13,
        height: 1.5,
      ),
    );
  }
}
