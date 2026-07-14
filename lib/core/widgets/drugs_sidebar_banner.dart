import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'drug_header_store.dart';

/// Compact display-only drug image for sidebars (above Sign out).
/// Same horizontal width as the Sign out button; image fills the frame.
class DrugsSidebarBanner extends StatefulWidget {
  const DrugsSidebarBanner({super.key});

  @override
  State<DrugsSidebarBanner> createState() => _DrugsSidebarBannerState();
}

class _DrugsSidebarBannerState extends State<DrugsSidebarBanner> {
  final _store = DrugHeaderStore.instance;

  static const double _height = 44;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _store.ensureLoaded();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final url = _store.headerImageUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SizedBox(
        width: double.infinity,
        height: _height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: _store.loading && url == null
                ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : url != null && url.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: url,
                        width: double.infinity,
                        height: _height,
                        fit: BoxFit.fill,
                        alignment: Alignment.center,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, _) => const Center(
                          child: Icon(
                            Icons.medication_outlined,
                            color: Colors.black45,
                            size: 18,
                          ),
                        ),
                        errorWidget: (_, _, _) => _emptyState(),
                      )
                    : _emptyState(),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'No drug',
        style: GoogleFonts.inter(
          color: Colors.black45,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
