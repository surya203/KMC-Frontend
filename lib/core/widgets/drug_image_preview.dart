import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../network/drugs_api_service.dart';

/// Shows the drug detail image in a dialog on the current page (no route change).
Future<void> showDrugImagePreview(
  BuildContext context, {
  String? imageUrl,
  String? drugId,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _DrugImagePreviewDialog(
        initialUrl: imageUrl,
        drugId: drugId,
      );
    },
  );
}

class _DrugImagePreviewDialog extends StatefulWidget {
  const _DrugImagePreviewDialog({
    this.initialUrl,
    this.drugId,
  });

  final String? initialUrl;
  final String? drugId;

  @override
  State<_DrugImagePreviewDialog> createState() =>
      _DrugImagePreviewDialogState();
}

class _DrugImagePreviewDialogState extends State<_DrugImagePreviewDialog> {
  final _api = DrugsApiService();
  String? _url;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = widget.initialUrl;
    if ((_url == null || _url!.isEmpty) &&
        widget.drugId != null &&
        widget.drugId!.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final drug = await _api.fetchPublishedDrug(widget.drugId!);
      if (!mounted) return;
      setState(() {
        _url = drug.detailImageUrl ?? drug.headerImageUrl;
        _loading = false;
        if (_url == null || _url!.isEmpty) {
          _error = 'No detail image available.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load drug image.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width;
    final maxH = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxW > 900 ? 860 : maxW - 32,
          maxHeight: maxH - 48,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            _error!,
            style: GoogleFonts.inter(color: AppColors.bodyText),
          ),
        ),
      );
    }
    final url = _url;
    if (url == null || url.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No detail image available.',
            style: GoogleFonts.inter(color: AppColors.mutedText),
          ),
        ),
      );
    }
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 3,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        width: double.infinity,
        placeholder: (_, _) => const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, _, _) => SizedBox(
          height: 160,
          child: Center(
            child: Text(
              'Unable to load image',
              style: GoogleFonts.inter(color: AppColors.mutedText),
            ),
          ),
        ),
      ),
    );
  }
}
