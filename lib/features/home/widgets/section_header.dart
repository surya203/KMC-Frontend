import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/hover_link.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    this.eyebrow,
    this.title,
    this.titleWidget,
    this.regularTitle,
    this.italicTitle,
    this.titleSuffix,
    this.subtitle,
    this.center = true,
    this.actionLabel,
    this.onAction,
    this.actionBesideTitle = false,
  });

  final String? eyebrow;
  final String? title;
  final Widget? titleWidget;
  final String? regularTitle;
  final String? italicTitle;
  final String? titleSuffix;
  final String? subtitle;
  final bool center;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionBesideTitle;

  @override
  Widget build(BuildContext context) {
    Widget? heading;
    if (titleWidget != null) {
      heading = titleWidget;
    } else if (regularTitle != null) {
      heading = HeadingStyles.sectionTitleWidget(
        context,
        regular: regularTitle!,
        italic: italicTitle,
        suffix: titleSuffix,
        center: center,
      );
    } else if (title != null) {
      heading = Text(
        title!,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: HeadingStyles.sectionPageTitle(context),
      );
    }

    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (eyebrow != null &&
            !(actionBesideTitle && actionLabel != null && onAction != null))
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: center ? WrapAlignment.center : WrapAlignment.start,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!.toUpperCase(),
                  textAlign: center ? TextAlign.center : TextAlign.start,
                  style: HeadingStyles.eyebrow,
                ),
              if (actionLabel != null && onAction != null)
                HoverLink(
                  label: '$actionLabel →',
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  onTap: onAction!,
                ),
            ],
          ),
        if (eyebrow != null &&
            !(actionBesideTitle && actionLabel != null && onAction != null))
          const SizedBox(height: 14),
        if (actionBesideTitle && actionLabel != null && onAction != null) ...[
          if (eyebrow != null)
            Text(
              eyebrow!.toUpperCase(),
              style: HeadingStyles.eyebrow,
            ),
          if (eyebrow != null) const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading ?? const SizedBox.shrink()),
              HoverLink(
                label: '$actionLabel →',
                fontSize: 14,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                onTap: onAction!,
              ),
            ],
          ),
        ] else if (heading != null)
          heading,
        if (subtitle != null) ...[
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              subtitle!,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: GoogleFonts.inter(
                fontSize: 17,
                height: 1.7,
                color: AppColors.bodyText,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// @deprecated Use [HeadingStyles.sectionTitleWidget] or SectionHeader params.
Widget sectionTitleRich({
  required List<InlineSpan> spans,
  bool center = true,
}) {
  return Builder(
    builder: (context) {
      final base = HeadingStyles.sectionPageTitle(context);
      return RichText(
        textAlign: center ? TextAlign.center : TextAlign.start,
        text: TextSpan(style: base, children: spans),
      );
    },
  );
}
