import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/search/app_search_result.dart';
import '../../../core/search/app_search_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/drugs_header_card.dart';
import '../../../core/widgets/drugs_sidebar_banner.dart';
import '../../../core/utils/membership_number_format.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/safe_asset_image.dart';
import 'dashboard_nav_items.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.currentPath,
    required this.title,
    required this.child,
    required this.onSignOut,
    required this.searchController,
    required this.searchService,
    this.profileName,
    this.profilePhotoUrl,
    this.profilePhotoBytes,
  });

  final String currentPath;
  final String title;
  final Widget child;
  final VoidCallback onSignOut;
  final TextEditingController searchController;
  final AppSearchService searchService;
  final String? profileName;
  final String? profilePhotoUrl;
  final Uint8List? profilePhotoBytes;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F4),
      drawer: isDesktop
          ? null
          : Drawer(
              child: DashboardSidebar(
                currentPath: currentPath,
                onSignOut: onSignOut,
              ),
            ),
      body: Builder(
        builder: (scaffoldContext) => Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 228,
                child: DashboardSidebar(
                  currentPath: currentPath,
                  onSignOut: onSignOut,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  DashboardTopBar(
                    title: title,
                    searchController: searchController,
                    searchService: searchService,
                    profileName: profileName,
                    profilePhotoUrl: profilePhotoUrl,
                    profilePhotoBytes: profilePhotoBytes,
                    onMenuTap: isDesktop
                        ? null
                        : () => Scaffold.of(scaffoldContext).openDrawer(),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: const Color(0xFFF7F7F4),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.currentPath,
    required this.onSignOut,
  });

  final String currentPath;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(
                children: [
                  const SafeAssetImage(
                    assetPath: AppAssets.logo,
                    width: 38,
                    height: 38,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KMC',
                        style: GoogleFonts.fraunces(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'ALUMNI CONNECT',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0x33FFFFFF), height: 1),
            const SizedBox(height: 12),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    for (final item in dashboardNavItems)
                      _SidebarNavTile(
                        item: item,
                        active: dashboardNavItemIsActive(item.path, currentPath),
                        currentPath: currentPath,
                      ),
                  ],
                ),
              ),
            ),
            const DrugsSidebarBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x66FFFFFF)),
                  minimumSize: const Size.fromHeight(42),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.active,
    required this.currentPath,
  });

  final DashboardNavItem item;
  final bool active;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.secondary : Colors.transparent;
    final fg = active ? AppColors.primary : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.white.withValues(alpha: 0.08),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          onTap: () {
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            if (item.path == currentPath) return;
            context.go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardTopBar extends StatefulWidget {
  const DashboardTopBar({
    super.key,
    required this.title,
    required this.searchController,
    required this.searchService,
    required this.onMenuTap,
    this.profileName,
    this.profilePhotoUrl,
    this.profilePhotoBytes,
  });

  final String title;
  final TextEditingController searchController;
  final AppSearchService searchService;
  final VoidCallback? onMenuTap;
  final String? profileName;
  final String? profilePhotoUrl;
  final Uint8List? profilePhotoBytes;

  @override
  State<DashboardTopBar> createState() => _DashboardTopBarState();
}

class _DashboardTopBarState extends State<DashboardTopBar> {
  bool _searchExpanded = false;
  bool _searching = false;
  bool _hasSearched = false;
  List<AppSearchResult> _results = [];
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title && _searchExpanded) {
      _collapseSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.searchController.removeListener(_onQueryChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = widget.searchController.text.trim();

    if (!_searchExpanded && query.isNotEmpty) {
      setState(() => _searchExpanded = true);
    }

    _debounce?.cancel();

    if (query.length < 2) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _searching = false;
      });
      return;
    }

    // Drop stale rows immediately so taps cannot use the previous query.
    setState(() {
      _results = [];
      _searching = true;
      _hasSearched = false;
    });

    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  void _expandSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _collapseSearch({bool clearQuery = false}) {
    _debounce?.cancel();
    if (clearQuery) widget.searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchExpanded = false;
      _results = [];
      _hasSearched = false;
      _searching = false;
    });
  }

  Future<void> _runSearch() async {
    final query = widget.searchController.text.trim();
    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _hasSearched = false;
        _searching = false;
      });
      return;
    }

    final generation = ++_searchGeneration;
    setState(() {
      _searching = true;
      _hasSearched = true;
    });

    final results = await widget.searchService.search(query);
    if (!mounted || generation != _searchGeneration) return;

    setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _submitSearch() async {
    await _runSearch();
    if (!mounted) return;

    final query = widget.searchController.text.trim();
    if (query.length < 2) return;

    if (_results.isEmpty) {
      setState(() => _hasSearched = true);
      return;
    }

    final target = _pickBestResult(query);
    if (target != null) {
      _openResult(target);
    }
  }

  AppSearchResult? _pickBestResult(String query) {
    if (_results.isEmpty) return null;

    final q = query.toLowerCase();

    for (final result in _results) {
      if (result.type == AppSearchResultType.page &&
          result.title.toLowerCase() == q) {
        return result;
      }
    }

    for (final result in _results) {
      if (result.type == AppSearchResultType.page &&
          result.title.toLowerCase().startsWith(q)) {
        return result;
      }
    }

    final pageResults = _results
        .where((result) => result.type == AppSearchResultType.page)
        .toList();
    if (pageResults.length == 1 && pageResults.first.score >= 60) {
      return pageResults.first;
    }

    if (_results.length == 1) return _results.first;

    return null;
  }

  void _openResult(AppSearchResult result) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    context.go(result.route);
    _collapseSearch(clearQuery: true);
  }

  InputDecoration _searchDecoration() {
    return InputDecoration(
      hintText: 'Search alumni, events, pages...',
      prefixIcon: const Icon(Icons.search, size: 20),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );
  }

  Widget _buildResultsPanel() {
    final query = widget.searchController.text.trim();
    if (query.length < 2) return const SizedBox.shrink();

    if (_searching) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No results for "$query"',
          style: GoogleFonts.inter(color: AppColors.bodyText),
        ),
      );
    }

    if (_results.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _results.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 56),
        itemBuilder: (context, index) {
          final result = _results[index];
          return Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.background,
                child: Icon(result.icon, size: 18, color: AppColors.primary),
              ),
              title: Text(
                result.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                result.subtitle ?? result.typeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.bodyText,
                  fontSize: 12,
                ),
              ),
              onTap: () => _openResult(result),
            ),
          );
        },
      ),
    );
  }

  bool get _showSearchField {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return isCompact ? _searchExpanded : true;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 700;
    final initial = (widget.profileName?.isNotEmpty == true)
        ? widget.profileName!.trim()[0].toUpperCase()
        : 'A';

    return Material(
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 8 : 20,
          isCompact ? 8 : 12,
          isCompact ? 12 : 20,
          isCompact ? 8 : 12,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (widget.onMenuTap != null)
                  IconButton(
                    onPressed: widget.onMenuTap,
                    icon: const Icon(Icons.menu),
                    visualDensity: VisualDensity.compact,
                  ),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      fontWeight: FontWeight.w600,
                      color: AppColors.heading,
                      fontSize: isCompact ? 22 : 30,
                    ),
                  ),
                ),
                if (isCompact)
                  IconButton(
                    onPressed: _searchExpanded ? _collapseSearch : _expandSearch,
                    icon: Icon(
                      _searchExpanded ? Icons.close : Icons.search,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  const SizedBox(width: 12),
                const DrugsHeaderCard(),
                SizedBox(width: isCompact ? 8 : 10),
                IconButton(
                  onPressed: () => context.go('/announcements'),
                  icon: const Icon(Icons.notifications_none_rounded),
                  visualDensity: VisualDensity.compact,
                ),
                _ProfileAvatarMenu(
                  name: widget.profileName ?? initial,
                  photoBytes: widget.profilePhotoBytes,
                  size: isCompact ? 28 : 32,
                ),
              ],
            ),
            if (!isCompact && _showSearchField) ...[
              const SizedBox(height: 10),
              TextField(
                controller: widget.searchController,
                focusNode: _searchFocusNode,
                onSubmitted: (_) => _submitSearch(),
                textInputAction: TextInputAction.search,
                decoration: _searchDecoration(),
              ),
              _buildResultsPanel(),
            ],
            if (isCompact && _searchExpanded) ...[
              const SizedBox(height: 8),
              TextField(
                controller: widget.searchController,
                focusNode: _searchFocusNode,
                onSubmitted: (_) => _submitSearch(),
                textInputAction: TextInputAction.search,
                decoration: _searchDecoration(),
              ),
              _buildResultsPanel(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarMenu extends StatelessWidget {
  const _ProfileAvatarMenu({
    required this.name,
    required this.size,
    this.photoBytes,
  });

  final String name;
  final double size;
  final Uint8List? photoBytes;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final sizeBox = box.size;
    final screenSize = overlay.size;

    const menuWidth = 280.0;
    final right = screenSize.width - (topLeft.dx + sizeBox.width);
    final top = topLeft.dy + sizeBox.height + 8;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      builder: (dialogContext) {
        return Stack(
          children: [
            Positioned(
              top: top,
              right: right.clamp(12.0, screenSize.width - menuWidth - 12),
              child: Material(
                color: Colors.transparent,
                child: _ProfileDetailsCard(
                  name: name,
                  photoBytes: photoBytes,
                  onViewProfile: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/my-profile');
                  },
                  onSettings: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/settings');
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profile',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _open(context),
          child: ProfileAvatar(
            localBytes: photoBytes,
            name: name,
            size: size,
            cacheKey: photoBytes?.length,
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.name,
    required this.onViewProfile,
    required this.onSettings,
    this.photoBytes,
  });

  final String name;
  final Uint8List? photoBytes;
  final VoidCallback onViewProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.currentUser;
    final displayName =
        (name.trim().isNotEmpty ? name.trim() : null) ??
        user?.fullName?.trim() ??
        'Member';
    final batch = user?.batchYear;
    final email = user?.email;
    final membershipId = MembershipNumberFormat.displayOrFallback(
      storedMembershipNumber: user?.membershipNumber,
      batchYear: batch,
      fullName: displayName,
      fallback: user?.membershipNumber?.trim().isNotEmpty == true
          ? user!.membershipNumber!.trim()
          : '—',
    );

    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProfileAvatar(
                localBytes: photoBytes,
                name: displayName,
                size: 48,
                cacheKey: photoBytes?.length,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fraunces(
                        fontWeight: FontWeight.w600,
                        color: AppColors.heading,
                        fontSize: 18,
                        height: 1.15,
                      ),
                    ),
                    if (batch != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Batch of $batch',
                        style: GoogleFonts.inter(
                          color: AppColors.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          _ProfileDetailRow(
            label: 'Membership ID',
            value: membershipId,
          ),
          if (email != null && email.isNotEmpty)
            _ProfileDetailRow(
              label: 'Email',
              value: email,
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onViewProfile,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: Text(
              'View Profile',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onSettings,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.bodyText,
              padding: const EdgeInsets.symmetric(vertical: 6),
            ),
            child: Text(
              'Settings',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.heading,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
