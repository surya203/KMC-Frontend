import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import 'drugs_header_card.dart';
import 'hover_link.dart';
import 'safe_asset_image.dart';

/// Navigates back on public pages — pops history when possible, otherwise
/// returns to a sensible parent route (e.g. event detail → events list).
void navigatePublicBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  final path = GoRouterState.of(context).uri.path;
  if (path.startsWith('/events/') && path.length > '/events/'.length) {
    context.go('/events');
    return;
  }
  if (path.startsWith('/gallery/') && path.length > '/gallery/'.length) {
    context.go('/gallery');
    return;
  }
  if (path.startsWith('/profiles/') || path.startsWith('/member/profiles/')) {
    context.go('/member/alumni-roll');
    return;
  }
  context.go('/');
}

class PublicBackIcon extends StatelessWidget {
  const PublicBackIcon({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => navigatePublicBack(context),
      icon: Icon(
        Icons.arrow_back,
        color: dark ? Colors.white : AppColors.primary,
        size: 22,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      visualDensity: VisualDensity.compact,
      tooltip: 'Back',
    );
  }
}

class PublicAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PublicAppBar({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  static const _headerPadding = 16.0;
  static const _menuToLogoGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final currentPath = GoRouterState.of(context).uri.path;
    final isDesktop = width >= 1100;

    if (!isDesktop) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _headerPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MenuButton(onPressed: onMenuPressed),
                const SizedBox(width: _menuToLogoGap),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.go('/'),
                      behavior: HitTestBehavior.opaque,
                      child: const _BrandLockup(compact: true),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const DrugsHeaderCard(),
                const SizedBox(width: 6),
                const _HeaderSignInButton(),
              ],
            ),
          ),
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      toolbarHeight: 92,
      automaticallyImplyLeading: false,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _headerPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MenuButton(onPressed: onMenuPressed),
              const SizedBox(width: _menuToLogoGap),
              Flexible(
                fit: FlexFit.loose,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    behavior: HitTestBehavior.opaque,
                    child: const _BrandLockup(compact: false),
                  ),
                ),
              ),
              const Spacer(),
              const DrugsHeaderCard(),
              const SizedBox(width: 12),
              HoverLink(
                label: 'Sign in',
                fontSize: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                isActive: isNavRouteActive(currentPath, '/auth'),
                onTap: () => context.go('/auth'),
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(93);
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu, color: AppColors.primary, size: 28),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      visualDensity: VisualDensity.standard,
      tooltip: 'Open menu',
      onPressed: onPressed,
    );
  }
}

/// Compact header Sign in control — same height as [DrugsHeaderCard].
class _HeaderSignInButton extends StatelessWidget {
  const _HeaderSignInButton();

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/auth'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: Text(
            'Sign in',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
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

  static const _logoToKmcGap = 8.0;
  static const _kmcToSubtitleGap = 5.0;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 32.0 : 48.0;
    // KMC slightly larger than the logo for stronger brand focus.
    final kmcFontSize = compact ? 36.0 : 54.0;
    final kmcWidth = logoSize * 1.85;
    // Subtitle smaller so it reads as secondary text.
    final subtitleSize = compact ? 9.5 : 11.0;

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SafeAssetImage(
                assetPath: AppAssets.logo,
                height: logoSize,
                width: logoSize,
              ),
              const SizedBox(width: _logoToKmcGap),
              SizedBox(
                height: logoSize,
                width: kmcWidth,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'KMC',
                    style: GoogleFonts.fraunces(
                      fontSize: kmcFontSize,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _kmcToSubtitleGap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 5,
                  vertical: compact ? 1.5 : 2,
                ),
                color: AppColors.secondary,
                child: Text(
                  'ALUMNI',
                  style: GoogleFonts.inter(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    letterSpacing: compact ? 1.0 : 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                ' CONNECT',
                style: GoogleFonts.inter(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: compact ? 1.0 : 1.2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
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
            _DrawerTile(label: 'MY KMC', path: '/membership', currentPath: currentPath),
            _DrawerTile(label: 'Events', path: '/events', currentPath: currentPath),
            _DrawerTile(label: 'Gallery', path: '/gallery', currentPath: currentPath),
            const Divider(),
            _DrawerTile(label: 'Contact Us', path: '/contact', currentPath: currentPath),
            _DrawerTile(label: 'Pricing', path: '/pricing', currentPath: currentPath),
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
    final selected = isNavRouteActive(currentPath, path);

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
