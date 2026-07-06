import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/profiles_service.dart';
import '../../../core/theme/heading_styles.dart';
import '../../../core/widgets/page_hero.dart';
import '../../../core/widgets/public_layout.dart';
import '../../home/widgets/footer_section.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _service = ProfilesService();
  final _searchController = TextEditingController();
  final _batchController = TextEditingController();

  List<ProfileSummary> _profiles = [];
  bool _loading = true;
  bool _hasMore = false;
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) _page = 1;
    setState(() => _loading = true);
    final batch = int.tryParse(_batchController.text.trim());
    final result = await _service.searchProfiles(
      search: _searchController.text.trim(),
      batchYear: batch,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      if (reset) {
        _profiles = result.profiles;
      } else {
        _profiles = [..._profiles, ...result.profiles];
      }
      _hasMore = result.hasMore;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            PageHero(
              eyebrow: 'Directory',
              title: HeadingStyles.pageHeroTitleWidget(
                context,
                regular: 'Find alumni ',
                italic: 'worldwide.',
              ),
              subtitle: 'Search the verified MY KMC alumni directory.',
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              key: const ValueKey('directory-search'),
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search by name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              key: const ValueKey('directory-batch'),
                              controller: _batchController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Batch year',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            key: const ValueKey('directory-search-button'),
                            onPressed: () => _load(),
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_loading)
                        const CircularProgressIndicator()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _profiles.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final profile = _profiles[index];
                            return ListTile(
                              key: ValueKey('directory-profile-${profile.id}'),
                              leading: CircleAvatar(
                                backgroundImage: profile.photoUrl != null
                                    ? CachedNetworkImageProvider(
                                        profile.photoUrl!,
                                      )
                                    : null,
                                child: profile.photoUrl == null
                                    ? Text(profile.fullName[0])
                                    : null,
                              ),
                              title: Text(profile.fullName),
                              subtitle: Text(
                                'Batch ${profile.batchYear}'
                                '${profile.organization != null ? ' · ${profile.organization}' : ''}',
                              ),
                              onTap: () =>
                                  context.go('/profiles/${profile.id}'),
                            );
                          },
                        ),
                      if (_hasMore)
                        TextButton(
                          onPressed: () {
                            _page += 1;
                            _load(reset: false);
                          },
                          child: const Text('Load more'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _service = ProfilesService();
  ProfileSummary? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _service.fetchById(widget.profileId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return PublicLayout(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(child: Text('Profile not found'))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: profile.photoUrl != null
                                ? CachedNetworkImageProvider(profile.photoUrl!)
                                : null,
                            child: profile.photoUrl == null
                                ? Text(
                                    profile.fullName[0],
                                    style: const TextStyle(fontSize: 32),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.fullName,
                            style: GoogleFonts.fraunces(fontSize: 28),
                          ),
                          Text('Batch ${profile.batchYear}'),
                          if (profile.currentTitle != null)
                            Text(profile.currentTitle!),
                          if (profile.organization != null)
                            Text(profile.organization!),
                          if (profile.bio != null) ...[
                            const SizedBox(height: 16),
                            Text(profile.bio!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
