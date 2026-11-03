class PublicNavItem {
  const PublicNavItem(this.label, this.path);

  final String label;
  final String path;
}

/// Public destinations shown on https://kmcalumni.net/ (home pills + menu).
const publicNavItems = <PublicNavItem>[
  PublicNavItem('Home', '/'),
  PublicNavItem('About', '/about'),
  PublicNavItem('MY KMC', '/membership'),
  PublicNavItem('Events', '/events'),
  PublicNavItem('Gallery', '/gallery'),
];
