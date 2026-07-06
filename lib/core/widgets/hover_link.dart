import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Text link with gold hover + touch feedback — nav, footer, section actions.
class HoverLink extends StatefulWidget {
  const HoverLink({
    super.key,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isActive || _hovered || _pressed;
    final color = highlighted ? AppColors.secondary : AppColors.bodyText;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          hoverColor: AppColors.secondary.withValues(alpha: 0.08),
          splashColor: AppColors.secondary.withValues(alpha: 0.14),
          highlightColor: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: widget.padding,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              style: GoogleFonts.inter(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer link on dark background — light grey default, gold on hover/touch.
class FooterHoverLink extends StatefulWidget {
  const FooterHoverLink({
    super.key,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  State<FooterHoverLink> createState() => _FooterHoverLinkState();
}

class _FooterHoverLinkState extends State<FooterHoverLink> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isActive || _hovered || _pressed;
    final color =
        highlighted ? AppColors.secondary : const Color(0xFFD7DEE8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            hoverColor: AppColors.secondary.withValues(alpha: 0.12),
            splashColor: AppColors.secondary.withValues(alpha: 0.18),
            highlightColor: AppColors.secondary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                child: Text(widget.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns true when [path] matches the current route (incl. nested paths).
bool isNavRouteActive(String current, String path) {
  if (path == '/') return current == '/';
  if (path == '/auth') {
    return current == '/auth';
  }
  if (path == '/membership') {
    return current == '/membership';
  }
  return current == path || current.startsWith('$path/');
}
