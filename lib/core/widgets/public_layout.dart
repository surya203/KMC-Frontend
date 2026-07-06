import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import 'safe_asset_image.dart';

class PublicAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PublicAppBar({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  static const _navItems = [
    ('Home', '/'),
    ('About', '/about'),
    ('Events', '/events'),
    ('Gallery', '/gallery'),
    ('MY KMC', '/auth'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final currentPath = GoRouterState.of(context).uri.path;

    if (width < 900) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        toolbarHeight: 72,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: onMenuPressed,
        ),
        title: InkWell(
          onTap: () => context.go('/'),
          child: _BrandLockup(compact: true),
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      toolbarHeight: 84,
      automaticallyImplyLeading: false,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => context.go('/'),
                    child: const _BrandLockup(compact: false),
                  ),
                ),
              ),
              _CenterNavLinks(currentPath: currentPath),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/auth'),
                        child: Text(
                          'Sign in',
                          style: GoogleFonts.inter(color: AppColors.bodyText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/membership'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Join Network',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(85);
}

class _CenterNavLinks extends StatelessWidget {
  const _CenterNavLinks({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in PublicAppBar._navItems)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: TextButton(
              onPressed: () => context.go(item.$2),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.bodyText,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: currentPath == item.$2
                      ? const BorderSide(color: AppColors.heading, width: 1.2)
                      : BorderSide.none,
                ),
              ),
              child: Text(
                item.$1,
                style: GoogleFonts.inter(
                  fontWeight: currentPath == item.$2
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeAssetImage(
          assetPath: AppAssets.logo,
          height: compact ? 42 : 48,
          width: compact ? 42 : 48,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KMC',
              style: GoogleFonts.inter(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
                height: 1,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'ALUMNI CONNECT',
              style: GoogleFonts.inter(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                height: 1.1,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PublicDrawer extends StatelessWidget {
  const PublicDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _BrandLockup(compact: false),
            ),
            const Divider(),
            _DrawerTile(label: 'Home', path: '/', currentPath: currentPath),
            _DrawerTile(label: 'About', path: '/about', currentPath: currentPath),
            _DrawerTile(label: 'Events', path: '/events', currentPath: currentPath),
            _DrawerTile(label: 'Gallery', path: '/gallery', currentPath: currentPath),
            _DrawerTile(label: 'MY KMC', path: '/auth', currentPath: currentPath),
            const Divider(),
            _DrawerTile(label: 'Sign in', path: '/auth', currentPath: currentPath),
            _DrawerTile(
              label: 'Join Network',
              path: '/membership',
              currentPath: currentPath,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.label,
    required this.path,
    required this.currentPath,
  });

  final String label;
  final String path;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final selected = currentPath == path;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.bodyText,
        ),
      ),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        context.go(path);
      },
    );
  }
}

class PublicLayout extends StatefulWidget {
  const PublicLayout({
    super.key,
    required this.child,
    this.showFooter = true,
  });

  final Widget child;
  final bool showFooter;

  @override
  State<PublicLayout> createState() => _PublicLayoutState();
}

class _PublicLayoutState extends State<PublicLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: PublicAppBar(
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const PublicDrawer(),
      body: widget.child,
    );
  }
}
