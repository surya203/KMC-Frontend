import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/drugs_api_service.dart';

bool _looksLikeImageUrl(String url) {
  final path = url.toLowerCase().split('?').first;
  return path.endsWith('.png') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp');
}

/// Drug detail image shown inside the member dashboard shell.
class DrugDetailsScreen extends StatefulWidget {
  const DrugDetailsScreen({super.key, required this.drugId});

  final String drugId;

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen> {
  final _api = DrugsApiService();
  DrugItem? _drug;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final drug = await _api.fetchPublishedDrug(widget.drugId);
      if (!mounted) return;

      final link = drug.detailLinkUrl?.trim();
      final detailImage = drug.detailImageUrl?.trim();
      final hasDetailImage = detailImage != null && detailImage.isNotEmpty;
      final linkIsImage = link != null &&
          link.isNotEmpty &&
          _looksLikeImageUrl(link);

      // Link-only (no uploaded details image): open site and leave — no extra page.
      if (link != null &&
          link.isNotEmpty &&
          !hasDetailImage &&
          !linkIsImage) {
        final uri = Uri.tryParse(link);
        if (uri != null) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
        }
        if (!mounted) return;
        _close();
        return;
      }

      setState(() {
        _drug = drug;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        _loading = false;
      });
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/drugs/')) {
      context.go('/');
      return;
    }
    context.go('/dashboard');
  }

  String? get _linkUrl {
    final link = _drug?.detailLinkUrl?.trim();
    if (link == null || link.isEmpty) return null;
    return link;
  }

  /// Only a real details image (uploaded or image URL) — never header fallback.
  String? get _displayImageUrl {
    final detail = _drug?.detailImageUrl?.trim();
    if (detail != null && detail.isNotEmpty) return detail;
    final link = _linkUrl;
    if (link != null && _looksLikeImageUrl(link)) return link;
    return null;
  }

  bool get _hasOpenableLink => _linkUrl != null;

  Future<void> _openLink() async {
    final raw = _linkUrl;
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _displayImageUrl;
    final hasLink = _hasOpenableLink;

    if (_loading) {
      return const ColoredBox(
        color: Color(0xFFF7F7F4),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: const Color(0xFFF7F7F4),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.bodyText),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (imageUrl == null || imageUrl.isEmpty) {
            return Stack(
              children: [
                Center(
                  child: Text(
                    'No detail image available',
                    style: GoogleFonts.inter(
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: _close,
                    icon: const Icon(
                      Icons.close,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fadeInDuration: const Duration(milliseconds: 150),
                  fit: BoxFit.contain,
                  imageBuilder: (context, imageProvider) {
                    // Close stays on the image corner (scales with the poster).
                    return FittedBox(
                      fit: BoxFit.contain,
                      child: Stack(
                        children: [
                          MouseRegion(
                            cursor: hasLink
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.basic,
                            child: GestureDetector(
                              onTap: hasLink ? _openLink : null,
                              child: Image(
                                image: imageProvider,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 28,
                            right: 28,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _close,
                                behavior: HitTestBehavior.opaque,
                                child: const Icon(
                                  Icons.close,
                                  size: 64,
                                  color: Colors.black,
                                  weight: 700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, _, _) => Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Unable to load image',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: AppColors.mutedText,
                                  fontSize: 16,
                                ),
                              ),
                              if (hasLink) ...[
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _openLink,
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Open link'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: _close,
                          icon: const Icon(
                            Icons.close,
                            size: 32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
