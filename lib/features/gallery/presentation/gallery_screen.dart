import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/gallery_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/cover_image.dart';
import '../../../core/widgets/media_lightbox.dart';
import '../../../core/widgets/member_layout.dart';
import '../../../core/widgets/page_hero.dart';

String _slugify(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
  if (slug.isEmpty) {
    return 'album-${DateTime.now().millisecondsSinceEpoch}';
  }
  return '$slug-${DateTime.now().millisecondsSinceEpoch % 100000}';
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _service = GalleryService();
  List<GalleryAlbum> _albums = [];
  bool _loading = true;
  String? _error;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
      final albums = await _service.fetchAlbums();
      if (!mounted) return;
      setState(() {
        _albums = albums;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _createAlbum() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create album'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Album title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != true || titleController.text.trim().isEmpty) return;

    try {
      final album = await _service.createAlbum(
        slug: _slugify(titleController.text.trim()),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
      );
      if (!mounted) return;
      context.go('/gallery/${album.slug}');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _editAlbum(GalleryAlbum album) async {
    if (!album.isOwnedBy(authSession.user?.id)) return;

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
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (submitted != true || titleController.text.trim().isEmpty) return;

    try {
      await _service.updateAlbum(
        albumId: album.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
      );
      await _load();
      _showMessage('Album updated.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteAlbum(GalleryAlbum album) async {
    if (!album.isOwnedBy(authSession.user?.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete album'),
        content: Text(
          'Delete "${album.title}" and all its photos and links? '
          'This cannot be undone.',
        ),
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

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.of(context).size.width > 1100
        ? 4
        : MediaQuery.of(context).size.width > 700
            ? 3
            : 2;

    return MemberLayout(
      currentPath: '/gallery',
      title: 'Gallery',
      child: SingleChildScrollView(
        child: Column(
          children: [
            PageHero(
              eyebrow: 'Gallery',
              title: HeadingStyles.pageHeroTitleWidget(
                context,
                regular: 'Decades of ',
                italic: 'memories.',
              ),
              subtitle:
                  'Create albums, upload photos from your device, or share Google Drive links.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _createAlbum,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: const Text('Create album'),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 72),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _GalleryErrorState(
                            message: _error!,
                            onRetry: _load,
                          )
                        : _albums.isEmpty
                        ? _EmptyGalleryState(onCreateAlbum: _createAlbum)
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.92,
                              ),
                              itemCount: _albums.length,
                              itemBuilder: (context, index) {
                                final album = _albums[index];
                                return _GalleryAlbumCard(
                                  title: album.title,
                                  imageUrl: album.coverImageUrl,
                                  subtitle: '${album.mediaCount} photos',
                                  canManage:
                                      album.isOwnedBy(authSession.user?.id),
                                  onEdit: () => _editAlbum(album),
                                  onDelete: () => _deleteAlbum(album),
                                  onTap: () async {
                                    await context.push('/gallery/${album.slug}');
                                    if (mounted) await _load();
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class GalleryAlbumScreen extends StatefulWidget {
  const GalleryAlbumScreen({super.key, required this.slug});

  final String slug;

  @override
  State<GalleryAlbumScreen> createState() => _GalleryAlbumScreenState();
}

class _GalleryAlbumScreenState extends State<GalleryAlbumScreen> {
  final _service = GalleryService();
  GalleryAlbumDetail? _album;
  List<GalleryMedia> _media = [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;

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
      final album = await _service.fetchAlbum(widget.slug);
      final media = await _service.fetchAlbumMedia(widget.slug);
      if (!mounted) return;
      final merged = <String, GalleryMedia>{};
      for (final item in [...album.media, ...media]) {
        merged[item.id] = item;
      }
      final combined = merged.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _album = album;
        _media = combined;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this album.';
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _uploadPhotos() async {
    if (_album == null) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() => _uploading = true);
    try {
      for (final file in picked.files) {
        if (file.bytes == null) continue;
        await _service.uploadMedia(
          albumId: _album!.id,
          bytes: file.bytes!,
          filename: file.name,
        );
      }
      await _load();
      _showMessage('Photos uploaded.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addDriveLink() async {
    if (_album == null) return;

    final titleController = TextEditingController();
    final urlController = TextEditingController();
    var linkType = 'drive_album';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Google Drive link'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Link name',
                  hintText: 'e.g. Reunion Day-1 photos',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Google Drive URL',
                  hintText: 'https://drive.google.com/...',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: linkType,
                decoration: const InputDecoration(labelText: 'Link type'),
                items: const [
                  DropdownMenuItem(
                    value: 'drive_album',
                    child: Text('Photo album'),
                  ),
                  DropdownMenuItem(
                    value: 'drive_folder',
                    child: Text('Folder'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) linkType = value;
                },
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
            child: const Text('Add link'),
          ),
        ],
      ),
    );

    if (submitted != true ||
        titleController.text.trim().isEmpty ||
        urlController.text.trim().isEmpty) {
      return;
    }

    try {
      await _service.addDriveLink(
        albumId: _album!.id,
        title: titleController.text.trim(),
        url: urlController.text.trim(),
        linkType: linkType,
      );
      await _load();
      _showMessage('Google Drive link added.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  bool get _isOwner {
    final album = _album;
    final userId = authSession.user?.id;
    return album != null && album.isOwnedBy(userId);
  }

  Future<void> _editAlbum() async {
    if (_album == null || !_isOwner) return;

    final titleController = TextEditingController(text: _album!.title);
    final descriptionController =
        TextEditingController(text: _album!.description ?? '');

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
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (submitted != true || titleController.text.trim().isEmpty) return;

    try {
      final updated = await _service.updateAlbum(
        albumId: _album!.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _album = updated);
      _showMessage('Album updated.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteAlbum() async {
    if (_album == null || !_isOwner) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete album'),
        content: Text(
          'Delete "${_album!.title}" and all its photos and links? '
          'This cannot be undone.',
        ),
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
      await _service.deleteAlbum(_album!.id);
      if (!mounted) return;
      context.go('/gallery');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final album = _album;
    final externalLinks = album?.externalLinks ?? const <GalleryExternalLink>[];

    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: _GalleryErrorState(
                  message: _error!,
                  onRetry: _load,
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to gallery',
                          onPressed: () => context.go('/gallery'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: Text(
                            album?.title ?? 'Gallery',
                            style: HeadingStyles.contentColumnHeading,
                          ),
                        ),
                        if (_isOwner) ...[
                          IconButton(
                            tooltip: 'Edit album',
                            onPressed: _editAlbum,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete album',
                            onPressed: _deleteAlbum,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ],
                    ),
                    if (album?.description != null) ...[
                      const SizedBox(height: 8),
                      Text(album!.description!),
                    ],
                    if (_isOwner) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _uploading ? null : _uploadPhotos,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_outlined),
                            label: const Text('Upload photos'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _addDriveLink,
                            icon: const Icon(Icons.link),
                            label: const Text('Add Google Drive link'),
                          ),
                        ],
                      ),
                    ],
                    if (externalLinks.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Google Drive',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final link in externalLinks)
                            _DriveLinkCard(
                              link: link,
                              canManage: _isOwner,
                              onEdit: () async {
                                final titleController =
                                    TextEditingController(text: link.title);
                                final urlController =
                                    TextEditingController(text: link.url);
                                var dialogType = link.linkType;

                                final submitted = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Edit Google Drive link'),
                                    content: SizedBox(
                                      width: 420,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: titleController,
                                            decoration: const InputDecoration(
                                              labelText: 'Link name',
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: urlController,
                                            decoration: const InputDecoration(
                                              labelText: 'Google Drive URL',
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          DropdownButtonFormField<String>(
                                            initialValue: dialogType,
                                            decoration: const InputDecoration(
                                              labelText: 'Link type',
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'drive_album',
                                                child: Text('Photo album'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'drive_folder',
                                                child: Text('Folder'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                dialogType = value;
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );

                                if (submitted != true) return;
                                try {
                                  await _service.updateDriveLink(
                                    albumId: _album!.id,
                                    linkId: link.id,
                                    title: titleController.text.trim(),
                                    url: urlController.text.trim(),
                                    linkType: dialogType,
                                  );
                                  await _load();
                                  _showMessage('Link updated.');
                                } on ApiException catch (error) {
                                  _showMessage(error.message);
                                }
                              },
                              onDelete: () async {
                                if (!context.mounted) return;
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete link'),
                                    content: Text('Delete "${link.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                try {
                                  await _service.deleteDriveLink(
                                    albumId: _album!.id,
                                    linkId: link.id,
                                  );
                                  await _load();
                                  _showMessage('Link deleted.');
                                } on ApiException catch (error) {
                                  _showMessage(error.message);
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                    if (_media.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Photos',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _media.length,
                        itemBuilder: (context, index) {
                          final item = _media[index];
                          return Semantics(
                            label: item.caption ?? 'Gallery photo ${index + 1}',
                            button: true,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: InkWell(
                                    onTap: () => MediaLightbox.show(
                                      context,
                                      imageUrl: item.url,
                                      caption: item.caption,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: item.url,
                                        fit: BoxFit.cover,
                                        height: 180,
                                        errorWidget: (_, _, _) =>
                                            const ColoredBox(
                                          color: AppColors.muted,
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.mutedText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isOwner)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.white,
                                      ),
                                      onSelected: (action) async {
                                        if (action == 'edit') {
                                          final captionController =
                                              TextEditingController(
                                            text: item.caption ?? '',
                                          );
                                          final submitted =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title:
                                                  const Text('Edit caption'),
                                              content: TextField(
                                                controller: captionController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Caption',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (submitted != true) return;
                                          try {
                                            await _service.updateMediaCaption(
                                              albumId: _album!.id,
                                              mediaId: item.id,
                                              caption:
                                                  captionController.text.trim(),
                                            );
                                            await _load();
                                            _showMessage('Caption updated.');
                                          } on ApiException catch (error) {
                                            _showMessage(error.message);
                                          }
                                        }

                                        if (action == 'delete') {
                                          if (!context.mounted) return;
                                          final confirmed =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete photo'),
                                              content: const Text(
                                                  'Delete this photo?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed != true) return;
                                          try {
                                            await _service.deleteMedia(
                                              albumId: _album!.id,
                                              mediaId: item.id,
                                            );
                                            await _load();
                                            _showMessage('Photo deleted.');
                                          } on ApiException catch (error) {
                                            _showMessage(error.message);
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit caption'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete photo'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    if (_media.isEmpty &&
                        externalLinks.isEmpty &&
                        _isOwner)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          'No photos yet. Upload from your device or add a '
                          'Google Drive link.',
                          style: GoogleFonts.inter(color: AppColors.bodyText),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

    return MemberLayout(
      currentPath: '/gallery',
      title: 'Gallery',
      child: content,
    );
  }
}

class _GalleryErrorState extends StatelessWidget {
  const _GalleryErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _EmptyGalleryState extends StatelessWidget {
  const _EmptyGalleryState({required this.onCreateAlbum});

  final VoidCallback onCreateAlbum;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined,
              size: 56, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text(
            'No albums yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first album and upload photos or Google Drive links.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onCreateAlbum,
            child: const Text('Create album'),
          ),
        ],
      ),
    );
  }
}

class _DriveLinkCard extends StatelessWidget {
  const _DriveLinkCard({
    required this.link,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final GalleryExternalLink link;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => web.window.open(link.url, '_blank'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_shared_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title.isNotEmpty ? link.title : link.label,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    link.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              if (canManage) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryAlbumCard extends StatelessWidget {
  const _GalleryAlbumCard({
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final String title;
  final String? imageUrl;
  final String? subtitle;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              CoverImage(imageUrl: imageUrl, height: double.infinity)
            else
              const ColoredBox(
                color: AppColors.muted,
                child: Center(
                  child: Icon(
                    Icons.photo_album_outlined,
                    size: 48,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            if (canManage)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(999),
                  child: PopupMenuButton<String>(
                    tooltip: 'Album actions',
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit album'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete album'),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
