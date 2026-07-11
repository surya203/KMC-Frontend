import 'package:flutter/material.dart';

/// Shared responsive layout values for dashboard screens (iOS / Android / web).
class DashboardLayout {
  DashboardLayout._();

  static const compactBreakpoint = 700.0;
  static const narrowBreakpoint = 520.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < narrowBreakpoint;

  static EdgeInsets screenPadding(BuildContext context) {
    final compact = isCompact(context);
    return EdgeInsets.fromLTRB(
      compact ? 16 : 24,
      compact ? 16 : 20,
      compact ? 16 : 24,
      compact ? 24 : 32,
    );
  }

  static double pageTitleSize(BuildContext context) =>
      isCompact(context) ? 28 : 36;

  static double cardPadding(BuildContext context) =>
      isCompact(context) ? 16 : 22;
}
