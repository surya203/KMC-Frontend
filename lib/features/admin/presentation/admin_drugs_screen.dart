import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/drugs_api_service.dart';
import '../../../core/widgets/drug_header_store.dart';
import '../../../core/widgets/drug_image_preview.dart';

enum _DetailSource { file, url }

bool _looksLikeImageUrl(String url) {
  final path = url.toLowerCase().split('?').first;
  return path.endsWith('.png') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp');
}

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

class AdminDrugsScreen extends StatefulWidget {
  const AdminDrugsScreen({super.key});

  @override
  State<AdminDrugsScreen> createState() => _AdminDrugsScreenState();
}

class _AdminDrugsScreenState extends State<AdminDrugsScreen> {
  final _api = DrugsApiService();
  List<DrugItem> _drugs = [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AuthSession.instance.ensureReady();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final drugs = await _api.fetchAdminDrugs();
      if (!mounted) return;
      setState(() {
        _drugs = drugs;
        _loading = false;
      });
      // Keep sidebar banner in sync (retries if an earlier load failed).
      await DrugHeaderStore.instance.refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.contains('drugs table is missing') ||
        lower.contains('migration-018') ||
        lower.contains('pgrst205')) {
      return 'Database setup needed: run KMC-Backend/docs/migration-018-drugs.sql '
          'and migration-019-drugs-detail-link.sql in the Supabase SQL Editor, '
          'then click Retry.';
    }
    if (lower.contains('detail_link_url') ||
        lower.contains('migration-019')) {
      return 'Database update needed: run '
          'KMC-Backend/docs/migration-019-drugs-detail-link.sql '
          'in the Supabase SQL Editor, then click Retry.';
    }
    if (lower.contains('xmlhttprequest') ||
        lower.contains('connection errored') ||
        lower.contains('connection error')) {
      return 'Could not reach the API. Check that the backend is running on '
          'http://200.141.2.90:8000, then click Retry. If the backend is up, also '
          'run docs/migration-018-drugs.sql in Supabase (drugs table is required).';
    }
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    if (text.startsWith('DioException')) {
      final detailMatch = RegExp(r'detail["\s:]+([^"}\]]+)').firstMatch(text);
      if (detailMatch != null) return detailMatch.group(1)!.trim();
    }
    return text.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  Future<void> _openEditor({DrugItem? existing}) async {
    final result = await showDialog<_DrugFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DrugEditorDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    setState(() => _busyId = existing?.id ?? 'new');
    try {
      DrugItem drug;
      final useDetailUrl = result.detailSource == _DetailSource.url;
      final link = result.detailLinkUrl?.trim();
      final linkOrNull = (link != null && link.isNotEmpty) ? link : null;
      final imageFromUrl = useDetailUrl &&
              linkOrNull != null &&
              _looksLikeImageUrl(linkOrNull)
          ? linkOrNull
          : null;
      final changingDetail = useDetailUrl || result.detailFile != null;

      if (existing == null) {
        drug = await _api.createDrug(
          name: result.name,
          description: result.description,
          isPublished: true,
          detailLinkUrl: useDetailUrl ? linkOrNull : null,
          detailImageUrl: imageFromUrl,
        );
      } else if (changingDetail) {
        drug = await _api.updateDrug(
          id: existing.id,
          name: result.name,
          description: result.description,
          isPublished: true,
          detailLinkUrl: useDetailUrl ? linkOrNull : null,
          clearDetailLink: !useDetailUrl,
          // Image URL → show that image. Website URL → clear old details image
          // so admin shows the link instead of the previous upload.
          detailImageUrl: imageFromUrl,
          clearDetailImageUrl: useDetailUrl && imageFromUrl == null,
        );
      } else {
        drug = await _api.updateDrug(
          id: existing.id,
          name: result.name,
          description: result.description,
          isPublished: true,
        );
      }

      if (result.headerFile != null) {
        drug = await _api.uploadDrugImage(
          id: drug.id,
          file: result.headerFile!,
          kind: 'header',
        );
      }
      if (!useDetailUrl && result.detailFile != null) {
        drug = await _api.uploadDrugImage(
          id: drug.id,
          file: result.detailFile!,
          kind: 'detail',
        );
      }

      if (!mounted) return;
      await _load();
      await DrugHeaderStore.instance.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Drug created.' : 'Drug updated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmDelete(DrugItem drug) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete drug?'),
        content: Text('Delete “${drug.name}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busyId = drug.id);
    try {
      await _api.deleteDrug(drug.id);
      if (!mounted) return;
      await _load();
      await DrugHeaderStore.instance.refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 700;

    return ColoredBox(
      color: const Color(0xFFF7F7F4),
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 24,
            16,
            isCompact ? 16 : 24,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drug Management',
                    style: GoogleFonts.fraunces(
                      fontSize: isCompact ? 28 : 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage drug name, description and two independent images (header card + details page).',
                    style: GoogleFonts.inter(
                      color: AppColors.bodyText,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _busyId != null ? null : () => _openEditor(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Drug'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _ErrorBanner(message: _error!, onRetry: _load)
                  else if (_drugs.isEmpty)
                    _EmptyState(onAdd: () => _openEditor())
                  else
                    ..._drugs.map(
                      (drug) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DrugAdminCard(
                          drug: drug,
                          busy: _busyId == drug.id,
                          onEdit: () => _openEditor(existing: drug),
                          onDelete: () => _confirmDelete(drug),
                          onView: () => showDrugImagePreview(
                            context,
                            imageUrl: drug.detailImageUrl ?? drug.headerImageUrl,
                            drugId: drug.id,
                            linkUrl: drug.detailLinkUrl,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.medication_outlined, size: 40, color: AppColors.mutedText),
          const SizedBox(height: 12),
          Text(
            'No drugs yet',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a drug with a header image and a details image.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.bodyText),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Drug'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: GoogleFonts.inter(color: AppColors.error)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DrugAdminCard extends StatelessWidget {
  const _DrugAdminCard({
    required this.drug,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  final DrugItem drug;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stacked = width < 720;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drug.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      drug.isPublished ? 'Published' : 'Draft',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: drug.isPublished
                            ? AppColors.success
                            : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                IconButton(
                  tooltip: 'View details',
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (stacked) ...[
            _ImageSlotPreview(
              label: 'Header card image',
              url: drug.headerImageUrl,
            ),
            const SizedBox(height: 12),
            _ImageSlotPreview(
              label: 'Details page image',
              url: drug.detailImageUrl,
              // Portrait creatives need more height on phone or they look tiny.
              tall: true,
              linkUrl: drug.detailLinkUrl,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ImageSlotPreview(
                    label: 'Header card image',
                    url: drug.headerImageUrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageSlotPreview(
                    label: 'Details page image',
                    url: drug.detailImageUrl,
                    tall: true,
                    linkUrl: drug.detailLinkUrl,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ImageSlotPreview extends StatelessWidget {
  const _ImageSlotPreview({
    required this.label,
    required this.url,
    this.tall = false,
    this.linkUrl,
  });

  final String label;
  final String? url;
  final bool tall;
  final String? linkUrl;

  Future<void> _openLink(BuildContext context, String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 720;
    final double previewHeight;
    if (!tall) {
      previewHeight = isPhone ? 120 : 140;
    } else if (isPhone) {
      previewHeight = (width * 1.15).clamp(280.0, 420.0);
    } else {
      previewHeight = 220;
    }

    final link = linkUrl?.trim();
    final hasLink = link != null && link.isNotEmpty;
    final isWebsiteLink = hasLink && !_looksLikeImageUrl(link);
    // Website link: show a clickable URL card, not a leftover uploaded image.
    final showLinkOnly =
        hasLink && (isWebsiteLink || url == null || url!.isEmpty);
    final showImage = !showLinkOnly && url != null && url!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.bodyText,
          ),
        ),
        const SizedBox(height: 8),
        if (showLinkOnly)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _openLink(context, link),
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  color: const Color(0xFFF0F5FA),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.link_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saved link',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.heading,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              link,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    AppColors.primary.withValues(alpha: 0.5),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to open · Members: header image opens this link',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: previewHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: showImage
                ? CachedNetworkImage(
                    imageUrl: url!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    errorWidget: (_, _, _) => Center(
                      child: Text(
                        'Unable to load image',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'No image uploaded',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _DrugFormResult {
  const _DrugFormResult({
    required this.name,
    required this.description,
    required this.detailSource,
    this.headerFile,
    this.detailFile,
    this.detailLinkUrl,
  });

  final String name;
  final String? description;
  final _DetailSource detailSource;
  final PlatformFile? headerFile;
  final PlatformFile? detailFile;
  final String? detailLinkUrl;
}

class _DrugEditorDialog extends StatefulWidget {
  const _DrugEditorDialog({this.existing});

  final DrugItem? existing;

  @override
  State<_DrugEditorDialog> createState() => _DrugEditorDialogState();
}

class _DrugEditorDialogState extends State<_DrugEditorDialog> {
  static const _exclusiveMsg =
      'Please provide either an uploaded image or an image URL, not both.';

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _detailUrl;
  late final ScrollController _scrollController;
  PlatformFile? _headerFile;
  PlatformFile? _detailFile;
  /// True when the existing detail image came from a pasted URL (http image).
  late bool _existingWasUrl;
  /// When true, admin cleared existing detail source and must provide a new one.
  bool _clearedExistingDetail = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    final seededUrl = _seedDetailLinkUrl(e);
    _existingWasUrl = seededUrl != null;
    _detailUrl = TextEditingController(text: seededUrl ?? '');
    _detailUrl.addListener(_onDetailUrlChanged);
    _scrollController = ScrollController();
  }

  String? _seedDetailLinkUrl(DrugItem? e) {
    if (e == null) return null;
    final link = e.detailLinkUrl?.trim();
    if (link != null && link.isNotEmpty && _isHttpUrl(link)) {
      return link;
    }
    return null;
  }

  void _onDetailUrlChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _detailUrl.removeListener(_onDetailUrlChanged);
    _name.dispose();
    _description.dispose();
    _detailUrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasDetailFile => _detailFile != null;

  bool get _hasDetailUrlText => _detailUrl.text.trim().isNotEmpty;

  bool get _urlBlocksUpload => _hasDetailUrlText;

  bool get _fileBlocksUrl => _hasDetailFile;

  bool get _hasExistingDetailImage {
    final e = widget.existing;
    if (e == null || _clearedExistingDetail) return false;
    final url = e.detailImageUrl?.trim();
    if (url != null && url.isNotEmpty) return true;
    final link = e.detailLinkUrl?.trim();
    return link != null && link.isNotEmpty;
  }

  Future<void> _pickHeader() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _headerFile = result.files.first);
  }

  Future<void> _pickDetail() async {
    if (_urlBlocksUpload) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _detailFile = result.files.first;
      _detailUrl.clear();
      _clearedExistingDetail = true;
    });
  }

  void _clearDetailFile() {
    setState(() {
      _detailFile = null;
    });
  }

  void _clearDetailUrl() {
    setState(() {
      _detailUrl.clear();
      if (_existingWasUrl) {
        _clearedExistingDetail = true;
      }
    });
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drug name is required.')),
      );
      return;
    }

    final urlText = _detailUrl.text.trim();
    final hasFile = _hasDetailFile;
    final hasUrl = urlText.isNotEmpty;

    if (hasFile && hasUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_exclusiveMsg)),
      );
      return;
    }

    if (!hasFile && !hasUrl) {
      if (!_hasExistingDetailImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_exclusiveMsg)),
        );
        return;
      }
      // Keep existing detail image; no source change.
      Navigator.pop(
        context,
        _DrugFormResult(
          name: name,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          detailSource: _DetailSource.file,
          headerFile: _headerFile,
        ),
      );
      return;
    }

    if (hasUrl) {
      if (!_isHttpUrl(urlText)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL must start with http:// or https://'),
          ),
        );
        return;
      }
      Navigator.pop(
        context,
        _DrugFormResult(
          name: name,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          detailSource: _DetailSource.url,
          headerFile: _headerFile,
          detailLinkUrl: urlText,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _DrugFormResult(
        name: name,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        detailSource: _DetailSource.file,
        headerFile: _headerFile,
        detailFile: _detailFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final uploadEnabled = !_urlBlocksUpload;
    final urlEnabled = !_fileBlocksUrl;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Add Drug' : 'Edit Drug',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    scrollbarTheme: ScrollbarThemeData(
                      thickness: const WidgetStatePropertyAll(3),
                      radius: const Radius.circular(8),
                      thumbVisibility: const WidgetStatePropertyAll(true),
                      trackVisibility: const WidgetStatePropertyAll(false),
                      thumbColor: WidgetStatePropertyAll(
                        AppColors.mutedText.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thickness: 3,
                    radius: const Radius.circular(8),
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      primary: false,
                      padding: const EdgeInsets.only(right: 6),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Drug name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _description,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ImagePickerTile(
                        title: 'Header card image',
                        subtitle: existing?.headerImageUrl != null
                            ? 'Current image set — pick a file to replace'
                            : 'Shown in the dashboard header (full image, no crop)',
                        fileName: _headerFile?.name,
                        onPick: _pickHeader,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Details page image',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use only one method: upload a file or paste a URL.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (uploadEnabled) ...[
                        _ImagePickerTile(
                          title: 'Upload file',
                          subtitle: _hasExistingDetailImage && !_existingWasUrl
                              ? 'Current image set — pick a file to replace'
                              : 'JPG, JPEG, PNG, WEBP, or GIF',
                          fileName: _detailFile?.name,
                          onPick: _pickDetail,
                          onClear: _hasDetailFile ? _clearDetailFile : null,
                          enabled: uploadEnabled,
                        ),
                        if (urlEnabled) const SizedBox(height: 10),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Upload file is unavailable while a URL is entered. Clear the URL to upload a file.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      if (urlEnabled)
                        TextField(
                          controller: _detailUrl,
                          enabled: urlEnabled,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: 'Paste URL',
                            hintText: 'https://…',
                            helperText:
                                'Any website or image link — members open it from drug details',
                            border: const OutlineInputBorder(),
                            suffixIcon: _hasDetailUrlText
                                ? IconButton(
                                    tooltip: 'Clear URL',
                                    onPressed: _clearDetailUrl,
                                    icon: const Icon(Icons.clear),
                                  )
                                : null,
                          ),
                        )
                      else
                        Text(
                          'Paste URL is unavailable while a file is selected. Remove the file to paste a URL.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                    ],
                  ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    child: Text(existing == null ? 'Create' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.title,
    required this.subtitle,
    required this.onPick,
    this.fileName,
    this.onClear,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: const Color(0xFFF7F7F4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onPick : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileName ?? subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClear != null)
                  TextButton(
                    onPressed: enabled ? onClear : null,
                    child: const Text('Remove'),
                  ),
                TextButton(
                  onPressed: enabled ? onPick : null,
                  child: const Text('Upload'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
