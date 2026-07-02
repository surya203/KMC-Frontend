import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Typography aligned with the Lovable reference site.
class HeadingStyles {
  HeadingStyles._();

  static TextStyle eyebrow = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.4,
    color: AppColors.secondary,
  );

  static TextStyle pageHeroTitle(BuildContext context, {bool dark = false}) {
    final width = MediaQuery.sizeOf(context).width;
    final size = width > 900 ? 52.0 : width > 600 ? 42.0 : 34.0;

    return GoogleFonts.fraunces(
      fontSize: size,
      height: 1.12,
      fontWeight: FontWeight.w600,
      color: dark ? Colors.white : AppColors.heading,
    );
  }

  static TextStyle sectionPageTitle(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = width > 900 ? 36.0 : 30.0;

    return GoogleFonts.fraunces(
      fontSize: size,
      height: 1.15,
      fontWeight: FontWeight.w600,
      color: AppColors.heading,
    );
  }

  static TextStyle contentColumnHeading = GoogleFonts.fraunces(
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
  );

  static TextStyle pageSubtitle({bool dark = false}) => GoogleFonts.inter(
        fontSize: 17,
        height: 1.75,
        color: dark ? Colors.white.withValues(alpha: 0.78) : AppColors.bodyText,
      );

  /// Builds a page hero title with optional italic tail (Lovable pattern).
  static Widget pageHeroTitleWidget(
    BuildContext context, {
    required String regular,
    String? italic,
    bool dark = false,
  }) {
    final base = pageHeroTitle(context, dark: dark);

    if (italic == null || italic.isEmpty) {
      return Text(regular, style: base);
    }

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: regular),
          TextSpan(
            text: italic,
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// Section title with optional italic phrase (home + inner pages).
  static Widget sectionTitleWidget(
    BuildContext context, {
    required String regular,
    String? italic,
    String? suffix,
    bool center = true,
  }) {
    final base = sectionPageTitle(context);

    return RichText(
      textAlign: center ? TextAlign.center : TextAlign.start,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: regular),
          if (italic != null)
            TextSpan(
              text: italic,
              style: base.copyWith(fontStyle: FontStyle.italic),
            ),
          if (suffix != null) TextSpan(text: suffix),
        ],
      ),
    );
  }
}
