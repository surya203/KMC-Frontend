import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/admin_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/gallery_service.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/widgets/admin_layout.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _service = AdminService();
  AnalyticsOverview? _overview;
  Map<String, dynamic>? _engagement;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final overview = await _service.fetchOverview();
      Map<String, dynamic>? engagement;
      try {
        engagement = await _service.fetchEngagement();
      } catch (_) {
        engagement = null;
      }
      setState(() {
        _overview = overview;
        _engagement = engagement;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentPath: '/admin',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _overview == null
                  ? Text(_error ?? 'No data')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _StatCard('Members', '${_overview!.totalMembers}'),
                            _StatCard('Active memberships', '${_overview!.activeMemberships}'),
                            _StatCard('Pending verifications', '${_overview!.pendingVerifications}'),
                            _StatCard('Published events', '${_overview!.publishedEvents}'),
                            _StatCard('Upcoming events', '${_overview!.upcomingEvents}'),
                            _StatCard(
                              'Revenue',
                              '₹${(_overview!.totalRevenuePaise / 100).toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                        if (_engagement != null) ...[
                          const SizedBox(height: 32),
                          Text(
                            'Engagement',
                            key: const ValueKey('admin-engagement-heading'),
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              for (final entry in _engagement!.entries)
                                if (entry.value is num)
                                  _StatCard(
                                    _humanize(entry.key),
                                    '${entry.value}',
                                  ),
                            ],
                          ),
                          ..._buildEngagementEvents(),
                        ],
                      ],
                    ),
            ),
    );
  }

  List<Widget> _buildEngagementEvents() {
    final events = _engagement?['events'];
    if (events is! List || events.isEmpty) return const [];
    return [
      const SizedBox(height: 24),
      Text(
        'Registrations per event',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      const SizedBox(height: 8),
      for (final event in events)
        if (event is Map<String, dynamic>)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${event['title'] ?? event['slug'] ?? 'Event'}'),
            trailing: Text(
              '${event['registered_count'] ?? event['registrations'] ?? 0} registered',
              style: GoogleFonts.inter(color: AppColors.mutedText),
            ),
          ),
    ];
  }

  String _humanize(String key) {
    final words = key.replaceAll('_', ' ');
    return words.isEmpty
        ? key
        : words[0].toUpperCase() + words.substring(1);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.mutedText)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() =>
      _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  final _service = AdminService();
  List<VerificationItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.fetchVerifications();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _review(String profileId, String action) async {
    await _service.updateVerification(profileId, action);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentPath: '/admin/verifications',
      title: 'Verifications',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.fullName),
                  subtitle: Text('${item.email} · Batch ${item.batchYear}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _review(item.profileId, 'approve'),
                        child: const Text('Approve'),
                      ),
                      TextButton(
                        onPressed: () => _review(item.profileId, 'reject'),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _service = AdminService();
  final _searchController = TextEditingController();
  List<AdminMember> _members = [];
  bool _loading = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final members = await _service.fetchMembers(
      search: _searchController.text.trim(),
    );
    setState(() {
      _members = members;
      _loading = false;
    });
  }

  Future<void> _exportCsv() async {
    try {
      final bytes = await _service.exportMembers();
      if (bytes.isEmpty) {
        _showMessage('No member data to export.');
        return;
      }
      downloadBytes(bytes, 'kmc-members.csv');
      _showMessage('Members CSV downloaded.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not export members.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _changeRole(AdminMember member) async {
    final role = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign role'),
        children: [
          for (final role in ['member', 'staff', 'executive', 'verifier', 'admin'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Text(role),
            ),
        ],
      ),
    );
    if (role == null) return;
    try {
      await _service.updateUserRole(member.userId, role);
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentPath: '/admin/members',
      title: 'Members',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search members',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _load, child: const Text('Search')),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: const ValueKey('admin-members-export'),
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _members.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        return ListTile(
                          title: Text(member.fullName ?? member.email),
                          subtitle: Text(
                            '${member.email} · ${member.role} · ${member.membershipStatus ?? 'no membership'}',
                          ),
                          trailing: TextButton(
                            onPressed: () => _changeRole(member),
                            child: const Text('Role'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _service = AdminService();
  List<AdminEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _service.fetchAdminEvents();
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  Future<void> _createEvent() async {
    await _service.createEvent({
      'slug': 'new-event-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'New alumni event',
      'starts_at': DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
      'publish': true,
      'registration_open': true,
    });
    await _load();
  }

  Future<void> _remind(String eventId) async {
    final message = await _service.sendEventReminder(eventId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _editEvent(AdminEvent event) async {
    final titleController = TextEditingController(text: event.title);
    final venueController = TextEditingController(text: event.venueName ?? '');
    var publish = event.isPublished;
    var registrationOpen = event.registrationOpen;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit event'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const ValueKey('admin-event-title-field'),
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('admin-event-venue-field'),
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                SwitchListTile(
                  key: const ValueKey('admin-event-publish-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Published'),
                  value: publish,
                  onChanged: (value) =>
                      setDialogState(() => publish = value),
                ),
                SwitchListTile(
                  key: const ValueKey('admin-event-registration-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Registration open'),
                  value: registrationOpen,
                  onChanged: (value) =>
                      setDialogState(() => registrationOpen = value),
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
              key: const ValueKey('admin-event-save-button'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;
    try {
      await _service.updateEvent(event.id, {
        'title': titleController.text.trim(),
        if (venueController.text.trim().isNotEmpty)
          'venue_name': venueController.text.trim(),
        'publish': publish,
        'registration_open': registrationOpen,
      });
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentPath: '/admin/events',
      title: 'Admin events',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _createEvent,
                child: const Text('Create draft event'),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _events.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return ListTile(
                        title: Text(event.title),
                        subtitle: Text(
                          '${event.slug} · ${event.isPublished ? 'published' : 'draft'} · ${event.registeredCount} registered',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _remind(event.id),
                              child: const Text('Remind'),
                            ),
                            IconButton(
                              key: ValueKey('admin-event-edit-${event.id}'),
                              tooltip: 'Edit',
                              onPressed: () => _editEvent(event),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () async {
                                await _service.deleteEvent(event.id);
                                await _load();
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AdminGalleryScreen extends StatefulWidget {
  const AdminGalleryScreen({super.key});

  @override
  State<AdminGalleryScreen> createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends State<AdminGalleryScreen> {
  final _service = AdminService();
  List<GalleryAlbum> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final albums = await _service.fetchAdminAlbums();
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  Future<void> _createAlbum() async {
    final slug = 'album-${DateTime.now().millisecondsSinceEpoch}';
    await _service.createAlbum(
      slug: slug,
      title: 'New album',
      publish: true,
    );
    await _load();
  }

  Future<void> _editAlbum(GalleryAlbum album) async {
    final titleController = TextEditingController(text: album.title);
    final descriptionController =
        TextEditingController(text: album.description ?? '');

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit album'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('admin-album-title-field'),
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('admin-album-description-field'),
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
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
            key: const ValueKey('admin-album-save-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (submitted != true) return;
    try {
      await _service.updateAlbum(album.id, {
        'title': titleController.text.trim(),
        if (descriptionController.text.trim().isNotEmpty)
          'description': descriptionController.text.trim(),
      });
      await _load();
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteAlbum(GalleryAlbum album) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete album'),
        content: Text('Delete "${album.title}" and its media links?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteAlbum(album.id);
      await _load();
      _showMessage('Album deleted.');
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

  Future<void> _upload(String albumId) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.single;
    if (file?.bytes == null) return;
    await _service.uploadGalleryMedia(
      albumId: albumId,
      bytes: file!.bytes!,
      filename: file.name,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media uploaded')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentPath: '/admin/gallery',
      title: 'Admin gallery',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _createAlbum,
                child: const Text('Create album'),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _albums.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final album = _albums[index];
                      return ListTile(
                        title: Text(album.title),
                        subtitle: Text('${album.slug} · ${album.mediaCount} items'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _upload(album.id),
                              child: const Text('Upload'),
                            ),
                            IconButton(
                              key: ValueKey('admin-album-edit-${album.id}'),
                              tooltip: 'Edit',
                              onPressed: () => _editAlbum(album),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              key: ValueKey('admin-album-delete-${album.id}'),
                              tooltip: 'Delete',
                              onPressed: () => _deleteAlbum(album),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
