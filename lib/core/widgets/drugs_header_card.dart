import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/role_utils.dart';
import '../constants/app_colors.dart';
import 'drug_header_store.dart';

/// Header drug card sized to match the profile avatar row (~36px tall).
/// Admin → staff console drugs page.
/// Members → open link URL if set, otherwise drug details image page.
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
    // Always re-fetch on mount so auth/public pages don't stick on a failed load.
    _store.refresh(force: true);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onTap() async {
    if (canManageDrugs(currentUserRole)) {
      context.go('/admin/drugs');
      return;
    }

    // Always re-fetch so we use the latest admin link / image settings.
    await _store.refresh(force: true);
    if (!mounted) return;

    final card = _store.card;
    if (card == null) return;

    final link = card.detailLinkUrl?.trim();
    // Admin pasted a URL → open that site in the browser immediately.
    if (link != null && link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null) return;
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
      return;
    }

    // Admin uploaded a details image → open the image viewer page only.
    if (!card.hasDetailImage) return;

    final location = GoRouterState.of(context).uri.path;
    final inMemberShell = location.startsWith('/dashboard') ||
        location.startsWith('/my-') ||
        location.startsWith('/announcements') ||
        location.startsWith('/connect') ||
        location.startsWith('/settings') ||
        location.startsWith('/member/');
    final target = inMemberShell
        ? '/dashboard/drugs/${card.id}'
        : '/drugs/${card.id}';
    if (location == target ||
        location.startsWith('/dashboard/drugs/') ||
        location.startsWith('/drugs/')) {
      return;
    }
    context.push(target);
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
    final name = _store.card?.name?.trim();
    final label = (name != null && name.isNotEmpty) ? name : 'Drug';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          const Icon(
            Icons.medication_outlined,
            size: 16,
            color: AppColors.mutedText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
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
