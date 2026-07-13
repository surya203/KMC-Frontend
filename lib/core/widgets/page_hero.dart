import 'package:flutter/material.dart';

import '../theme/heading_styles.dart';
import '../constants/app_colors.dart';
import 'public_layout.dart';

class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.dark = false,
    this.showBackButton = true,
  });

  final String eyebrow;
  final Widget title;
  final String? subtitle;
  final bool dark;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: dark ? AppColors.primary : AppColors.background,
      padding: EdgeInsets.fromLTRB(
        24,
        dark ? 64 : 56,
        24,
        dark ? 64 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBackButton) ...[
                PublicBackIcon(dark: dark),
                SizedBox(height: dark ? 8 : 4),
              ],
              Text(eyebrow.toUpperCase(), style: HeadingStyles.eyebrow),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: title,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Text(
                    subtitle!,
                    style: HeadingStyles.pageSubtitle(dark: dark),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TwoColumnSection extends StatelessWidget {
  const TwoColumnSection({
    super.key,
    required this.heading,
    required this.child,
    this.showDivider = true,
  });

  final String heading;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260,
                    child: Text(
                      heading,
                      style: HeadingStyles.contentColumnHeading,
                    ),
                  ),
                  const SizedBox(width: 56),
                  Expanded(child: child),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: HeadingStyles.contentColumnHeading),
                const SizedBox(height: 20),
                child,
              ],
            );
          },
        ),
        if (showDivider) ...[
          const SizedBox(height: 48),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 48),
        ],
      ],
    );
  }
}
