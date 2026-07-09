import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/profiles_api_service.dart';

class ProfileEditorSection extends StatefulWidget {
  const ProfileEditorSection({super.key});

  @override
  State<ProfileEditorSection> createState() => _ProfileEditorSectionState();
}

class _ProfileEditorSectionState extends State<ProfileEditorSection> {
  final _api = ProfilesApiService();
  final _formKey = GlobalKey<FormState>();

  MyProfile? _profile;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _message;

  late final TextEditingController _currentTitle;
  late final TextEditingController _organization;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final TextEditingController _linkedin;
  bool _directoryVisible = true;

  @override
  void initState() {
    super.initState();
    _currentTitle = TextEditingController();
    _organization = TextEditingController();
    _city = TextEditingController();
    _bio = TextEditingController();
    _linkedin = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _currentTitle.dispose();
    _organization.dispose();
    _city.dispose();
    _bio.dispose();
    _linkedin.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final profile = await _api.fetchMyProfile();
      if (!mounted) return;
      _currentTitle.text = profile.currentTitle ?? '';
      _organization.text = profile.organization ?? '';
      _city.text = profile.city ?? '';
      _bio.text = profile.bio ?? '';
      _linkedin.text = profile.linkedinUrl ?? '';
      setState(() {
        _profile = profile;
        _directoryVisible = profile.isDirectoryVisible ?? true;
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final updated = await _api.updateMyProfile({
        'current_title': _currentTitle.text.trim(),
        'organization': _organization.text.trim(),
        'city': _city.text.trim(),
        'bio': _bio.text.trim(),
        'linkedin_url': _linkedin.text.trim(),
        'is_directory_visible': _directoryVisible,
      });
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _saving = false;
        _message = 'Profile saved.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = e.toString();
      });
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;

    setState(() {
      _uploadingPhoto = true;
      _message = null;
    });

    try {
      await _api.uploadProfilePhoto(file);
      if (!mounted) return;
      await _loadProfile(silent: true);
      if (!mounted) return;
      setState(() {
        _uploadingPhoto = false;
        _message = 'Photo updated.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingPhoto = false;
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: GoogleFonts.inter(color: AppColors.warning)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadProfile, child: const Text('Retry')),
        ],
      );
    }

    final profile = _profile!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alumni profile',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.fullName,
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.heading,
              ),
            ),
            Text(
              'Batch ${profile.batchYear}'
              '${profile.verificationStatus != null ? ' · ${profile.verificationStatus}' : ''}',
              style: GoogleFonts.inter(color: AppColors.bodyText),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ClipOval(
                  child: profile.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: profile.photoUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _uploadingPhoto ? null : _pickPhoto,
                  icon: _uploadingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: const Text('Upload photo'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _field('Current title', _currentTitle),
            const SizedBox(height: 16),
            _field('Organization', _organization),
            const SizedBox(height: 16),
            _field('City', _city),
            const SizedBox(height: 16),
            _field('Bio', _bio, maxLines: 4),
            const SizedBox(height: 16),
            _field('LinkedIn URL', _linkedin),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show in alumni directory'),
              value: _directoryVisible,
              onChanged: (v) => setState(() => _directoryVisible = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(_saving ? 'Saving…' : 'Save profile'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: GoogleFonts.inter(color: AppColors.bodyText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.muted,
      child: const Icon(Icons.person, color: AppColors.primary, size: 36),
    );
  }
}
