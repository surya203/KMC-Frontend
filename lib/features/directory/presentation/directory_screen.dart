import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/profiles_api_service.dart';
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
  final _api = ProfilesApiService();
  final _searchController = TextEditingController();
  final _batchController = TextEditingController();

  List<DirectoryProfile> _profiles = [];
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = false;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadProfiles(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final batchText = _batchController.text.trim();
    final batchYear = batchText.isEmpty ? null : int.tryParse(batchText);

    try {
      final result = await _api.fetchDirectory(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        batchYear: batchYear,
        page: reset ? 1 : _page + 1,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _profiles = result.profiles;
          _page = result.page;
        } else {
          _profiles = [..._profiles, ...result.profiles];
          _page = result.page;
        }
        _hasMore = result.hasMore;
        _total = result.total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
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
                regular: 'Find your ',
                italic: 'batchmates.',
              ),
              subtitle:
                  'Search approved alumni profiles by name or graduation batch.',
            ),
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 72),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          SizedBox(
                            width: 280,
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search by name',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _loadProfiles(reset: true),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _batchController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Batch year',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _loadProfiles(reset: true),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _loadProfiles(reset: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                            ),
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (!_loading && _error == null)
                        Text(
                          '$_total alumni found',
                          style: GoogleFonts.inter(color: AppColors.bodyText),
                        ),
                      const SizedBox(height: 20),
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        Text(
                          _error!,
                          style: GoogleFonts.inter(color: AppColors.bodyText),
                        )
                      else if (_profiles.isEmpty)
                        Text(
                          'No profiles match your search.',
                          style: GoogleFonts.inter(color: AppColors.bodyText),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth > 900 ? 3 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: columns == 1 ? 3.2 : 2.8,
                              ),
                              itemCount: _profiles.length,
                              itemBuilder: (context, index) {
                                return _DirectoryCard(profile: _profiles[index]);
                              },
                            );
                          },
                        ),
                      if (_hasMore) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: _loadingMore
                              ? const CircularProgressIndicator()
                              : OutlinedButton(
                                  onPressed: () => _loadProfiles(reset: false),
                                  child: const Text('Load more'),
                                ),
                        ),
                      ],
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

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.profile});

  final DirectoryProfile profile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/profiles/${profile.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _Avatar(photoUrl: profile.photoUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.fullName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ClipOval(
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, error, stackTrace) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.muted,
      child: const Icon(Icons.person, color: AppColors.primary),
    );
  }
}
