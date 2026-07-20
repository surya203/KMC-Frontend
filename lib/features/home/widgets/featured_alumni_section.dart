import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/resilient_profile_image.dart';
import 'section_header.dart';

class FeaturedAlumniSection extends StatefulWidget {
  const FeaturedAlumniSection({super.key});

  @override
  State<FeaturedAlumniSection> createState() => _FeaturedAlumniSectionState();
}

class _FeaturedAlumniSectionState extends State<FeaturedAlumniSection> {
  final _api = ProfilesApiService();
  final _pageController = PageController(viewportFraction: 0.85);
  Timer? _autoScrollTimer;

  List<_AlumniCardData> _profiles = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  bool _autoScrollPaused = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _api.fetchFeatured();
      if (!mounted) return;
      final mapped = profiles.map(_mapProfile).toList();
      setState(() {
        _profiles = mapped;
        _loading = false;
        _error = mapped.isEmpty ? 'No featured alumni yet.' : null;
      });
      if (mapped.length > 1) _startAutoScroll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load featured alumni.';
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_autoScrollPaused || _profiles.length < 2) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _autoScrollPaused || _profiles.length < 2) return;
      final next = (_currentPage + 1) % _profiles.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoScroll() {
    if (_autoScrollPaused) return;
    _autoScrollPaused = true;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _resumeAutoScroll() {
    if (!_autoScrollPaused) return;
    _autoScrollPaused = false;
    _startAutoScroll();
  }

  _AlumniCardData _mapProfile(FeaturedProfile profile) {
    final parts = <String>[];
    if (profile.currentTitle != null && profile.currentTitle!.isNotEmpty) {
      parts.add(profile.currentTitle!);
    }
    if (profile.organization != null && profile.organization!.isNotEmpty) {
      parts.add(profile.organization!);
    }

    final quote = profile.bio != null && profile.bio!.isNotEmpty
        ? profile.bio!
        : 'Proud KMC graduate.';

    return _AlumniCardData(
      id: profile.id,
      name: profile.fullName,
      quote: quote,
      roleLine: parts.join('\n'),
      photoUrl: profile.photoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              SectionHeader(
                eyebrow: 'Featured Alumni',
                regularTitle: 'From Warangal ',
                italicTitle: 'to the world.',
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _profiles.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _AlumniCard(data: _profiles[index]),
                    );
                  },
                ),
              ),
              if (_profiles.length > 1) ...[
                const SizedBox(height: 20),
                MouseRegion(
                  onEnter: (_) => _pauseAutoScroll(),
                  onExit: (_) => _resumeAutoScroll(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _profiles.length; i++)
                          GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 8,
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _currentPage
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () {
                  if (AuthSession.instance.isAuthenticated) {
                    context.go('/member/alumni-roll');
                  } else {
                    context.go('/auth');
                  }
                },
                child: Text(
                  AuthSession.instance.isAuthenticated
                      ? 'Browse Alumni'
                      : 'Sign in to browse Alumni',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlumniCardData {
  const _AlumniCardData({
    this.id,
    required this.name,
    required this.quote,
    required this.roleLine,
    this.photoUrl,
  });

  final String? id;
  final String name;
  final String quote;
  final String roleLine;
  final String? photoUrl;
}

class _AlumniCard extends StatelessWidget {
  const _AlumniCard({required this.data});

  final _AlumniCardData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.id == null
            ? null
            : () {
                if (AuthSession.instance.isAuthenticated) {
                  context.go('/member/profiles/${data.id}');
                } else {
                  context.go('/auth');
                }
              },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“${data.quote}”',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: AppColors.heading,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondary, width: 2),
                    ),
                    child: ClipOval(
                      child: data.photoUrl != null
                          ? ResilientProfileImage(
                              photoUrl: data.photoUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              fallback: _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.heading,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.roleLine,
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
        ),
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
