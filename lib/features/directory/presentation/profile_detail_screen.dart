import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key, required this.profileId});

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
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to home'),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 72),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        )
                      : _error != null
                          ? Text(
                              _error!,
                              style: GoogleFonts.inter(color: AppColors.bodyText),
                            )
                          : _buildContent(_profile!),
                ),
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ProfileDetail profile) {
    final location = [profile.city, profile.country]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfilePhoto(url: profile.photoUrl),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: GoogleFonts.fraunces(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Batch ${profile.batchYear}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.bodyText,
                    ),
                  ),
                  if (profile.currentTitle != null &&
                      profile.currentTitle!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.currentTitle!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.heading,
                      ),
                    ),
                  ],
                  if (profile.organization != null &&
                      profile.organization!.isNotEmpty)
                    Text(
                      profile.organization!,
                      style: GoogleFonts.inter(color: AppColors.bodyText),
                    ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      location,
                      style: GoogleFonts.inter(color: AppColors.mutedText),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (profile.degree != null || profile.specialization != null) ...[
          const SizedBox(height: 32),
          Text(
            'Education',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              profile.degree,
              profile.specialization,
            ].where((e) => e != null && e.isNotEmpty).join(' · '),
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.7,
              color: AppColors.bodyText,
            ),
          ),
        ],
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            'About',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bio!,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.7,
              color: AppColors.bodyText,
            ),
          ),
        ],
        if (profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty) ...[
          const SizedBox(height: 24),
          SelectableText(
            profile.linkedinUrl!,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorWidget: (_, error, stackTrace) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: 120,
      height: 120,
      color: AppColors.muted,
      child: const Icon(Icons.person, size: 48, color: AppColors.primary),
    );
  }
}
