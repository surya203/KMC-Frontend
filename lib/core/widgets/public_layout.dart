import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_session.dart';
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
  ];

  String get _myKmcPath => authSession.memberDestination;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final currentPath = GoRouterState.of(context).uri.path;

    return ListenableBuilder(
      listenable: authSession,
      builder: (context, _) {
        if (width < 1100) {
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
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: _CenterNavLinks(
                        currentPath: currentPath,
                        myKmcPath: _myKmcPath,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!authSession.isAuthenticated)
                            TextButton(
                              key: const ValueKey('nav-sign-in'),
                              onPressed: () => context.go('/auth'),
                              child: Text(
                                'Sign in',
                                style: GoogleFonts.inter(
                                  color: AppColors.bodyText,
                                ),
                              ),
                            )
                          else
                            TextButton(
                              key: const ValueKey('nav-dashboard'),
                              onPressed: () => context.go('/dashboard'),
                              child: Text(
                                'Dashboard',
                                style: GoogleFonts.inter(
                                  color: AppColors.bodyText,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            key: const ValueKey('nav-join-network'),
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
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
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
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(85);
}

class _CenterNavLinks extends StatelessWidget {
  const _CenterNavLinks({
    required this.currentPath,
    required this.myKmcPath,
  });

  final String currentPath;
  final String myKmcPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in PublicAppBar._navItems)
          _NavLinkItem(
            key: ValueKey('nav-${item.$1.toLowerCase().replaceAll(' ', '-')}'),
            label: item.$1,
            path: item.$2,
            isActive: currentPath == item.$2,
          ),
        _NavLinkItem(
          key: const ValueKey('nav-my-kmc'),
          label: 'MY KMC',
          path: myKmcPath,
          isActive: currentPath == myKmcPath ||
              currentPath.startsWith('/dashboard'),
        ),
      ],
    );
  }
}

class _NavLinkItem extends StatefulWidget {
  const _NavLinkItem({
    super.key,
    required this.label,
    required this.path,
    required this.isActive,
  });

  final String label;
  final String path;
  final bool isActive;

  @override
  State<_NavLinkItem> createState() => _NavLinkItemState();
}

class _NavLinkItemState extends State<_NavLinkItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isActive || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.path),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: highlighted ? AppColors.heading : AppColors.bodyText,
            ),
          ),
        ),
      ),
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
    final myKmcPath = authSession.memberDestination;

    return ListenableBuilder(
      listenable: authSession,
      builder: (context, _) {
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
                _DrawerTile(
                  key: const ValueKey('drawer-home'),
                  label: 'Home',
                  path: '/',
                  currentPath: currentPath,
                ),
                _DrawerTile(
                  key: const ValueKey('drawer-about'),
                  label: 'About',
                  path: '/about',
                  currentPath: currentPath,
                ),
                _DrawerTile(
                  key: const ValueKey('drawer-events'),
                  label: 'Events',
                  path: '/events',
                  currentPath: currentPath,
                ),
                _DrawerTile(
                  key: const ValueKey('drawer-my-kmc'),
                  label: 'MY KMC',
                  path: myKmcPath,
                  currentPath: currentPath,
                ),
                const Divider(),
                if (!authSession.isAuthenticated)
                  _DrawerTile(
                    key: const ValueKey('drawer-sign-in'),
                    label: 'Sign in',
                    path: '/auth',
                    currentPath: currentPath,
                  )
                else
                  _DrawerTile(
                    key: const ValueKey('drawer-dashboard'),
                    label: 'Dashboard',
                    path: '/dashboard',
                    currentPath: currentPath,
                  ),
                _DrawerTile(
                  key: const ValueKey('drawer-join-network'),
                  label: 'Join Network',
                  path: '/membership',
                  currentPath: currentPath,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    super.key,
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
  const PublicLayout({super.key, required this.child, this.showFooter = true});

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
