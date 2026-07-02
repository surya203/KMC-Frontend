import 'package:flutter/material.dart';

import '../theme/heading_styles.dart';

class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow = 'MY KMC',
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(eyebrow.toUpperCase(), style: HeadingStyles.eyebrow),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: HeadingStyles.sectionPageTitle(context).copyWith(fontSize: 40),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: HeadingStyles.pageSubtitle(),
          ),
        ],
      ],
    );
  }
}
