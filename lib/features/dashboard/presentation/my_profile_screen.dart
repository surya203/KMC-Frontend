import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/profile_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/membership_api_service.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/compress_profile_photo.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/utils/membership_number_format.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/validators.dart';
import '../widgets/dashboard_layout.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/profile_photo_cropper.dart';

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
  String? _message;
  bool _messageIsError = false;
  Uint8List? _localPhotoBytes;
  int _photoCacheKey = 0;

  late final TextEditingController _currentTitle;
  late final TextEditingController _organization;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final TextEditingController _linkedin;
  late final TextEditingController _phone;
  late final TextEditingController _medicalCouncilNumber;
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
    _medicalCouncilNumber = TextEditingController();
    ProfileSession.instance.addListener(_onProfileSessionChanged);
    AuthSession.instance.addListener(_onAuthSessionChanged);
    _syncPhotoFromSession();
    _load();
  }

  void _onProfileSessionChanged() {
    _syncPhotoFromSession();
  }

  void _onAuthSessionChanged() {
    if (!AuthSession.instance.isAuthenticated) return;
    if (_loading || _profile != null) return;
    _load();
  }

  void _syncPhotoFromSession() {
    final bytes = ProfileSession.instance.photoBytes;
    if (bytes != null && bytes.isNotEmpty && bytes != _localPhotoBytes) {
      if (mounted) setState(() => _localPhotoBytes = bytes);
    }
  }

  @override
  void dispose() {
    ProfileSession.instance.removeListener(_onProfileSessionChanged);
    AuthSession.instance.removeListener(_onAuthSessionChanged);
    _scrollController.dispose();
    _currentTitle.dispose();
    _organization.dispose();
    _city.dispose();
    _bio.dispose();
    _linkedin.dispose();
    _phone.dispose();
    _medicalCouncilNumber.dispose();
    super.dispose();
  }

  Future<void> _load({int attempt = 0}) async {
    await AuthSession.instance.ensureReady();

    if (!AuthSession.instance.isAuthenticated) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Not signed in.';
        _profile = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = attempt == 0;
      if (attempt == 0) _error = null;
    });

    MyProfile? profile;
    MemberMembership? membership;
    Object? profileError;

    try {
      profile = await _profilesApi.fetchMyProfile();
    } catch (e) {
      profileError = e;
      if (attempt < 2 && _shouldRetryRequest(e)) {
        await Future<void>.delayed(
          Duration(milliseconds: 450 * (attempt + 1)),
        );
        if (mounted) {
          await _load(attempt: attempt + 1);
        }
        return;
      }
    }

    if (profile != null) {
      try {
        membership = await _membershipApi.fetchMyMembership();
      } catch (_) {
        membership = _membership;
      }
    }

    if (!mounted) return;

    if (profile != null) {
      _syncEditors(profile);
      await ProfileSession.instance.updateFromProfile(profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _membership = membership;
        _loading = false;
        _error = null;
        _localPhotoBytes = ProfileSession.instance.photoBytes;
      });
      return;
    }

    setState(() {
      _error = formatUserError(profileError ?? 'Profile request failed.');
      _loading = false;
    });
  }

  bool _shouldRetryRequest(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('profile request failed') ||
        message.contains('unable to reach') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket') ||
        message.contains('401') ||
        message.contains('expired');
  }

  void _syncEditors(MyProfile profile) {
    _currentTitle.text = profile.currentTitle ?? '';
    _organization.text = profile.organization ?? '';
    _city.text = profile.city ?? '';
    _bio.text = profile.bio ?? '';
    _linkedin.text = profile.linkedinUrl ?? '';
    _phone.text = _localPhoneNumber(profile.phone);
    _medicalCouncilNumber.text = profile.medicalCouncilNumber ?? '';
    _directoryVisible = profile.isDirectoryVisible ?? true;
  }

  void _toggleEdit() {
    if (_editing) {
      if (_profile != null) _syncEditors(_profile!);
      setState(() {
        _editing = false;
        _message = null;
        _messageIsError = false;
      });
      return;
    }
    setState(() {
      _editing = true;
      _message = null;
      _messageIsError = false;
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
      _messageIsError = false;
    });

    try {
      String? textOrNull(String raw) {
        final value = raw.trim();
        return value.isEmpty ? null : value;
      }

      final phoneError = validateMobileNumber(_phone.text);
      if (phoneError != null) {
        throw FormatException(phoneError);
      }

      final linkedinError = validateLinkedInUrl(_linkedin.text);
      if (linkedinError != null) {
        throw FormatException(linkedinError);
      }

      final bio = _bio.text.trim();
      if (bio.length > 500) {
        throw const FormatException('Bio must be 500 characters or fewer.');
      }

      final mcNumber = _medicalCouncilNumber.text.trim();
      if (!_isMcNumberLocked(_profile!) && mcNumber.isEmpty) {
        throw const FormatException(
          'Medical Council Number is required. Certificates are not needed for existing members.',
        );
      }

      final normalizedLinkedIn = normalizeLinkedInUrl(_linkedin.text);

      final updated = await _profilesApi.updateMyProfile({
        'phone': _phoneForSave(_phone.text),
        'current_title': textOrNull(_currentTitle.text),
        'organization': textOrNull(_organization.text),
        'city': textOrNull(_city.text),
        'bio': textOrNull(bio),
        'linkedin_url': normalizedLinkedIn,
        'is_directory_visible': _directoryVisible,
        if (!_isMcNumberLocked(_profile!))
          'medical_council_number': textOrNull(mcNumber),
      });
      if (!mounted) return;
      _syncEditors(updated);
      if (normalizedLinkedIn != null) {
        _linkedin.text = normalizedLinkedIn;
      }
      await ProfileSession.instance.updateFromProfile(updated);
      setState(() {
        _profile = updated;
        _editing = false;
        _saving = false;
        _message = 'Profile updated successfully.';
        _messageIsError = false;
      });
      _showFeedback('Profile updated successfully.');
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = e.message;
        _messageIsError = true;
      });
      _showFeedback(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      final message = formatUserError(e);
      setState(() {
        _saving = false;
        _message = message;
        _messageIsError = true;
      });
      _showFeedback(message, isError: true);
    }
  }

  static const _maxPhotoBytes = 3 * 1024 * 1024;

  Future<void> _uploadPhotoFile(PlatformFile file) async {
    if (file.bytes == null || file.bytes!.isEmpty) {
      throw Exception('Could not read image file.');
    }
    if (file.bytes!.length > _maxPhotoBytes) {
      throw Exception('Profile photo must be 3 MB or smaller.');
    }
    if (!looksLikeImageBytes(file.bytes!)) {
      throw Exception('Please choose a valid JPG or PNG image.');
    }

    await AuthSession.instance.ensureReady();
    final authId = AuthSession.instance.currentUser?.id;
    if (authId == null) throw Exception('Not signed in.');

    setState(() {
      _uploadingPhoto = true;
      _message = null;
      _messageIsError = false;
      _localPhotoBytes = file.bytes;
    });

    // Save locally first so photo shows immediately and survives refresh.
    await ProfileSession.instance.saveLocalPreview(file.bytes!);

    try {
      final uploadedUrl = await _profilesApi.uploadProfilePhoto(file);
      final profile = await _profilesApi.fetchMyProfile();
      final effectiveUrl = profile.photoUrl ?? uploadedUrl;
      final resolvedPhoto = resolveMediaUrl(effectiveUrl);
      await ProfileSession.instance.setPhoto(
        profileId: profile.id,
        url: resolvedPhoto,
        bytes: ProfileSession.instance.photoBytes ?? file.bytes!,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile.copyWith(photoUrl: resolvedPhoto);
        _localPhotoBytes = ProfileSession.instance.photoBytes;
        _uploadingPhoto = false;
        _photoCacheKey++;
      });
      _showFeedback('Photo updated successfully.');
    } catch (e) {
      if (!mounted) return;
      final message = formatUserError(e);
      setState(() {
        _uploadingPhoto = false;
        _message = message;
        _messageIsError = true;
      });
      _showFeedback(message, isError: true);
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final file = await pickAndCropProfilePhoto(context);
      if (file == null) return;
      await _uploadPhotoFile(file);
    } catch (e) {
      if (!mounted) return;
      _showFeedback(formatUserError(e), isError: true);
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final captured = await captureImageWithLivePreview(context);
      if (captured == null) return;
      if (!mounted) return;
      final cropped = await cropProfilePhotoFile(
        context,
        bytes: captured.bytes,
        fileName: captured.fileName,
      );
      if (cropped == null) return;
      await _uploadPhotoFile(cropped);
    } catch (e) {
      if (!mounted) return;
      _showFeedback(formatUserError(e), isError: true);
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _uploadingPhoto = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      await _profilesApi.removeProfilePhoto();
      final profile = await _profilesApi.fetchMyProfile();
      await ProfileSession.instance.clearPhoto();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _localPhotoBytes = null;
        _uploadingPhoto = false;
        _photoCacheKey++;
      });
      _showFeedback('Photo removed.');
    } catch (e) {
      if (!mounted) return;
      final message = formatUserError(e);
      setState(() {
        _uploadingPhoto = false;
        _message = message;
        _messageIsError = true;
      });
      _showFeedback(message, isError: true);
    }
  }

  bool get _hasPhoto {
    final bytes =
        ProfileSession.instance.photoBytes ?? _localPhotoBytes;
    return bytes != null && bytes.isNotEmpty;
  }

  Widget _photoMenuRow(
    IconData icon,
    String label, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.heading),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? AppColors.heading,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCameraButton() {
    final badge = Material(
      elevation: 2,
      color: AppColors.secondary,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white, width: 2),
      ),
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
    );

    if (_uploadingPhoto) {
      return badge;
    }

    return PopupMenuButton<String>(
      tooltip: 'Change profile photo',
      offset: const Offset(-4, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: Colors.white,
      elevation: 6,
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        switch (value) {
          case 'upload':
            await _pickPhotoFromGallery();
          case 'camera':
            await _capturePhoto();
          case 'remove':
            await _removePhoto();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'upload',
          height: 42,
          child: _photoMenuRow(Icons.upload_outlined, 'Upload photo'),
        ),
        PopupMenuItem<String>(
          value: 'camera',
          height: 42,
          child: _photoMenuRow(Icons.photo_camera_outlined, 'Take photo'),
        ),
        if (_hasPhoto) ...[
          const PopupMenuDivider(height: 8),
          PopupMenuItem<String>(
            value: 'remove',
            height: 42,
            child: _photoMenuRow(
              Icons.delete_outline,
              'Remove photo',
              color: AppColors.error,
            ),
          ),
        ],
      ],
      child: badge,
    );
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
    return digits;
  }

  String get _email => AuthSession.instance.currentUser?.email ?? '—';

  String _membershipId(MyProfile profile) {
    return MembershipNumberFormat.displayOrFallback(
      storedMembershipNumber: _membership?.membershipNumber ??
          AuthSession.instance.currentUser?.membershipNumber,
      batchYear: profile.batchYear,
      fullName: profile.fullName,
      fallback: '—',
    );
  }

  bool _hasMcNumber(MyProfile profile) =>
      profile.medicalCouncilNumber?.trim().isNotEmpty ?? false;

  /// Existing approved members may fill a missing MC once; after that it locks.
  /// New joiners stay editable until admin approval, then lock when MC is present.
  bool _isMcNumberLocked(MyProfile profile) {
    return profile.verificationStatus == 'approved' && _hasMcNumber(profile);
  }

  bool _needsMcNumber(MyProfile profile) => !_hasMcNumber(profile);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: DashboardLayout.screenPadding(context),
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
                _StatusBanner(
                  message: _message!,
                  isError: _messageIsError,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    final isCompact = DashboardLayout.isCompact(context);

    final subtitle = Text(
      'Manage your MY KMC profile and membership details.',
      style: GoogleFonts.inter(
        fontSize: isCompact ? 14 : 15,
        color: AppColors.bodyText,
        height: 1.5,
      ),
    );

    final editActions = _editing
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : _toggleEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.heading,
                  side: const BorderSide(color: AppColors.border),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 20,
                    vertical: isCompact ? 12 : 14,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 20,
                    vertical: isCompact ? 12 : 14,
                  ),
                ),
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          )
        : ElevatedButton.icon(
            onPressed: _profile == null ? null : _toggleEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 20,
                vertical: isCompact ? 12 : 14,
              ),
            ),
          );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subtitle,
          const SizedBox(height: 12),
          editActions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: subtitle,
        ),
        const SizedBox(width: 16),
        editActions,
      ],
    );
  }

  Widget _buildProfileSummary(MyProfile profile) {
    final isCompact = DashboardLayout.isCompact(context);
    final avatarSize = isCompact ? 80.0 : 88.0;

    final avatar = SizedBox(
      width: avatarSize + 8,
      height: avatarSize + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: ProfileAvatar(
              localBytes:
                  ProfileSession.instance.photoBytes ?? _localPhotoBytes,
              networkUrl: ProfileSession.instance.photoUrl ?? profile.photoUrl,
              name: profile.fullName,
              size: avatarSize,
              cacheKey: _photoCacheKey,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _buildPhotoCameraButton(),
          ),
        ],
      ),
    );

    final name = Text(
      profile.fullName,
      maxLines: 3,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.fraunces(
        fontSize: isCompact ? 24 : 28,
        fontWeight: FontWeight.w600,
        color: AppColors.heading,
        height: 1.15,
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(height: 14),
          name,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 18),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: name,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(MyProfile profile) {
    final cardPadding = DashboardLayout.cardPadding(context) + 4;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
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
                'You can update your mobile number, photo, alumni directory details, and Medical Council Number if missing. Name, batch and email are locked. Existing members do not need certificates.',
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
              final wide = constraints.maxWidth > 700;
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
                    label: 'MEMBERSHIP ID',
                    value: _membershipId(profile),
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  if (_editing && !_isMcNumberLocked(profile))
                    _formField(
                      label: 'MEDICAL COUNCIL NUMBER',
                      controller: _medicalCouncilNumber,
                      hintText: 'e.g. KMC/12345',
                      helperText:
                          'Required for existing members. Certificates are not needed — only MC number.',
                    )
                  else
                    _formField(
                      label: 'MEDICAL COUNCIL NUMBER',
                      value: _hasMcNumber(profile)
                          ? profile.medicalCouncilNumber
                          : 'Not added yet',
                      readOnly: true,
                    ),
                  if (_needsMcNumber(profile) && !_editing)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _StatusBanner(
                        message:
                            'Please add your Medical Council Number (Edit → Save). '
                            'Existing members do not need to upload certificates. '
                            'After admin approval, MC number stays locked.',
                        isError: true,
                      ),
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
                      hintText: 'e.g. Consultant Cardiologist',
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      label: 'ORGANIZATION',
                      controller: _organization,
                      hintText: 'e.g. Apollo Hospitals, Hyderabad',
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      label: 'CITY',
                      controller: _city,
                      hintText: 'e.g. Hyderabad, India',
                    ),
                    const SizedBox(height: 16),
                    _formField(
                      label: 'BIO',
                      controller: _bio,
                      maxLines: 4,
                      hintText:
                          'A short professional summary for the alumni directory.',
                      helperText: 'Maximum 500 characters',
                    ),
                    if (_isMcNumberLocked(profile)) ...[
                      const SizedBox(height: 16),
                      _formField(
                        label: 'MEDICAL COUNCIL NUMBER',
                        controller: _medicalCouncilNumber,
                        hintText: 'e.g. KMC/12345',
                        readOnly: true,
                        helperText: 'Locked — approved by admin',
                      ),
                    ],
                    const SizedBox(height: 16),
                    _formField(
                      label: 'LINKEDIN URL',
                      controller: _linkedin,
                      keyboardType: TextInputType.url,
                      hintText: 'https://www.linkedin.com/in/your-name',
                      helperText:
                          'Example: https://www.linkedin.com/in/sooraj-bhardwaj',
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

    final visible = profile.isDirectoryVisible ?? true;

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
      if (items.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Your alumni directory profile is not complete yet. Tap Edit to add your title, organization, city, bio and LinkedIn URL.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.bodyText,
              height: 1.5,
            ),
          ),
        )
      else
        ...items,
      const SizedBox(height: 20),
      _formField(
        label: 'DIRECTORY VISIBILITY',
        value: visible ? 'Visible in alumni directory' : 'Hidden from alumni directory',
        readOnly: true,
      ),
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
    String? hintText,
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
            maxLength: label == 'BIO' ? 500 : null,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: label == 'BIO'
                ? (_, {required currentLength, required isFocused, maxLength}) =>
                    null
                : null,
            keyboardType: isMobileNumber ? TextInputType.number : keyboardType,
            inputFormatters:
                isMobileNumber ? mobileNumberInputFormatters : null,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.heading),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? AppColors.background : Colors.white,
              hintText: hintText,
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
          inputFormatters: mobileNumberInputFormatters,
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
            helperText: 'Enter 10 digits without country code.',
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: isError ? AppColors.error : AppColors.heading,
                height: 1.4,
              ),
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
              formatUserError(message),
              style: GoogleFonts.inter(color: AppColors.warning),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
