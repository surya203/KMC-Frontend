import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class GalleryAlbum {
  const GalleryAlbum({
    required this.id,
    required this.slug,
    required this.title,
    required this.mediaCount,
    this.description,
    this.coverImageUrl,
  });

  final String id;
  final String slug;
  final String title;
  final int mediaCount;
  final String? description;
  final String? coverImageUrl;

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    return GalleryAlbum(
      id: '${json['id']}',
      slug: '${json['slug']}',
      title: '${json['title']}',
      mediaCount: json['media_count'] is int
          ? json['media_count'] as int
          : int.tryParse('${json['media_count']}') ?? 0,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
    );
  }
}

class GalleryMedia {
  const GalleryMedia({
    required this.id,
    required this.url,
    this.caption,
    this.sortOrder = 0,
  });

  final String id;
  final String url;
  final String? caption;
  final int sortOrder;

  factory GalleryMedia.fromJson(Map<String, dynamic> json) {
    return GalleryMedia(
      id: '${json['id']}',
      url: '${json['url']}',
      caption: json['caption'] as String?,
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse('${json['sort_order']}') ?? 0,
    );
  }
}

class GalleryAlbumDetail extends GalleryAlbum {
  const GalleryAlbumDetail({
    required super.id,
    required super.slug,
    required super.title,
    required super.mediaCount,
    super.description,
    super.coverImageUrl,
    this.media = const [],
  });

  final List<GalleryMedia> media;

  factory GalleryAlbumDetail.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    return GalleryAlbumDetail(
      id: '${json['id']}',
      slug: '${json['slug']}',
      title: '${json['title']}',
      mediaCount: json['media_count'] is int
          ? json['media_count'] as int
          : int.tryParse('${json['media_count']}') ?? 0,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      media: media is List
          ? [
              for (final item in media)
                if (item is Map<String, dynamic>)
                  GalleryMedia.fromJson(item),
            ]
          : const [],
    );
  }
}

class GalleryService {
  GalleryService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<GalleryAlbum>> fetchAlbums() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums',
      );
      final albums = response.data?['albums'];
      if (response.statusCode == 200 && albums is List) {
        return [
          for (final item in albums)
            if (item is Map<String, dynamic>) GalleryAlbum.fromJson(item),
        ];
      }
    } catch (_) {}
    return const [];
  }

  Future<GalleryAlbumDetail> fetchAlbum(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$slug',
      );
      if (response.statusCode == 200 && response.data != null) {
        return GalleryAlbumDetail.fromJson(response.data!);
      }
      throw const ApiException('Album not found.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<List<GalleryMedia>> fetchAlbumMedia(
    String slug, {
    int page = 1,
    int pageSize = 24,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$slug/media',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final media = response.data?['media'];
      if (response.statusCode == 200 && media is List) {
        return [
          for (final item in media)
            if (item is Map<String, dynamic>) GalleryMedia.fromJson(item),
        ];
      }
    } catch (_) {}
    return const [];
  }
}
