import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/safe_asset_image.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A2744),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _brandColumn()),
                      const SizedBox(width: 40),
                      Expanded(child: _exploreColumn(context)),
                      const SizedBox(width: 40),
                      Expanded(child: _officeColumn()),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _brandColumn(),
                    const SizedBox(height: 32),
                    _exploreColumn(context),
                    const SizedBox(height: 32),
                    _officeColumn(),
                  ],
                );
              },
            ),
          ),
          Container(height: 1, color: Colors.white12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final copyright = const Text(
                  '┬⌐ 2026 KMC Alumni Association. All rights reserved.',
                  style: TextStyle(color: Color(0xFFB8C2D2), fontSize: 15),
                );
                final tagline = const Text(
                  'Official Platform ΓÇó Estd. 1959',
                  style: TextStyle(color: Color(0xFFB8C2D2), fontSize: 15),
                );

                if (isWide) {
                  return Row(
                    children: [copyright, const Spacer(), tagline],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copyright,
                    const SizedBox(height: 8),
                    tagline,
                  ],
                );
              },
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
              width: 52,
              height: 52,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'KMC Alumni Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'ESTD. 1959 ΓÇó WARANGAL',
                    style: TextStyle(
                      color: Color(0xFFB7C0D1),
                      fontSize: 13,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'The official alumni engagement platform for Kakatiya Medical College ΓÇö '
          'connecting alumni, doctors, researchers, academicians and healthcare leaders across the globe.',
          style: TextStyle(
            color: Color(0xFFD8DEE8),
            fontSize: 16,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _exploreColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXPLORE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 26),
        _footerLink(context, 'About', '/about'),
        _footerLink(context, 'Events', '/events'),
        _footerLink(context, 'MY KMC', '/auth'),
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
        SizedBox(height: 26),
        FooterInfo('Kakatiya Medical College'),
        SizedBox(height: 10),
        FooterInfo('Rangampet,\nWarangal - 506007'),
        SizedBox(height: 10),
        FooterInfo('alumni@kmc.edu.in'),
      ],
    );
  }

  Widget _footerLink(BuildContext context, String title, String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go(path),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD7DEE8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
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
        fontSize: 16,
        height: 1.8,
      ),
    );
  }
}
