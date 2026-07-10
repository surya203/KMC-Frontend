import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

String gallerySlugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}

Future<({String slug, String title, String? description})?> showCreateAlbumDialog(
  BuildContext context,
) {
  final titleController = TextEditingController();
  final slugController = TextEditingController();
  final descriptionController = TextEditingController();
  var slugEdited = false;

  return showDialog<({String slug, String title, String? description})?>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              'Create album',
              style: GoogleFonts.fraunces(
                color: AppColors.heading,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Album title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (!slugEdited) {
                        slugController.text = gallerySlugify(value);
                        setLocalState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: slugController,
                    decoration: const InputDecoration(
                      labelText: 'URL slug',
                      border: OutlineInputBorder(),
                      helperText: 'Used in the gallery link',
                    ),
                    onChanged: (_) {
                      slugEdited = true;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final slug = slugController.text.trim();
                  if (title.isEmpty || slug.isEmpty) return;
                  Navigator.of(context).pop((
                    slug: slug,
                    title: title,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<({String title, String? description})?> showEditAlbumDialog(
  BuildContext context, {
  required String initialTitle,
  String? initialDescription,
}) {
  final titleController = TextEditingController(text: initialTitle);
  final descriptionController =
      TextEditingController(text: initialDescription ?? '');

  return showDialog<({String title, String? description})?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Edit album',
          style: GoogleFonts.fraunces(
            color: AppColors.heading,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Album title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context).pop((
                title: title,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<({String title, String url, String linkType})?> showDriveLinkDialog(
  BuildContext context, {
  String? initialTitle,
  String? initialUrl,
  String initialLinkType = 'drive_folder',
}) {
  final titleController = TextEditingController(text: initialTitle ?? '');
  final urlController = TextEditingController(text: initialUrl ?? '');
  var linkType = initialLinkType;

  return showDialog<({String title, String url, String linkType})?>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              initialTitle == null ? 'Add Drive link' : 'Edit Drive link',
              style: GoogleFonts.fraunces(
                color: AppColors.heading,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Link title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Google Drive URL',
                      border: OutlineInputBorder(),
                      helperText: 'Must start with https://drive.google.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: linkType,
                    decoration: const InputDecoration(
                      labelText: 'Link type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'drive_folder',
                        child: Text('Drive folder'),
                      ),
                      DropdownMenuItem(
                        value: 'drive_album',
                        child: Text('Drive album'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => linkType = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final url = urlController.text.trim();
                  if (title.isEmpty || url.isEmpty) return;
                  Navigator.of(context).pop((
                    title: title,
                    url: url,
                    linkType: linkType,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                ),
                child: Text(initialTitle == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(title, style: GoogleFonts.fraunces(color: AppColors.heading)),
      content: Text(message, style: GoogleFonts.inter(color: AppColors.bodyText)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
