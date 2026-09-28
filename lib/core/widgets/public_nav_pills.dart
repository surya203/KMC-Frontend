import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/public_nav_items.dart';
import '../router/app_back_navigation.dart';
import 'hover_link.dart';

/// Home / About / MY KMC / Events / Gallery — same destinations as the website.
class PublicNavPills extends StatelessWidget {
  const PublicNavPills({
    super.key,
    required this.currentPath,
    this.dark = false,
    this.compact = true,
  });

  final String currentPath;
  final bool dark;
  final bool compact;

  static const height = 48.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Row(
            children: [
              for (var i = 0; i < publicNavItems.length; i++) ...[
                if (i > 0) SizedBox(width: compact ? 8 : 10),
                _PublicNavPill(
                  label: publicNavItems[i].label,
                  path: publicNavItems[i].path,
                  active: isNavRouteActive(
                    currentPath,
                    publicNavItems[i].path,
                  ),
                  dark: dark,
                  compact: compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicNavPill extends StatelessWidget {
  const _PublicNavPill({
    required this.label,
    required this.path,
    required this.active,
    required this.dark,
    required this.compact,
  });

  final String label;
  final String path;
  final bool active;
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color border;
    final Color foreground;

    if (dark) {
      background = active
          ? Colors.white
          : Colors.white.withValues(alpha: 0.14);
      border = Colors.white.withValues(alpha: active ? 0.9 : 0.45);
      foreground = active ? AppColors.primary : Colors.white;
    } else {
      background = active ? AppColors.primary : Colors.white;
      border = active ? AppColors.primary : AppColors.border;
      foreground = active ? Colors.white : AppColors.bodyText;
    }

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => navigateAppPath(context, path),
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 8 : 10,
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
