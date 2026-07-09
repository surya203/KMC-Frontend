import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';

class GalleryAlbum {
  const GalleryAlbum({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.mediaCount = 0,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int mediaCount;

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    return GalleryAlbum(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      mediaCount: json['media_count'] as int? ?? 0,
    );
  }
}

class GalleryMediaItem {
  const GalleryMediaItem({
    required this.id,
    required this.storagePath,
    this.caption,
    this.storageUrl,
    this.thumbnailUrl,
    this.sortOrder = 0,
  });

  final String id;
  final String storagePath;
  final String? caption;
  final String? storageUrl;
  final String? thumbnailUrl;
  final int sortOrder;

  String get imageUrl => storageUrl ?? storagePath;

  factory GalleryMediaItem.fromJson(Map<String, dynamic> json) {
    return GalleryMediaItem(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      caption: json['caption'] as String?,
      storageUrl: json['storage_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class GalleryAlbumDetail {
  const GalleryAlbumDetail({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.mediaCount = 0,
    this.media = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int mediaCount;
  final List<GalleryMediaItem> media;

  factory GalleryAlbumDetail.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] as List<dynamic>? ?? [];
    return GalleryAlbumDetail(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      mediaCount: json['media_count'] as int? ?? 0,
      media: rawMedia
          .map((e) => GalleryMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GalleryMediaPage {
  const GalleryMediaPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final List<GalleryMediaItem> items;
  final int page;
  final int total;
  final bool hasMore;
}

class GalleryApiService {
  GalleryApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<GalleryAlbum>> fetchAlbums() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums',
      );
      final albums = response.data?['albums'] as List<dynamic>? ?? [];
      return albums
          .map((e) => GalleryAlbum.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<GalleryAlbumDetail> fetchAlbumBySlug(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$slug',
      );
      if (response.data == null) throw Exception('Album not found.');
      return GalleryAlbumDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<GalleryMediaPage> fetchAlbumMediaPage(
    String slug, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$slug/media',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final data = response.data ?? {};
      final raw = (data['items'] ?? data['media']) as List<dynamic>? ?? [];
      return GalleryMediaPage(
        items: raw
            .map((e) => GalleryMediaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: data['page'] as int? ?? page,
        total: data['total'] as int? ?? raw.length,
        hasMore: data['has_more'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<GalleryMediaItem>> fetchAlbumMedia(
    String slug, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await fetchAlbumMediaPage(
      slug,
      page: page,
      pageSize: pageSize,
    );
    return result.items;
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      return '${detail['detail']}';
    }
    return e.response?.statusMessage ?? 'Gallery request failed.';
  }
}
