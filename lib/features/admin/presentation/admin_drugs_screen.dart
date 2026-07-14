import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/drugs_api_service.dart';
import '../../../core/widgets/drug_header_store.dart';
import '../../../core/widgets/drug_image_preview.dart';

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
          'in the Supabase SQL Editor, then click Retry.';
    }
    if (lower.contains('xmlhttprequest') ||
        lower.contains('connection errored') ||
        lower.contains('connection error')) {
      return 'Could not reach the API. Check that the backend is running on '
          'http://localhost:8000, then click Retry. If the backend is up, also '
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
      if (existing == null) {
        drug = await _api.createDrug(
          name: result.name,
          description: result.description,
          isPublished: result.isPublished,
        );
      } else {
        drug = await _api.updateDrug(
          id: existing.id,
          name: result.name,
          description: result.description,
          isPublished: result.isPublished,
        );
      }

      if (result.headerFile != null) {
        drug = await _api.uploadDrugImage(
          id: drug.id,
          file: result.headerFile!,
          kind: 'header',
        );
      }
      if (result.detailFile != null) {
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
                    'Manage drug name, description, and two independent images (header card + details page).',
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
  const _ImageSlotPreview({required this.label, required this.url});

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
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
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: url == null || url!.isEmpty
              ? Center(
                  child: Text(
                    'No image uploaded',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorWidget: (_, _, _) => Center(
                    child: Text(
                      'Image unavailable',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
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
    required this.isPublished,
    this.headerFile,
    this.detailFile,
  });

  final String name;
  final String? description;
  final bool isPublished;
  final PlatformFile? headerFile;
  final PlatformFile? detailFile;
}

class _DrugEditorDialog extends StatefulWidget {
  const _DrugEditorDialog({this.existing});

  final DrugItem? existing;

  @override
  State<_DrugEditorDialog> createState() => _DrugEditorDialogState();
}

class _DrugEditorDialogState extends State<_DrugEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late bool _published;
  PlatformFile? _headerFile;
  PlatformFile? _detailFile;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _published = e?.isPublished ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick(String kind) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      if (kind == 'header') {
        _headerFile = file;
      } else {
        _detailFile = file;
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
    Navigator.pop(
      context,
      _DrugFormResult(
        name: name,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        isPublished: _published,
        headerFile: _headerFile,
        detailFile: _detailFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
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
                child: SingleChildScrollView(
                  child: Column(
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Published'),
                        subtitle: const Text(
                          'Visible to members in the header and details page',
                        ),
                        value: _published,
                        onChanged: (v) => setState(() => _published = v),
                      ),
                      const SizedBox(height: 8),
                      _ImagePickerTile(
                        title: 'Header card image',
                        subtitle: existing?.headerImageUrl != null
                            ? 'Current image set — pick a file to replace'
                            : 'Shown in the dashboard header (full image, no crop)',
                        fileName: _headerFile?.name,
                        onPick: () => _pick('header'),
                      ),
                      const SizedBox(height: 10),
                      _ImagePickerTile(
                        title: 'Details page image',
                        subtitle: existing?.detailImageUrl != null
                            ? 'Current image set — pick a file to replace'
                            : 'Shown on the Drug Details page',
                        fileName: _detailFile?.name,
                        onPick: () => _pick('detail'),
                      ),
                    ],
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
  });

  final String title;
  final String subtitle;
  final String? fileName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPick,
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
              TextButton(onPressed: onPick, child: const Text('Upload')),
            ],
          ),
        ),
      ),
    );
  }
}
