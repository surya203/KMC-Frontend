import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/role_utils.dart';
import '../constants/app_colors.dart';
import 'drug_header_store.dart';

/// Header drug card sized to match the profile avatar row (~36px tall).
/// Admin → staff console drugs page; other users → dedicated detail image page.
class DrugsHeaderCard extends StatefulWidget {
  const DrugsHeaderCard({super.key});

  @override
  State<DrugsHeaderCard> createState() => _DrugsHeaderCardState();
}

class _DrugsHeaderCardState extends State<DrugsHeaderCard> {
  final _store = DrugHeaderStore.instance;

  static const double _height = 32;
  static const double _width = 104;

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

  void _onTap() {
    if (canManageDrugs(currentUserRole)) {
      context.go('/admin/drugs');
      return;
    }
    final card = _store.card;
    if (card == null) return;
    // Push so Close (X) can pop back to the page the user was on
    // (e.g. Payments / Membership), instead of replacing history with go().
    context.push('/dashboard/drugs/${card.id}');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _store.headerImageUrl;
    final card = _store.card;
    final canTap = canManageDrugs(currentUserRole) || card != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? _onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.5),
            child: ColoredBox(
              color: Colors.white,
              child: _store.loading && imageUrl == null
                  ? const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: _width,
                          height: _height,
                          fit: BoxFit.fill,
                          fadeInDuration: Duration.zero,
                          placeholder: (_, _) => const ColoredBox(
                            color: Colors.white,
                            child: Center(
                              child: Icon(
                                Icons.medication_outlined,
                                size: 18,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          const Icon(
            Icons.image_outlined,
            size: 16,
            color: AppColors.mutedText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Drug',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedText,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
