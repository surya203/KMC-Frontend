import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/profiles_api_service.dart';
import '../../../core/utils/membership_number_format.dart';
import '../../../core/utils/resilient_profile_image.dart';
import '../../dashboard/widgets/dashboard_layout.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key, this.embeddedInDashboard = true});

  /// Always rendered inside the member dashboard shell.
  final bool embeddedInDashboard;

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _api = ProfilesApiService();
  final _nameController = TextEditingController();
  final _membershipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _batchController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();

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
    AuthSession.instance.addListener(_onSessionChanged);
    _loadProfiles(reset: true);
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onSessionChanged);
    _nameController.dispose();
    _membershipController.dispose();
    _phoneController.dispose();
    _batchController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) _loadProfiles(reset: true);
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
    final phone = _phoneController.text.trim();

    try {
      final result = await _api.fetchDirectory(
        search: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        membershipNumber: _membershipController.text.trim().isEmpty
            ? null
            : _membershipController.text.trim(),
        phone: phone.isEmpty ? null : phone,
        batchYear: batchYear,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
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
        _error = _formatError(e);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _clearFilters() {
    _nameController.clear();
    _membershipController.clear();
    _phoneController.clear();
    _batchController.clear();
    _categoryController.clear();
    _locationController.clear();
    _loadProfiles(reset: true);
  }

  String _formatError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  bool get _hasActiveFilters =>
      _nameController.text.trim().isNotEmpty ||
      _membershipController.text.trim().isNotEmpty ||
      _phoneController.text.trim().isNotEmpty ||
      _batchController.text.trim().isNotEmpty ||
      _categoryController.text.trim().isNotEmpty ||
      _locationController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final compact = DashboardLayout.isCompact(context);
    final pad = DashboardLayout.screenPadding(context);

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find and open verified member profiles.',
                style: GoogleFonts.inter(
                  fontSize: compact ? 14 : 15,
                  color: AppColors.bodyText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _FiltersCard(
                compact: compact,
                nameController: _nameController,
                membershipController: _membershipController,
                batchController: _batchController,
                categoryController: _categoryController,
                locationController: _locationController,
                phoneController: _phoneController,
                onSearch: () => _loadProfiles(reset: true),
                onClear: _clearFilters,
              ),
              const SizedBox(height: 22),
              _ResultsHeader(
                loading: _loading,
                error: _error,
                total: _total,
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _EmptyPanel(
                  title: 'Could not load alumni',
                  body: _error!,
                  actionLabel: 'Try again',
                  onAction: () => _loadProfiles(reset: true),
                )
              else if (_profiles.isEmpty)
                _EmptyPanel(
                  title: 'No alumni found',
                  body:
                      'Try fewer filters, a different batch year, or clear the search.',
                  actionLabel: _hasActiveFilters ? 'Clear filters' : null,
                  onAction: _hasActiveFilters ? _clearFilters : null,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 820 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        // Room for name + ID + one chip row + location on mobile.
                        mainAxisExtent: compact ? 138 : 128,
                      ),
                      itemCount: _profiles.length,
                      itemBuilder: (context, index) {
                        return _DirectoryCard(profile: _profiles[index]);
                      },
                    );
                  },
                ),
              if (_hasMore) ...[
                const SizedBox(height: 22),
                Center(
                  child: _loadingMore
                      ? const CircularProgressIndicator()
                      : OutlinedButton.icon(
                          onPressed: () => _loadProfiles(reset: false),
                          icon: const Icon(Icons.expand_more, size: 18),
                          label: const Text('Load more alumni'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.heading,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.compact,
    required this.nameController,
    required this.membershipController,
    required this.batchController,
    required this.categoryController,
    required this.locationController,
    required this.phoneController,
    required this.onSearch,
    required this.onClear,
  });

  final bool compact;
  final TextEditingController nameController;
  final TextEditingController membershipController;
  final TextEditingController batchController;
  final TextEditingController categoryController;
  final TextEditingController locationController;
  final TextEditingController phoneController;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DashboardLayout.cardPadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A2744),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search filters',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.heading,
                      ),
                    ),
                    Text(
                      'Filter by name, ID, batch, specialty, place, or mobile',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 640
                      ? 2
                      : 1;
              final gap = 12.0;
              final itemWidth =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;

              Widget cell(Widget child) => SizedBox(width: itemWidth, child: child);

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  cell(_FilterField(
                    controller: nameController,
                    label: 'Name',
                    hint: 'Dr. Rao',
                    icon: Icons.person_outline,
                    onSubmitted: (_) => onSearch(),
                  )),
                  cell(_FilterField(
                    controller: membershipController,
                    label: 'Membership ID',
                    hint: '2022sooraj007',
                    icon: Icons.badge_outlined,
                    onSubmitted: (_) => onSearch(),
                  )),
                  cell(_FilterField(
                    controller: batchController,
                    label: 'Batch year',
                    hint: '2022',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => onSearch(),
                  )),
                  cell(_FilterField(
                    controller: categoryController,
                    label: 'Specialty',
                    hint: 'Cardiology',
                    icon: Icons.medical_services_outlined,
                    onSubmitted: (_) => onSearch(),
                  )),
                  cell(_FilterField(
                    controller: locationController,
                    label: 'Location',
                    hint: 'Hyderabad',
                    icon: Icons.place_outlined,
                    onSubmitted: (_) => onSearch(),
                  )),
                  cell(_FilterField(
                    controller: phoneController,
                    label: 'Mobile',
                    hint: '9876543210',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => onSearch(),
                  )),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search, size: 18),
                label: Text(compact ? 'Search' : 'Search Alumni Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 18 : 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.heading,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.heading),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.mutedText),
        filled: true,
        fillColor: const Color(0xFFF9F8F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
        ),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedText),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.loading,
    required this.error,
    required this.total,
  });

  final bool loading;
  final String? error;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (loading || error != null) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          'Results',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4EE),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFB9D8C4)),
          ),
          child: Text(
            '$total alumni',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 36, color: AppColors.mutedText),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.bodyText,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.profile});

  final DirectoryProfile profile;

  String get membershipId => _membershipIdFrom(
        storedOrDisplay: profile.membershipNumber,
        batchYear: profile.batchYear,
        fullName: profile.fullName,
      );

  String get _displayName {
    final parts = profile.fullName.trim().split(RegExp(r'\s+'));
    return parts.map((part) {
      if (part.isEmpty) return part;
      if (part.length == 1) return part.toUpperCase();
      return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final specialty = profile.specialization?.trim().isNotEmpty == true
        ? profile.specialization!
        : (profile.degree?.trim().isNotEmpty == true ? profile.degree! : null);
    final place = (profile.city ?? profile.practiceLocation)?.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/member/profiles/${profile.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              _Avatar(photoUrl: profile.photoUrl, name: _displayName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.heading,
                      ),
                    ),
                    if (membershipId.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        membershipId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F6B3A),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniChip(label: 'Batch ${profile.batchYear}'),
                        if (specialty != null) _MiniChip(label: specialty),
                      ],
                    ),
                    if (place != null && place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _titleCase(place),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.mutedText,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.heading,
        ),
      ),
    );
  }
}

String _membershipIdFrom({
  required String? storedOrDisplay,
  required int batchYear,
  required String fullName,
}) {
  final raw = storedOrDisplay?.trim() ?? '';
  if (raw.isEmpty) return '';
  if (!raw.toUpperCase().startsWith('KMC-')) return raw;
  return MembershipNumberFormat.displayOrFallback(
    storedMembershipNumber: raw,
    batchYear: batchYear,
    fullName: fullName,
    fallback: raw,
  );
}

String _titleCase(String value) {
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

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    return ResilientProfileImage(
      photoUrl: photoUrl,
      width: 56,
      height: 56,
      borderRadius: BorderRadius.circular(14),
      fallback: _fallback(),
    );
  }

  Widget _fallback() {
    final initials = MembershipNumberFormat.avatarInitials(name);
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFE8EEF6),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 16,
        ),
      ),
    );
  }
}
