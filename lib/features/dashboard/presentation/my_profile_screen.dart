import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/membership_api_service.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/utils/validators.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final _profilesApi = ProfilesApiService();
  final _membershipApi = MembershipApiService();
  final _scrollController = ScrollController();
  final _editSectionKey = GlobalKey();

  MyProfile? _profile;
  MemberMembership? _membership;
  String? _error;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  bool _showPhotoOptions = false;
  String? _message;

  late final TextEditingController _currentTitle;
  late final TextEditingController _organization;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final TextEditingController _linkedin;
  late final TextEditingController _phone;
  bool _directoryVisible = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentTitle = TextEditingController();
    _organization = TextEditingController();
    _city = TextEditingController();
    _bio = TextEditingController();
    _linkedin = TextEditingController();
    _phone = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _currentTitle.dispose();
    _organization.dispose();
    _city.dispose();
    _bio.dispose();
    _linkedin.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _profilesApi.fetchMyProfile(),
        _membershipApi.fetchMyMembership(),
      ]);

      if (!mounted) return;
      final profile = results[0] as MyProfile;
      _syncEditors(profile);
      setState(() {
        _profile = profile;
        _membership = results[1] as MemberMembership;
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

  void _syncEditors(MyProfile profile) {
    _currentTitle.text = profile.currentTitle ?? '';
    _organization.text = profile.organization ?? '';
    _city.text = profile.city ?? '';
    _bio.text = profile.bio ?? '';
    _linkedin.text = profile.linkedinUrl ?? '';
    _phone.text = _localPhoneNumber(profile.phone);
    _directoryVisible = profile.isDirectoryVisible ?? true;
  }

  void _toggleEdit() {
    if (_editing) {
      if (_profile != null) _syncEditors(_profile!);
      setState(() {
        _editing = false;
        _message = null;
      });
      return;
    }
    setState(() {
      _editing = true;
      _message = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _editSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  void _showFeedback(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      String? textOrNull(String raw) {
        final value = raw.trim();
        return value.isEmpty ? null : value;
      }

      final phoneError = validateMobileNumber(_phone.text);
      if (phoneError != null) {
        throw Exception(phoneError);
      }

      final updated = await _profilesApi.updateMyProfile({
        'phone': _phoneForSave(_phone.text),
        'current_title': textOrNull(_currentTitle.text),
        'organization': textOrNull(_organization.text),
        'city': textOrNull(_city.text),
        'bio': textOrNull(_bio.text),
        'linkedin_url': textOrNull(_linkedin.text),
        'is_directory_visible': _directoryVisible,
      });
      if (!mounted) return;
      _syncEditors(updated);
      setState(() {
        _profile = updated;
        _editing = false;
        _saving = false;
        _message = 'Profile updated.';
      });
      _showFeedback('Profile updated.');
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = e.message;
      });
      _showFeedback(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = e.toString();
      });
      _showFeedback(e.toString(), isError: true);
    }
  }

  static const _maxPhotoBytes = 3 * 1024 * 1024;

  Future<PlatformFile?> _pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    final file = result?.files.single;
    if (file == null) return null;

    if (file.bytes != null && file.bytes!.isNotEmpty) return file;

    final stream = file.readStream;
    if (stream != null) {
      final chunks = await stream.toList();
      final bytes = Uint8List.fromList(chunks.expand((chunk) => chunk).toList());
      if (bytes.isEmpty) throw Exception('Could not read image file.');
      return PlatformFile(
        name: file.name,
        size: bytes.length,
        bytes: bytes,
      );
    }

    throw Exception('Could not read image file. Try a smaller JPG or PNG.');
  }

  Future<void> _uploadPhotoFile(PlatformFile file) async {
    if (file.bytes == null || file.bytes!.isEmpty) {
      throw Exception('Could not read image file.');
    }
    if (file.bytes!.length > _maxPhotoBytes) {
      throw Exception('Profile photo must be 3 MB or smaller.');
    }

    setState(() {
      _uploadingPhoto = true;
      _showPhotoOptions = false;
      _message = null;
    });

    try {
      await _profilesApi.uploadProfilePhoto(file);
      final profile = await _profilesApi.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _uploadingPhoto = false;
      });
      _showFeedback('Photo updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingPhoto = false;
        _message = e.toString();
      });
      _showFeedback(e.toString(), isError: true);
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final file = await _pickImageFile();
      if (file == null) return;
      await _uploadPhotoFile(file);
    } catch (e) {
      if (!mounted) return;
      _showFeedback(e.toString(), isError: true);
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _showPhotoOptions = false);
    try {
      final captured = await captureImageWithLivePreview(context);
      if (captured == null) return;
      await _uploadPhotoFile(
        PlatformFile(
          name: captured.fileName,
          size: captured.bytes.length,
          bytes: captured.bytes,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showFeedback(e.toString(), isError: true);
    }
  }

  static const _indiaCountryCode = '+91';

  String _localPhoneNumber(String? phone) {
    final raw = (phone ?? '').trim();
    if (raw.startsWith('+91')) {
      return raw.substring(3).trim();
    }
    if (raw.startsWith('91') && raw.length > 10) {
      return raw.substring(2).trim();
    }
    return raw;
  }

  String _displayPhone(String? phone) {
    final local = _localPhoneNumber(phone);
    if (local.isEmpty) return '—';
    return '$_indiaCountryCode $local';
  }

  String? _phoneForSave(String local) {
    final digits = local.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return '$_indiaCountryCode$digits';
  }

  String get _email => AuthSession.instance.currentUser?.email ?? '—';

  String get _username {
    final email = _email;
    if (email == '—') return '—';
    final at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return email;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 24),
              if (_error != null) ...[
                _InlineError(message: _error!, onRetry: _load),
                const SizedBox(height: 16),
              ],
              if (_profile != null) ...[
                _buildProfileSummary(_profile!),
                const SizedBox(height: 24),
                _buildDetailsCard(_profile!),
              ],
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
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Profile',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your MY KMC profile and membership details.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.bodyText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (_editing) ...[
          OutlinedButton(
            onPressed: _saving ? null : _toggleEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.heading,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ] else
          ElevatedButton.icon(
            onPressed: _profile == null ? null : _toggleEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileSummary(MyProfile profile) {
    final initial = profile.fullName.isNotEmpty
        ? profile.fullName.trim()[0].toUpperCase()
        : 'K';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: ClipOval(
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: profile.photoUrl != null
                            ? CachedNetworkImage(
                                key: ValueKey(profile.photoUrl),
                                imageUrl: profile.photoUrl!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    _avatarPlaceholder(initial),
                              )
                            : _avatarPlaceholder(initial),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      elevation: 2,
                      color: AppColors.secondary,
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white, width: 2),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploadingPhoto
                            ? null
                            : () => setState(() => _showPhotoOptions = true),
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Center(
                            child: _uploadingPhoto
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showPhotoOptions) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: _uploadingPhoto ? null : _capturePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    tooltip: 'Open camera',
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _uploadingPhoto ? null : _pickPhotoFromGallery,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Upload photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.heading,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(width: 18),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            profile.fullName,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder(String initial) {
    return Container(
      width: 88,
      height: 88,
      color: AppColors.muted,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
        ),
      ),
    );
  }

  Widget _buildDetailsCard(MyProfile profile) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _editing ? AppColors.secondary : AppColors.border,
          width: _editing ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_editing) ...[
            Container(
              key: _editSectionKey,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'You can update your mobile number, photo, and alumni directory details. Name, batch, and email are locked.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.heading,
                  height: 1.4,
                ),
              ),
            ),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 600;
              return Column(
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _formField(
                            label: 'FULL NAME',
                            value: profile.fullName,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _formField(
                            label: 'BATCH YEAR',
                            value: '${profile.batchYear}',
                            readOnly: true,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _formField(
                      label: 'FULL NAME',
                      value: profile.fullName,
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    _formField(
                      label: 'BATCH YEAR',
                      value: '${profile.batchYear}',
                      readOnly: true,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _formField(
                    label: 'SPECIALIZATION',
                    value: profile.specialization ?? '—',
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _editing
                              ? _mobileNumberField()
                              : _formField(
                                  label: 'MOBILE NUMBER',
                                  value: _displayPhone(profile.phone),
                                  readOnly: true,
                                ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _formField(
                            label: 'EMAIL',
                            value: _email,
                            readOnly: true,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _editing
                        ? _mobileNumberField()
                        : _formField(
                            label: 'MOBILE NUMBER',
                            value: _displayPhone(profile.phone),
                            readOnly: true,
                          ),
                    const SizedBox(height: 20),
                    _formField(
                      label: 'EMAIL',
                      value: _email,
                      readOnly: true,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _formField(
                    label: 'USERNAME',
                    value: _username,
                    readOnly: true,
                  ),
                  if (!_editing) ..._buildDirectoryViewFields(profile),
                  if (_editing) ...[
                    const SizedBox(height: 28),
                    Divider(color: AppColors.border.withValues(alpha: 0.8)),
                    const SizedBox(height: 20),
                    Text(
                      'Alumni directory profile',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      label: 'CURRENT TITLE',
                      controller: _currentTitle,
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      label: 'ORGANIZATION',
                      controller: _organization,
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      label: 'CITY',
                      controller: _city,
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      label: 'BIO',
                      controller: _bio,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      label: 'LINKEDIN URL',
                      controller: _linkedin,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Show in alumni directory',
                          style: GoogleFonts.inter(color: AppColors.bodyText),
                        ),
                        value: _directoryVisible,
                        onChanged: (v) => setState(() => _directoryVisible = v),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _membershipBanner(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDirectoryViewFields(MyProfile profile) {
    final items = <Widget>[];

    void add(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      if (items.isNotEmpty) items.add(const SizedBox(height: 20));
      items.add(_formField(label: label, value: value, readOnly: true));
    }

    add('CURRENT TITLE', profile.currentTitle);
    add('ORGANIZATION', profile.organization);
    add('CITY', profile.city);
    add('BIO', profile.bio);
    add('LINKEDIN URL', profile.linkedinUrl);

    if (items.isEmpty) return items;

    return [
      const SizedBox(height: 28),
      Divider(color: AppColors.border.withValues(alpha: 0.8)),
      const SizedBox(height: 20),
      Text(
        'Alumni directory profile',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.mutedText,
        ),
      ),
      const SizedBox(height: 16),
      ...items,
    ];
  }

  Widget _formField({
    required String label,
    String? value,
    TextEditingController? controller,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? helperText,
    bool isMobileNumber = false,
  }) {
    assert(value != null || controller != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.mutedText,
              ),
            ),
            if (readOnly && _editing) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline,
                size: 12,
                color: AppColors.mutedText.withValues(alpha: 0.8),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (value != null && controller == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.heading,
              ),
            ),
          )
        else
          TextField(
            controller: controller,
            readOnly: readOnly,
            enabled: _editing,
            maxLines: maxLines,
            keyboardType: isMobileNumber ? TextInputType.number : keyboardType,
            inputFormatters:
                isMobileNumber ? mobileNumberInputFormatters : null,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.heading),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? AppColors.background : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _editing && !readOnly
                      ? AppColors.secondary
                      : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: readOnly ? AppColors.border : AppColors.primary,
                  width: readOnly ? 1 : 1.5,
                ),
              ),
              helperText: helperText,
            ),
          ),
      ],
    );
  }

  Widget _mobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOBILE NUMBER',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.heading),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixText: '$_indiaCountryCode ',
            prefixStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
            hintText: '9876543210',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _membershipBanner() {
    final isActive = _membership?.status == 'active';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isActive ? 'Membership active' : 'Membership pending',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive
                ? '${_membership?.planName ?? 'Life'} membership valid forever.'
                : 'Complete payment to activate your membership.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.bodyText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: AppColors.warning),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
