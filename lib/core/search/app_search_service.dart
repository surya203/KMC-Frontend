import 'package:flutter/material.dart';

import '../../features/dashboard/widgets/dashboard_nav_items.dart';
import '../network/announcements_api_service.dart';
import '../network/events_api_service.dart';
import '../network/gallery_api_service.dart';
import '../network/profiles_api_service.dart';
import 'app_search_result.dart';

const _pageKeywords = <String, List<String>>{
  '/dashboard': ['dashboard', 'home'],
  '/my-profile': ['profile', 'my profile'],
  '/my-membership': ['membership', 'member', 'plan', 'subscription'],
  '/my-events': ['events', 'event', 'annual meet', 'reunion', 'meet'],
  '/my-gallery': ['gallery', 'photos', 'album', 'pictures'],
  '/announcements': ['announcements', 'announcement', 'news', 'notification'],
  '/connect': [
    'connect',
    'chat',
    'message',
    'community',
    'finance council',
    'financial decisions',
  ],
  '/member/alumni-roll': [
    'alumni member',
    'alumni roll',
    'alumni',
    'directory',
    'membership',
    'batchmates',
    'registry',
  ],
  '/my-payments': ['payments', 'payment', 'receipt', 'invoice'],
  '/settings': ['settings', 'setting', 'preferences', 'account'],
};

class AppSearchService {
  AppSearchService({
    ProfilesApiService? profilesApi,
    EventsApiService? eventsApi,
    GalleryApiService? galleryApi,
    AnnouncementsApiService? announcementsApi,
  })  : _profilesApi = profilesApi ?? ProfilesApiService(),
        _eventsApi = eventsApi ?? EventsApiService(),
        _galleryApi = galleryApi ?? GalleryApiService(),
        _announcementsApi = announcementsApi ?? AnnouncementsApiService();

  final ProfilesApiService _profilesApi;
  final EventsApiService _eventsApi;
  final GalleryApiService _galleryApi;
  final AnnouncementsApiService _announcementsApi;

  Future<List<AppSearchResult>> search(String rawQuery) async {
    final query = _normalizeQuery(rawQuery);
    if (query.length < 2) return [];

    final results = <AppSearchResult>[
      ..._matchPages(query),
    ];

    await Future.wait([
      _searchAlumni(query, results),
      _searchEvents(query, results),
      _searchGallery(query, results),
      _searchAnnouncements(query, results),
    ]);

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(20).toList();
  }

  String _normalizeQuery(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    const typos = <String, String>{
      'gallary': 'gallery',
      'galery': 'gallery',
      'gallrey': 'gallery',
      'profle': 'profile',
      'evnts': 'events',
      'eventts': 'events',
      'anouncement': 'announcement',
      'announcment': 'announcement',
    };
    return typos[query] ?? query;
  }

  List<AppSearchResult> _matchPages(String query) {
    final q = query.toLowerCase();
    final matches = <AppSearchResult>[];

    for (final item in dashboardNavItems) {
      final label = item.label.toLowerCase();
      final keywords = _pageKeywords[item.path] ?? [];
      var score = 0;

      if (label == q) {
        score = 100;
      } else if (label.startsWith(q)) {
        score = 80;
      } else if (label.contains(q)) {
        score = 60;
      } else {
        for (final keyword in keywords) {
          if (keyword == q) {
            score = 90;
            break;
          }
          if (keyword.startsWith(q) || q.startsWith(keyword)) {
            score = 70;
            break;
          }
          if (keyword.contains(q)) {
            score = 50;
            break;
          }
        }
      }

      if (score > 0) {
        matches.add(
          AppSearchResult(
            type: AppSearchResultType.page,
            title: item.label,
            subtitle: 'Go to ${item.label}',
            route: item.path,
            icon: item.icon,
            score: score,
          ),
        );
      }
    }

    return matches;
  }

  Future<void> _searchAlumni(String query, List<AppSearchResult> results) async {
    try {
      final page = await _profilesApi.fetchDirectory(
        search: query,
        membershipNumber: _looksLikeMembershipId(query) ? query : null,
        pageSize: 5,
      );
      for (final profile in page.profiles) {
        results.add(
          AppSearchResult(
            type: AppSearchResultType.alumni,
            title: profile.fullName,
            subtitle: profile.subtitle,
            route: '/member/profiles/${profile.id}',
            icon: Icons.person_outline_rounded,
            score: _textScore(profile.fullName, query) + 10,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _searchEvents(String query, List<AppSearchResult> results) async {
    try {
      final events = await _eventsApi.fetchEvents();
      final q = query.toLowerCase();
      for (final event in events) {
        final haystack = [
          event.title,
          event.description,
          event.venueName,
          event.city,
        ].whereType<String>().join(' ').toLowerCase();

        if (!haystack.contains(q)) continue;

        results.add(
          AppSearchResult(
            type: AppSearchResultType.event,
            title: event.title,
            subtitle: event.displayDate,
            route: '/my-events/${event.slug}',
            icon: Icons.event_outlined,
            score: _textScore(event.title, query) + 8,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _searchGallery(String query, List<AppSearchResult> results) async {
    try {
      final albums = await _galleryApi.fetchAlbums();
      final q = query.toLowerCase();
      for (final album in albums) {
        final haystack = [
          album.title,
          album.description,
        ].whereType<String>().join(' ').toLowerCase();

        if (!haystack.contains(q)) continue;

        results.add(
          AppSearchResult(
            type: AppSearchResultType.galleryAlbum,
            title: album.title,
            subtitle: album.mediaCount > 0
                ? '${album.mediaCount} photos'
                : 'Gallery album',
            route: '/my-gallery/album/${album.slug}',
            icon: Icons.photo_library_outlined,
            score: _textScore(album.title, query) + 6,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _searchAnnouncements(
    String query,
    List<AppSearchResult> results,
  ) async {
    try {
      final items = await _announcementsApi.fetchAnnouncements();
      final q = query.toLowerCase();
      for (final item in items) {
        final haystack = [
          item.title,
          item.categoryLabel,
        ].join(' ').toLowerCase();

        if (!haystack.contains(q)) continue;

        results.add(
          AppSearchResult(
            type: AppSearchResultType.announcement,
            title: item.title,
            subtitle: item.categoryLabel,
            route: '/announcements',
            icon: Icons.campaign_outlined,
            score: _textScore(item.title, query) + 4,
          ),
        );
      }
    } catch (_) {}
  }

  int _textScore(String text, String query) {
    final value = text.toLowerCase();
    final q = query.toLowerCase();
    if (value == q) return 100;
    if (value.startsWith(q)) return 80;
    if (value.contains(q)) return 60;
    return 40;
  }

  bool _looksLikeMembershipId(String query) {
    final q = query.trim().toLowerCase();
    return q.startsWith('kmc-') || RegExp(r'^\d{4}[a-z]+\d{3,6}$').hasMatch(q);
  }
}
