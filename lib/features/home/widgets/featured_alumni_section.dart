import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/profiles_service.dart';
import 'section_header.dart';

class FeaturedAlumniSection extends StatefulWidget {
  const FeaturedAlumniSection({super.key});

  @override
  State<FeaturedAlumniSection> createState() => _FeaturedAlumniSectionState();
}

class _FeaturedAlumniSectionState extends State<FeaturedAlumniSection> {
  final _service = ProfilesService();
  List<ProfileSummary> _profiles = [];

  static const _fallback = [
    (
      '“KMC shaped my career. The bonds I formed here remain my strongest support system.”',
      'Dr. Ramesh Reddy',
      'Chief Cardiologist, AIIMS Delhi · Batch 1992',
      'https://i.pravatar.cc/200?img=12',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await _service.fetchFeatured();
    if (!mounted) return;
    setState(() => _profiles = profiles.take(3).toList());
  }

  @override
  Widget build(BuildContext context) {
    final useApi = _profiles.isNotEmpty;

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const SectionHeader(
                eyebrow: 'Featured Alumni',
                regularTitle: 'From Warangal ',
                italicTitle: 'to',
                titleSuffix: ' the world.',
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  if (useApi) {
                    final cards = _profiles
                        .map((p) => _AlumniCard.fromProfile(p))
                        .toList();
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 20),
                            Expanded(child: cards[i]),
                          ],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (final card in cards) ...[
                          card,
                          const SizedBox(height: 20),
                        ],
                      ],
                    );
                  }

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _fallback.length; i++) ...[
                          if (i > 0) const SizedBox(width: 20),
                          Expanded(child: _AlumniCard(data: _fallback[i])),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (final person in _fallback) ...[
                        _AlumniCard(data: person),
                        const SizedBox(height: 20),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlumniCard extends StatelessWidget {
  const _AlumniCard({this.data, this.profile});

  final (String, String, String, String)? data;
  final ProfileSummary? profile;

  factory _AlumniCard.fromProfile(ProfileSummary profile) {
    return _AlumniCard(profile: profile);
  }

  @override
  Widget build(BuildContext context) {
    final quote = data?.$1 ??
        '“Proud KMC graduate making a difference in medicine and community.”';
    final name = profile?.fullName ?? data?.$2 ?? '';
    final subtitle = profile != null
        ? '${profile!.currentTitle ?? profile!.organization ?? 'Alumni'} · Batch ${profile!.batchYear}'
        : data?.$3 ?? '';
    final photo = profile?.photoUrl ?? data?.$4;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote,
            style: GoogleFonts.fraunces(
              fontSize: 18,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: photo != null
                    ? CachedNetworkImage(
                        imageUrl: photo,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.muted,
      child: const Icon(Icons.person, color: AppColors.primary),
    );
  }
}
