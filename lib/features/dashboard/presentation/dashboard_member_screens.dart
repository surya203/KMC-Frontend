import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/role_helpers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/announcements_service.dart';
import '../../../core/network/events_service.dart';
import '../../../core/network/profiles_service.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.fetchAnnouncements();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _createAnnouncement() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    var authorRole = 'office';

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
                  key: const ValueKey('announcement-role-field'),
                  initialValue: authorRole,
                  decoration: const InputDecoration(labelText: 'Author role'),
                  items: const [
                    DropdownMenuItem(
                      value: 'president',
                      child: Text('President'),
                    ),
                    DropdownMenuItem(
                      value: 'treasurer',
                      child: Text('Treasurer'),
                    ),
                    DropdownMenuItem(value: 'office', child: Text('Office')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => authorRole = value ?? 'office'),
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
        authorRole: authorRole,
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

    final titleController = TextEditingController(text: detail.title);
    final bodyController = TextEditingController(text: detail.body);

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
          if (isExecutiveUser)
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
                            subtitle: Text(item.authorRole),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!item.isRead)
                                  const Icon(
                                    Icons.fiber_manual_record,
                                    size: 10,
                                  ),
                                if (isExecutiveUser)
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
    final item = await _service.fetchById(widget.id);
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MemberLayout(
      currentPath: '/dashboard/announcements',
      title: 'Announcement',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: _item == null
                  ? const Text('Not found')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _item!.title,
                          style: GoogleFonts.fraunces(fontSize: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(_item!.body),
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
