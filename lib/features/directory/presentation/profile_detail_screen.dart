import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/membership_number_format.dart';
import '../../../core/utils/open_external_url.dart';
import '../../../core/utils/resilient_profile_image.dart';

/// Member-only alumni profile page (opened inside dashboard shell).
class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({
    super.key,
    required this.profileId,
  });

  final String profileId;

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _api = ProfilesApiService();
  ProfileDetail? _profile;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.fetchProfileById(widget.profileId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 8, compact ? 16 : 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/member/alumni-roll');
                  }
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Alumni Member'),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 8, compact ? 16 : 24, 72),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      )
                    : _error != null
                        ? _ErrorState(message: _error!, onRetry: _loadProfile)
                        : _FullAlumniProfile(profile: _profile!, compact: compact),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullAlumniProfile extends StatelessWidget {
  const _FullAlumniProfile({required this.profile, required this.compact});

  final ProfileDetail profile;
  final bool compact;

  String get _displayName => _titleCase(profile.fullName);

  String get _membershipId {
    final raw = profile.membershipNumber?.trim() ?? '';
    if (raw.isEmpty) return '';
    if (!raw.toUpperCase().startsWith('KMC-')) return raw;
    return MembershipNumberFormat.displayOrFallback(
      storedMembershipNumber: raw,
      batchYear: profile.batchYear,
      fullName: profile.fullName,
      fallback: raw,
    );
  }

  String get _mobile =>
      _nonEmpty(profile.phone) ? _phoneWithCountryCode(profile.phone!) : '';

  String get _locationLine {
    final parts = <String>[];
    if (_nonEmpty(profile.city)) parts.add(_titleCase(profile.city!));
    if (_nonEmpty(profile.practiceLocation) &&
        profile.practiceLocation!.toLowerCase() != profile.city?.toLowerCase()) {
      parts.add(_titleCase(profile.practiceLocation!));
    }
    if (_nonEmpty(profile.country)) parts.add(profile.country!.toUpperCase());
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final membershipId = _membershipId;
    final mobile = _mobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(
          compact: compact,
          photoUrl: profile.photoUrl,
          displayName: _displayName,
          batchYear: profile.batchYear,
          membershipId: membershipId,
          degree: profile.degree,
          specialization: profile.specialization,
          currentTitle: profile.currentTitle,
          organization: profile.organization,
          locationLine: _locationLine,
        ),
        const SizedBox(height: 20),
        _DetailsPanel(
          compact: compact,
          title: 'Identity',
          rows: [
            _Field('Full name', _displayName),
            _Field('Batch year', 'Batch ${profile.batchYear}'),
            _Field('Membership ID', membershipId),
          ],
        ),
        const SizedBox(height: 16),
        _DetailsPanel(
          compact: compact,
          title: 'Education',
          rows: [
            _Field('Degree', profile.degree),
            _Field('Specialty / category', profile.specialization),
          ],
        ),
        const SizedBox(height: 16),
        _DetailsPanel(
          compact: compact,
          title: 'Professional',
          rows: [
            _Field('Current title', profile.currentTitle),
            _Field('Organization', profile.organization),
          ],
        ),
        const SizedBox(height: 16),
        _DetailsPanel(
          compact: compact,
          title: 'Contact',
          rows: [
            _Field('Mobile', mobile.isEmpty ? null : mobile),
            _Field('LinkedIn', profile.linkedinUrl, isLink: true),
          ],
          trailing: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (mobile.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _copy(
                    context,
                    mobile,
                    'Mobile number copied with country code',
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy mobile'),
                ),
              if (mobile.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _call(mobile),
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: const Text('Call'),
                ),
              if (membershipId.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _copy(
                    context,
                    membershipId,
                    'Membership ID copied',
                  ),
                  icon: const Icon(Icons.badge_outlined, size: 16),
                  label: const Text('Copy Membership ID'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DetailsPanel(
          compact: compact,
          title: 'Location',
          rows: [
            _Field('City', profile.city == null ? null : _titleCase(profile.city!)),
            _Field(
              'Practice location',
              profile.practiceLocation == null
                  ? null
                  : _titleCase(profile.practiceLocation!),
            ),
            _Field(
              'Country',
              _nonEmpty(profile.country) ? profile.country!.toUpperCase() : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DetailsPanel(
          compact: compact,
          title: 'About',
          rows: [
            _Field('Bio', profile.bio, multiline: true),
          ],
        ),
      ],
    );
  }

  static bool _nonEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String _phoneWithCountryCode(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return phone.trim();
    if (digits.startsWith('91') && digits.length >= 12) {
      return '+$digits';
    }
    if (digits.length == 10) {
      return '+91 $digits';
    }
    if (phone.trim().startsWith('+')) {
      return phone.trim();
    }
    return '+91 $digits';
  }

  static String _titleCase(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) return part;
          if (part.length == 1) return part.toUpperCase();
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static Future<void> _copy(
    BuildContext context,
    String value,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1F6B3A),
      ),
    );
  }

  static Future<void> _call(String mobile) async {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: '+$digits');
    await launchUrl(uri);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.compact,
    required this.photoUrl,
    required this.displayName,
    required this.batchYear,
    required this.membershipId,
    required this.degree,
    required this.specialization,
    required this.currentTitle,
    required this.organization,
    required this.locationLine,
  });

  final bool compact;
  final String? photoUrl;
  final String displayName;
  final int batchYear;
  final String membershipId;
  final String? degree;
  final String? specialization;
  final String? currentTitle;
  final String? organization;
  final String locationLine;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _Chip(label: 'Batch $batchYear'),
      if (membershipId.isNotEmpty) _Chip(label: membershipId, emphasize: true),
      if (_has(specialization)) _Chip(label: specialization!),
      if (_has(degree) &&
          degree!.toLowerCase() != specialization?.toLowerCase())
        _Chip(label: degree!),
    ];

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alumni profile',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          displayName,
          style: GoogleFonts.fraunces(
            fontSize: compact ? 28 : 36,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        if (_has(currentTitle)) ...[
          const SizedBox(height: 14),
          Text(
            currentTitle!,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.heading,
            ),
          ),
        ],
        if (_has(organization))
          Text(
            organization!,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.bodyText),
          ),
        if (locationLine.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  locationLine,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              children: [
                _ProfilePhoto(url: photoUrl, size: 120),
                const SizedBox(height: 18),
                textBlock,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfilePhoto(url: photoUrl, size: 140),
                const SizedBox(width: 28),
                Expanded(child: textBlock),
              ],
            ),
    );
  }

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.title,
    required this.rows,
    required this.compact,
    this.trailing,
  });

  final String title;
  final List<_Field> rows;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 24),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _FieldRow(field: row, compact: compact),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _Field {
  const _Field(this.label, this.value, {this.isLink = false, this.multiline = false});

  final String label;
  final String? value;
  final bool isLink;
  final bool multiline;
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field, required this.compact});

  final _Field field;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasValue = field.value != null && field.value!.trim().isNotEmpty;
    final valueStyle = GoogleFonts.inter(
      fontSize: 15,
      height: field.multiline ? 1.65 : 1.4,
      color: hasValue ? AppColors.heading : AppColors.mutedText,
      fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
    );

    Widget valueWidget;
    if (!hasValue) {
      valueWidget = Text('Not shared', style: valueStyle);
    } else if (field.isLink) {
      valueWidget = InkWell(
        onTap: () => openExternalUrl(field.value!),
        child: Text(
          field.value!,
          style: valueStyle.copyWith(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      valueWidget = Text(field.value!, style: valueStyle);
    }

    final label = Text(
      field.label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: AppColors.mutedText,
      ),
    );

    if (compact || field.multiline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 6),
          valueWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 180, child: label),
        Expanded(child: valueWidget),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.emphasize = false});

  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: emphasize ? const Color(0xFFEAF4EE) : const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasize ? const Color(0xFFB9D8C4) : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: emphasize ? AppColors.primary : AppColors.heading,
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({this.url, this.size = 120});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ResilientProfileImage(
      photoUrl: url,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(16),
      fallback: _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: AppColors.muted,
      child: Icon(Icons.person, size: size * 0.4, color: AppColors.primary),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.bodyText, height: 1.5),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
