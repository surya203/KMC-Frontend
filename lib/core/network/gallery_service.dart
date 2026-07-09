import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

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
    this.createdBy,
  });

  final String id;
  final String slug;
  final String title;
  final int mediaCount;
  final String? description;
  final String? coverImageUrl;
  final String? createdBy;

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
      createdBy: json['created_by'] as String?,
    );
  }

  bool isOwnedBy(String? userId) {
    if (userId == null || createdBy == null) return false;
    return createdBy == userId;
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
      url: '${json['storage_url'] ?? json['url']}',
      caption: json['caption'] as String?,
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse('${json['sort_order']}') ?? 0,
    );
  }
}

class GalleryExternalLink {
  const GalleryExternalLink({
    required this.id,
    required this.linkType,
    required this.title,
    required this.url,
  });

  final String id;
  final String linkType;
  final String title;
  final String url;

  factory GalleryExternalLink.fromJson(Map<String, dynamic> json) {
    return GalleryExternalLink(
      id: '${json['id']}',
      linkType: '${json['link_type']}',
      title: '${json['title'] ?? ''}',
      url: '${json['url']}',
    );
  }

  String get label =>
      linkType == 'drive_folder' ? 'Google Drive folder' : 'Google Drive album';
}

class GalleryAlbumDetail extends GalleryAlbum {
  const GalleryAlbumDetail({
    required super.id,
    required super.slug,
    required super.title,
    required super.mediaCount,
    super.description,
    super.coverImageUrl,
    super.createdBy,
    this.media = const [],
    this.externalLinks = const [],
  });

  final List<GalleryMedia> media;
  final List<GalleryExternalLink> externalLinks;

  factory GalleryAlbumDetail.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    final links = json['external_links'];
    return GalleryAlbumDetail(
      id: '${json['id']}',
      slug: '${json['slug']}',
      title: '${json['title']}',
      mediaCount: json['media_count'] is int
          ? json['media_count'] as int
          : int.tryParse('${json['media_count']}') ?? 0,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      createdBy: json['created_by'] as String?,
      media: media is List
          ? [
              for (final item in media)
                if (item is Map<String, dynamic>)
                  GalleryMedia.fromJson(item),
            ]
          : const [],
      externalLinks: links is List
          ? [
              for (final item in links)
                if (item is Map<String, dynamic>)
                  GalleryExternalLink.fromJson(item),
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
      throw const ApiException('Could not load gallery albums.');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiClient.wrapError(error);
    }
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
      final media = response.data?['items'] ?? response.data?['media'];
      if (response.statusCode == 200 && media is List) {
        return [
          for (final item in media)
            if (item is Map<String, dynamic>) GalleryMedia.fromJson(item),
        ];
      }
    } catch (_) {}
    return const [];
  }

  Future<GalleryAlbumDetail> createAlbum({
    required String slug,
    required String title,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums',
        data: {
          'slug': slug,
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          'publish': true,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return GalleryAlbumDetail.fromJson(response.data!);
      }
      throw const ApiException('Could not create album.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> uploadMedia({
    required String albumId,
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'files': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType.parse(_imageContentType(filename)),
      ),
    });
    try {
      await _apiClient.postMultipart<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/upload',
        data: formData,
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> addDriveLink({
    required String albumId,
    required String title,
    required String url,
    required String linkType,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/drive-link',
        data: {'title': title.trim(), 'url': url.trim(), 'link_type': linkType},
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> updateDriveLink({
    required String albumId,
    required String linkId,
    String? title,
    String? url,
    String? linkType,
  }) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/drive-link/$linkId',
        data: {
          'title': title?.trim(),
          'url': url?.trim(),
          'link_type': linkType,
        },
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> deleteDriveLink({
    required String albumId,
    required String linkId,
  }) async {
    try {
      await _apiClient.dio.delete(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/drive-link/$linkId',
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> updateMediaCaption({
    required String albumId,
    required String mediaId,
    required String caption,
  }) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/media/$mediaId',
        data: {'caption': caption},
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> deleteMedia({
    required String albumId,
    required String mediaId,
  }) async {
    try {
      await _apiClient.dio.delete(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/media/$mediaId',
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<GalleryAlbumDetail> updateAlbum({
    required String albumId,
    String? title,
    String? description,
  }) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId',
        data: {
          'title': title,
          'description': description,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return GalleryAlbumDetail.fromJson(response.data!);
      }
      throw const ApiException('Could not update album.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      await _apiClient.dio.delete(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId',
      );
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }
}

String _imageContentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
