import 'package:flutter/material.dart';

enum AppSearchResultType {
  page,
  alumni,
  event,
  galleryAlbum,
  announcement,
}

class AppSearchResult {
  const AppSearchResult({
    required this.type,
    required this.title,
    required this.route,
    required this.icon,
    this.subtitle,
    this.score = 0,
  });

  final AppSearchResultType type;
  final String title;
  final String? subtitle;
  final String route;
  final IconData icon;
  final int score;

  String get typeLabel {
    switch (type) {
      case AppSearchResultType.page:
        return 'Page';
      case AppSearchResultType.alumni:
        return 'Alumni';
      case AppSearchResultType.event:
        return 'Event';
      case AppSearchResultType.galleryAlbum:
        return 'Gallery';
      case AppSearchResultType.announcement:
        return 'Announcement';
    }
  }
}
