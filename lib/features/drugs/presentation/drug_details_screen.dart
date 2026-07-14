import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/drugs_api_service.dart';

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
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _drug?.detailImageUrl ?? _drug?.headerImageUrl;

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
            return Center(
              child: Text(
                'No detail image available',
                style: GoogleFonts.inter(color: AppColors.mutedText),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fadeInDuration: const Duration(milliseconds: 150),
                imageBuilder: (context, imageProvider) {
                  // Stack sizes to the image; close stays inside the image border.
                  return FittedBox(
                    fit: BoxFit.contain,
                    child: Stack(
                      children: [
                        Image(
                          image: imageProvider,
                          filterQuality: FilterQuality.medium,
                        ),
                        Positioned(
                          top: 32,
                          right: 32,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _close,
                              behavior: HitTestBehavior.opaque,
                              child: const Icon(
                                Icons.close,
                                size: 64,
                                color: Colors.black,
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
                errorWidget: (_, _, _) => Center(
                  child: Text(
                    'Unable to load image',
                    style: GoogleFonts.inter(color: AppColors.mutedText),
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
