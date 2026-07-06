import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Thin pill scrollbar — matches Lovable / Chrome reference (track + thumb + arrows on web).
class KmcScrollBehavior extends MaterialScrollBehavior {
  const KmcScrollBehavior();

  static const _thumbColor = Color(0xFF8E95A3);
  static const _trackColor = Color(0xFFF2F0EB);

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return RawScrollbar(
      controller: details.controller,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: kIsWeb ? 11 : 8,
      radius: const Radius.circular(100),
      minThumbLength: 48,
      thumbColor: _thumbColor,
      trackColor: _trackColor,
      trackBorderColor: Colors.transparent,
      crossAxisMargin: kIsWeb ? 3 : 2,
      mainAxisMargin: kIsWeb ? 14 : 6,
      interactive: true,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

/// Shared scrollbar theme for [ThemeData.scrollbarTheme].
class KmcScrollbarTheme {
  KmcScrollbarTheme._();

  static ScrollbarThemeData get data => const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(true),
        trackVisibility: WidgetStatePropertyAll(true),
        thickness: WidgetStatePropertyAll(11),
        radius: Radius.circular(100),
        minThumbLength: 48,
        thumbColor: WidgetStatePropertyAll(Color(0xFF8E95A3)),
        trackColor: WidgetStatePropertyAll(Color(0xFFF2F0EB)),
        crossAxisMargin: 3,
        mainAxisMargin: 14,
        interactive: true,
      );
}
