import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/announcements_api_service.dart';
import '../../../core/utils/membership_number_format.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _api = AnnouncementsApiService();

  List<AnnouncementItem> _items = [];
  List<AnnouncementCategory> _categories = const [
    AnnouncementCategory(slug: 'job_opportunities', label: 'Job Opportunities'),
    AnnouncementCategory(
      slug: 'hospital_training',
      label: 'Hospital Training',
    ),
    AnnouncementCategory(slug: 'cme_programs', label: 'CME Programs'),
    AnnouncementCategory(
      slug: 'medical_workshops',
      label: 'Medical Workshops',
    ),
    AnnouncementCategory(slug: 'alumni_updates', label: 'Alumni Updates'),
  ];
  String? _selectedCategory;
  String? _error;
  bool _loading = true;
  String? _loadingDetailId;
  String? _expandedId;
  AnnouncementDetail? _expandedDetail;

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
      final categories = await _api.fetchCategories();
      if (categories.isNotEmpty) _categories = categories;
    } catch (_) {
      // Keep fallback categories.
    }

    try {
      final items = await _api.fetchAnnouncements(category: _selectedCategory);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleDetail(AnnouncementItem item) async {
    if (_expandedId == item.id) {
      setState(() {
        _expandedId = null;
        _expandedDetail = null;
      });
      return;
    }

    setState(() => _loadingDetailId = item.id);

    try {
      final detail = await _api.fetchAnnouncementById(item.id);
      if (!mounted) return;
      setState(() {
        _expandedId = item.id;
        _expandedDetail = detail;
        _loadingDetailId = null;
        final index = _items.indexWhere((e) => e.id == item.id);
        if (index >= 0 && !item.isRead) {
          final current = _items[index];
          _items[index] = AnnouncementItem(
            id: current.id,
            title: current.title,
            category: current.category,
            categoryLabel: current.categoryLabel,
            authorRole: current.authorRole,
            authorRoleLabel: current.authorRoleLabel,
            authorId: current.authorId,
            publishedAt: current.publishedAt,
            expiresAt: current.expiresAt,
            isRead: true,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetailId = null);
      _showMessage(e.toString());
    }
  }

  Future<void> _createAnnouncement() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    var category = _categories.first.slug;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New announcement'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Body'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final item in _categories)
                      DropdownMenuItem(
                        value: item.slug,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => category = value ?? category),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;
    if (titleController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty) {
      _showMessage('Title and body are required.');
      return;
    }

    try {
      await _api.createAnnouncement(
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        category: category,
      );
      await _load();
      _showMessage('Announcement published.');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _editAnnouncement(AnnouncementItem item) async {
    AnnouncementDetail detail;
    try {
      detail = await _api.fetchAnnouncementById(item.id);
    } catch (e) {
      _showMessage(e.toString());
      return;
    }
    if (!mounted) return;

    final titleController = TextEditingController(text: detail.title);
    final bodyController = TextEditingController(text: detail.body);
    var category = detail.category;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit announcement'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Body'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final item in _categories)
                      DropdownMenuItem(
                        value: item.slug,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => category = value ?? category),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    try {
      await _api.updateAnnouncement(
        id: item.id,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        category: category,
      );
      await _load();
      _showMessage('Announcement updated.');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _deleteAnnouncement(AnnouncementItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpublish announcement'),
        content: Text('Remove "${item.title}" from the member feed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.deleteAnnouncement(item.id);
      await _load();
      _showMessage('Announcement unpublished.');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _contactAuthor(AnnouncementDetail detail) async {
    final user = AuthSession.instance.currentUser;
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final membershipController = TextEditingController(
      text: MembershipNumberFormat.displayOrFallback(
        storedMembershipNumber: user?.membershipNumber,
        batchYear: user?.batchYear,
        fullName: user?.fullName,
        fallback: user?.membershipNumber ?? '',
      ),
    );
    final detailsController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Me'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: membershipController,
                decoration: const InputDecoration(
                  labelText: 'Membership number',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Contact details',
                  hintText: 'Phone, email, or how to reach you',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (submitted != true || !mounted) return;

    try {
      final message = await _api.submitContact(
        announcementId: detail.id,
        fullName: nameController.text.trim(),
        membershipNumber: membershipController.text.trim(),
        contactDetails: detailsController.text.trim(),
      );
      _showMessage(message);
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
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
                          'Announcements',
                          style: GoogleFonts.fraunces(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: AppColors.heading,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Office bearer messages and important notices.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAnnouncementPublisherUser)
                    ElevatedButton.icon(
                      onPressed: _createAnnouncement,
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('New announcement'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                      _load();
                    },
                  ),
                  for (final category in _categories)
                    FilterChip(
                      label: Text(category.label),
                      selected: _selectedCategory == category.slug,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category.slug);
                        _load();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _ErrorBanner(message: _error!, onRetry: _load),
                const SizedBox(height: 16),
              ],
              if (_items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No announcements yet.',
                    style: GoogleFonts.inter(color: AppColors.bodyText),
                  ),
                )
              else
                for (final item in _items) ...[
                  _AnnouncementCard(
                    item: item,
                    expanded: _expandedId == item.id,
                    detail: _expandedId == item.id ? _expandedDetail : null,
                    loadingDetail: _loadingDetailId == item.id,
                    onTap: () => _toggleDetail(item),
                    onEdit: canEditAnnouncementForUser(item.authorId)
                        ? () => _editAnnouncement(item)
                        : null,
                    onDelete: isAdminUser ? () => _deleteAnnouncement(item) : null,
                    onContact: _expandedDetail != null &&
                            _expandedId == item.id &&
                            _expandedDetail!.contactEnabled &&
                            _expandedDetail!.authorId !=
                                AuthSession.instance.currentUser?.id
                        ? () => _contactAuthor(_expandedDetail!)
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.item,
    required this.expanded,
    required this.onTap,
    this.detail,
    this.loadingDetail = false,
    this.onEdit,
    this.onDelete,
    this.onContact,
  });

  final AnnouncementItem item;
  final bool expanded;
  final bool loadingDetail;
  final AnnouncementDetail? detail;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead ? AppColors.border : AppColors.secondary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.authorRoleLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  if (!item.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Unpublish',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(item.categoryLabel),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    _formatDate(item.publishedAt),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              if (loadingDetail) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ] else if (expanded && detail != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text(
                  detail!.body,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.bodyText,
                  ),
                ),
                if (onContact != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Contact Me'),
                  ),
                ],
              ],
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 14),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
