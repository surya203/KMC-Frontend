import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/role_helpers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/announcements_service.dart';
import '../../../core/network/events_service.dart';
import '../../../core/network/membership_service.dart';
import '../../../core/network/profiles_service.dart';
import '../../../core/payments/razorpay_checkout.dart';
import '../../../core/widgets/member_layout.dart';

class DashboardProfileScreen extends StatefulWidget {
  const DashboardProfileScreen({super.key});

  @override
  State<DashboardProfileScreen> createState() => _DashboardProfileScreenState();
}

class _DashboardProfileScreenState extends State<DashboardProfileScreen> {
  final _service = ProfilesService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _orgController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();

  MyProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _orgController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _service.fetchMyProfile();
      _nameController.text = profile.fullName;
      _titleController.text = profile.currentTitle ?? '';
      _orgController.text = profile.organization ?? '';
      _cityController.text = profile.city ?? '';
      _bioController.text = profile.bio ?? '';
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await _service.updateMyProfile({
        'full_name': _nameController.text.trim(),
        'current_title': _titleController.text.trim(),
        'organization': _orgController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
      });
      setState(() => _profile = profile);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.single;
    if (file?.bytes == null) return;
    setState(() => _saving = true);
    try {
      final url = await _service.uploadPhoto(file!.bytes!, file.name);
      setState(() {
        _profile = MyProfile(
          id: _profile!.id,
          fullName: _profile!.fullName,
          batchYear: _profile!.batchYear,
          photoUrl: url,
          degree: _profile!.degree,
          specialization: _profile!.specialization,
          currentTitle: _profile!.currentTitle,
          organization: _profile!.organization,
          city: _profile!.city,
          country: _profile!.country,
          bio: _profile!.bio,
          linkedinUrl: _profile!.linkedinUrl,
          phone: _profile!.phone,
          verificationStatus: _profile!.verificationStatus,
          isDirectoryVisible: _profile!.isDirectoryVisible,
        );
      });
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberLayout(
      currentPath: '/dashboard/profile',
      title: 'My profile',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null)
                          Text(_error!, style: const TextStyle(color: AppColors.error)),
                        OutlinedButton(
                          key: const ValueKey('profile-upload-photo'),
                          onPressed: _saving ? null : _uploadPhoto,
                          child: const Text('Upload profile photo'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('profile-full-name'),
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full name'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Current title'),
                        ),
                        TextFormField(
                          controller: _orgController,
                          decoration: const InputDecoration(labelText: 'Organization'),
                        ),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Bio'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          key: const ValueKey('profile-save'),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const CircularProgressIndicator()
                              : const Text('Save profile'),
                        ),
                        if (_profile?.verificationStatus != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Verification: ${_profile!.verificationStatus}',
                            style: GoogleFonts.inter(color: AppColors.bodyText),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class DashboardAnnouncementsScreen extends StatefulWidget {
  const DashboardAnnouncementsScreen({super.key});

  @override
  State<DashboardAnnouncementsScreen> createState() =>
      _DashboardAnnouncementsScreenState();
}

class _DashboardAnnouncementsScreenState
    extends State<DashboardAnnouncementsScreen> {
  final _service = AnnouncementsService();
  List<AnnouncementSummary> _items = [];
  List<AnnouncementCategory> _categories = [];
  String? _selectedCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Prefer API categories; keep a local fallback so the page still renders.
    var categories = _categories.isNotEmpty
        ? _categories
        : const [
            AnnouncementCategory(
              slug: 'job_opportunities',
              label: 'Job Opportunities',
            ),
            AnnouncementCategory(
              slug: 'hospital_training',
              label: 'Hospital Training',
            ),
            AnnouncementCategory(
              slug: 'cme_programs',
              label: 'CME Programs',
            ),
            AnnouncementCategory(
              slug: 'medical_workshops',
              label: 'Medical Workshops',
            ),
            AnnouncementCategory(
              slug: 'alumni_updates',
              label: 'Alumni Updates',
            ),
          ];

    try {
      categories = await _service.fetchCategories();
    } on ApiException {
      // Keep fallback categories.
    }

    try {
      final items = await _service.fetchAnnouncements(
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _items = items;
        _loading = false;
      });
    } on ApiException catch (error) {
      // One retry — uvicorn --reload briefly drops connections.
      try {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        final items = await _service.fetchAnnouncements(
          category: _selectedCategory,
        );
        if (!mounted) return;
        setState(() {
          _categories = categories;
          _items = items;
          _loading = false;
        });
        return;
      } on ApiException {
        if (!mounted) return;
        setState(() {
          _categories = categories;
          _loading = false;
        });
        _showMessage(error.message);
      }
    }
  }

  Future<void> _createAnnouncement() async {
    if (_categories.isEmpty) {
      try {
        _categories = await _service.fetchCategories();
      } on ApiException catch (error) {
        _showMessage(error.message);
        return;
      }
    }
    if (!mounted) return;
    if (_categories.isEmpty) {
      _showMessage('Categories are not available yet.');
      return;
    }

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
                  key: const ValueKey('announcement-title-field'),
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('announcement-body-field'),
                  controller: bodyController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Body'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('announcement-category-field'),
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
              key: const ValueKey('announcement-publish-button'),
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
      await _service.createAnnouncement(
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        category: category,
      );
      await _load();
      _showMessage('Announcement published.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _editAnnouncement(AnnouncementSummary item) async {
    AnnouncementDetail? detail;
    try {
      detail = await _service.fetchById(item.id);
    } on ApiException catch (error) {
      _showMessage(error.message);
      return;
    }
    if (!mounted) return;

    if (_categories.isEmpty) {
      try {
        _categories = await _service.fetchCategories();
      } on ApiException catch (error) {
        _showMessage(error.message);
        return;
      }
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
                  key: const ValueKey('announcement-edit-title-field'),
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('announcement-edit-body-field'),
                  controller: bodyController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Body'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('announcement-edit-category-field'),
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
              key: const ValueKey('announcement-edit-save-button'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
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
      await _service.updateAnnouncement(
        id: item.id,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        category: category,
      );
      await _load();
      _showMessage('Announcement updated.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteAnnouncement(AnnouncementSummary item) async {
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
      await _service.deleteAnnouncement(item.id);
      await _load();
      _showMessage('Announcement unpublished.');
    } on ApiException catch (error) {
      _showMessage(error.message);
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
    return MemberLayout(
      currentPath: '/dashboard/announcements',
      title: 'Announcements',
      child: Column(
        children: [
          if (isAnnouncementPublisher)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: ElevatedButton.icon(
                  key: const ValueKey('announcement-create-button'),
                  onPressed: _createAnnouncement,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('New announcement'),
                ),
              ),
            ),
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Wrap(
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
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No announcements yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            key: ValueKey('announcement-${item.id}'),
                            title: Text(item.title),
                            subtitle: Text(
                              '${item.categoryLabel} · ${item.authorRoleLabel}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!item.isRead)
                                  const Icon(
                                    Icons.fiber_manual_record,
                                    size: 10,
                                  ),
                                if (canEditAnnouncement(item.authorId))
                                  IconButton(
                                    key: ValueKey(
                                      'announcement-edit-${item.id}',
                                    ),
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _editAnnouncement(item),
                                  ),
                                if (isAdminUser)
                                  IconButton(
                                    key: ValueKey(
                                      'announcement-delete-${item.id}',
                                    ),
                                    tooltip: 'Unpublish',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteAnnouncement(item),
                                  ),
                              ],
                            ),
                            onTap: () => context
                                .go('/dashboard/announcements/${item.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class DashboardAnnouncementDetailScreen extends StatefulWidget {
  const DashboardAnnouncementDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<DashboardAnnouncementDetailScreen> createState() =>
      _DashboardAnnouncementDetailScreenState();
}

class _DashboardAnnouncementDetailScreenState
    extends State<DashboardAnnouncementDetailScreen> {
  final _service = AnnouncementsService();
  AnnouncementDetail? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final item = await _service.fetchById(widget.id);
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _contactAuthor() async {
    final item = _item;
    if (item == null) return;

    final user = authSession.user;
    final nameController = TextEditingController(
      text: user?.profile?.fullName ?? '',
    );
    final membershipController = TextEditingController(
      text: user?.membership?.membershipNumber ?? '',
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
                key: const ValueKey('announcement-contact-name-field'),
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('announcement-contact-membership-field'),
                controller: membershipController,
                decoration: const InputDecoration(
                  labelText: 'Membership number',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('announcement-contact-details-field'),
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
            key: const ValueKey('announcement-contact-submit-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (submitted != true || !mounted) return;
    if (nameController.text.trim().isEmpty ||
        membershipController.text.trim().isEmpty ||
        detailsController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Full name, membership number, and contact details are required.',
          ),
        ),
      );
      return;
    }

    try {
      final message = await _service.submitContact(
        announcementId: item.id,
        fullName: nameController.text.trim(),
        membershipNumber: membershipController.text.trim(),
        contactDetails: detailsController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final isOwnAnnouncement = item != null &&
        item.authorId == authSession.user?.id;

    return MemberLayout(
      currentPath: '/dashboard/announcements',
      title: 'Announcement',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: item == null
                  ? const Text('Not found')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.fraunces(fontSize: 28),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(item.categoryLabel)),
                            Chip(label: Text(item.authorRoleLabel)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(item.body),
                        if (item.contactEnabled && !isOwnAnnouncement) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            key: const ValueKey('announcement-contact-button'),
                            onPressed: _contactAuthor,
                            icon: const Icon(Icons.mail_outline),
                            label: const Text('Contact Me'),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }
}

class DashboardMyEventsScreen extends StatefulWidget {
  const DashboardMyEventsScreen({super.key});

  @override
  State<DashboardMyEventsScreen> createState() =>
      _DashboardMyEventsScreenState();
}

class _DashboardMyEventsScreenState extends State<DashboardMyEventsScreen> {
  final _service = EventsService();
  List<MyEventRegistration> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _service.fetchMyRegistrations();
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MemberLayout(
      currentPath: '/dashboard/events',
      title: 'My events',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _events.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final event = _events[index];
                return ListTile(
                  key: ValueKey('my-event-${event.eventId}'),
                  title: Text(event.title),
                  subtitle: Text('Registered · ${event.registeredCount} total'),
                  onTap: () => context.go('/events/${event.slug}'),
                );
              },
            ),
    );
  }
}

class DashboardMembershipScreen extends StatefulWidget {
  const DashboardMembershipScreen({super.key});

  @override
  State<DashboardMembershipScreen> createState() =>
      _DashboardMembershipScreenState();
}

class _DashboardMembershipScreenState extends State<DashboardMembershipScreen> {
  final _service = MembershipService();
  MembershipRecord? _record;
  List<DonationCategory> _categories = [];
  List<DonationRecord> _donations = [];
  bool _loading = true;
  bool _donating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final record = await _service.fetchMyMembership();
      var categories = <DonationCategory>[];
      var donations = <DonationRecord>[];
      try {
        categories = await _service.fetchDonationCategories();
        donations = await _service.fetchMyDonations();
      } on ApiException {
        // Record should still show even if donations table is not migrated yet.
      }
      if (!mounted) return;
      setState(() {
        _record = record;
        _categories = categories;
        _donations = donations;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Future<void> _openDonateDialog() async {
    if (_categories.isEmpty) {
      try {
        _categories = await _service.fetchDonationCategories();
      } on ApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
        return;
      }
    }
    if (!mounted) return;

    final amountController = TextEditingController();
    var donationType = 'general';
    String? projectCategory =
        _categories.isEmpty ? null : _categories.first.slug;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final maxHeight = MediaQuery.of(context).size.height * 0.7;
          return AlertDialog(
            title: const Text('Make a donation'),
            content: SizedBox(
              width: 420,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donate as a general donation, or to exactly one project.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.bodyText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('donation-amount-field'),
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          hintText: 'e.g. 500',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        key: const ValueKey('donation-type-general'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('General Donation'),
                        value: 'general',
                        groupValue: donationType,
                        onChanged: (value) => setDialogState(
                          () => donationType = value ?? 'general',
                        ),
                      ),
                      RadioListTile<String>(
                        key: const ValueKey('donation-type-project'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Project Donation'),
                        value: 'project',
                        groupValue: donationType,
                        onChanged: (value) => setDialogState(
                          () => donationType = value ?? 'project',
                        ),
                      ),
                      if (donationType == 'project') ...[
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          key: const ValueKey(
                            'donation-project-category-field',
                          ),
                          initialValue: projectCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Project category (one only)',
                            isDense: true,
                          ),
                          items: [
                            for (final category in _categories)
                              DropdownMenuItem(
                                value: category.slug,
                                child: Text(
                                  category.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => projectCategory = value,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const ValueKey('donation-continue-button'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue to pay'),
              ),
            ],
          );
        },
      ),
    );

    if (submitted != true || !mounted) return;

    final rupees = double.tryParse(amountController.text.trim());
    if (rupees == null || rupees < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount of at least ₹1.')),
      );
      return;
    }
    if (donationType == 'project' &&
        (projectCategory == null || projectCategory!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose exactly one project category.')),
      );
      return;
    }

    final amountPaise = (rupees * 100).round();
    setState(() => _donating = true);

    try {
      final checkout = await _service.createDonationCheckout(
        amountPaise: amountPaise,
        donationType: donationType,
        projectCategory:
            donationType == 'project' ? projectCategory : null,
      );

      if (checkout.keyId.isNotEmpty) {
        final paid = await openRazorpayCheckout(
          keyId: checkout.keyId,
          orderId: checkout.orderId,
          amountPaise: checkout.amountPaise,
          currency: checkout.currency,
          description: donationType == 'general'
              ? 'General donation'
              : 'Donation: ${checkout.projectCategoryLabel ?? projectCategory}',
          prefillEmail: authSession.user?.email,
        );
        if (!paid) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Donation payment was cancelled.')),
          );
          return;
        }
      }

      final message = await _service.completeDonation(checkout.orderId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _donating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;

    return MemberLayout(
      currentPath: '/dashboard/membership',
      title: 'Membership',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : record == null
              ? const Center(child: Text('Membership record not found.'))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Membership record',
                            style: GoogleFonts.fraunces(fontSize: 28),
                          ),
                        ),
                        ElevatedButton.icon(
                          key: const ValueKey('membership-donate-button'),
                          onPressed: _donating ? null : _openDonateDialog,
                          icon: _donating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.volunteer_activism_outlined),
                          label: Text(_donating ? 'Processing…' : 'Donate'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.planName,
                      style: GoogleFonts.inter(
                        color: AppColors.bodyText,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _MembershipField(
                      label: 'Membership Number',
                      value: record.membershipNumber ?? '—',
                    ),
                    _MembershipField(
                      label: 'Registration Date',
                      value: _formatDate(record.registrationDate),
                    ),
                    _MembershipField(
                      label: 'Payment Date',
                      value: _formatDate(record.paymentDate),
                    ),
                    _MembershipField(
                      label: 'Fee',
                      value: record.feeDisplay,
                    ),
                    _MembershipField(
                      label: 'General Donation',
                      value: record.generalDonationDisplay,
                    ),
                    _MembershipField(
                      label: 'Project Donation',
                      value: record.projectDonationDisplay,
                    ),
                    if (record.projectDonations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Project donations by category',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in record.projectDonations)
                        _MembershipField(
                          label: item.label,
                          value: '₹${(item.totalPaise / 100).toStringAsFixed(
                            item.totalPaise % 100 == 0 ? 0 : 2,
                          )}',
                        ),
                    ],
                    if (_donations.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Donation history',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final donation in _donations)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(donation.title),
                          subtitle: Text(
                            '${donation.status} · ${_formatDate(donation.capturedAt ?? donation.createdAt)}',
                          ),
                          trailing: Text(donation.amountDisplay),
                        ),
                    ],
                  ],
                ),
    );
  }
}

class _MembershipField extends StatelessWidget {
  const _MembershipField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: AppColors.heading,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
