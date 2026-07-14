import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class GalleryAlbum {
  const GalleryAlbum({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.mediaCount = 0,
    this.createdBy,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int mediaCount;
  final String? createdBy;

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    return GalleryAlbum(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      mediaCount: json['media_count'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
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

class GalleryExternalLink {
  const GalleryExternalLink({
    required this.id,
    required this.linkType,
    required this.url,
    this.title,
    this.createdAt,
  });

  final String id;
  final String linkType;
  final String url;
  final String? title;
  final DateTime? createdAt;

  factory GalleryExternalLink.fromJson(Map<String, dynamic> json) {
    return GalleryExternalLink(
      id: json['id'] as String,
      linkType: json['link_type'] as String,
      url: json['url'] as String,
      title: json['title'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
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
    this.externalLinks = const [],
    this.createdBy,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int mediaCount;
  final List<GalleryMediaItem> media;
  final List<GalleryExternalLink> externalLinks;
  final String? createdBy;

  factory GalleryAlbumDetail.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] as List<dynamic>? ?? [];
    final rawLinks = json['external_links'] as List<dynamic>? ?? [];
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
      externalLinks: rawLinks
          .map((e) => GalleryExternalLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdBy: json['created_by'] as String?,
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

  Options get _authOptions {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in required.');
    return Options(headers: {'Authorization': header});
  }

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
        },
        options: _authOptions,
      );
      if (response.data == null) throw Exception('Album creation failed.');
      return GalleryAlbumDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  /// Staff create — uses admin API and publishes immediately.
  Future<GalleryAlbum> createAlbumAsAdmin({
    required String slug,
    required String title,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/admin/gallery/albums',
        data: {
          'slug': slug,
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          'publish': true,
        },
        options: _authOptions,
      );
      if (response.data == null) throw Exception('Album creation failed.');
      return GalleryAlbum.fromJson({
        ...response.data!,
        'media_count': response.data!['media_count'] ?? 0,
      });
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<GalleryAlbum>> fetchAlbumsAsAdmin() async {
    try {
      final response = await _apiClient.get<dynamic>(
        '${AppConfig.apiPrefix}/admin/gallery/albums',
        options: _authOptions,
      );
      final raw = response.data;
      final albums = raw is List
          ? raw
          : (raw is Map ? (raw['albums'] as List<dynamic>? ?? []) : <dynamic>[]);
      return albums
          .map((e) => GalleryAlbum.fromJson({
                ...(e as Map<String, dynamic>),
                'media_count': e['media_count'] ?? 0,
              }))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
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
          if (title != null) 'title': title,
          if (description != null) 'description': description,
        },
        options: _authOptions,
      );
      if (response.data == null) throw Exception('Album update failed.');
      return GalleryAlbumDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> updateAlbumAsAdmin({
    required String albumId,
    String? title,
    String? description,
  }) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/admin/gallery/albums/$albumId',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
        },
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      await _apiClient.delete<void>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> deleteAlbumAsAdmin(String albumId) async {
    try {
      await _apiClient.delete<void>(
        '${AppConfig.apiPrefix}/admin/gallery/albums/$albumId',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<List<GalleryMediaItem>> uploadAlbumMedia({
    required String albumId,
    required List<PlatformFile> files,
  }) async {
    if (files.isEmpty) throw Exception('Select at least one image.');

    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Sign in required.');

    final multipartFiles = <MultipartFile>[];
    for (final file in files) {
      if (file.bytes == null) continue;
      multipartFiles.add(
        MultipartFile.fromBytes(file.bytes!, filename: file.name),
      );
    }
    if (multipartFiles.isEmpty) {
      throw Exception('Could not read selected images.');
    }

    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/admin/gallery/media',
        data: FormData.fromMap({
          'album_id': albumId,
          'files': multipartFiles,
        }),
        options: Options(
          headers: {'Authorization': header},
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final uploaded = response.data?['uploaded'] as List<dynamic>? ?? [];
      return uploaded
          .map(
            (e) => GalleryMediaItem(
              id: e['id'] as String,
              storagePath: e['storage_path'] as String,
              storageUrl: e['storage_url'] as String?,
              caption: e['caption'] as String?,
              sortOrder: e['sort_order'] as int? ?? 0,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> deleteMedia({
    required String albumId,
    required String mediaId,
    bool asAdmin = false,
  }) async {
    try {
      final path = asAdmin
          ? '${AppConfig.apiPrefix}/admin/gallery/albums/$albumId/media/$mediaId'
          : '${AppConfig.apiPrefix}/gallery/albums/$albumId/media/$mediaId';
      await _apiClient.delete<void>(path, options: _authOptions);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<GalleryExternalLink> addDriveLink({
    required String albumId,
    required String title,
    required String url,
    String linkType = 'drive_folder',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/drive-link',
        data: {
          'title': title,
          'url': url,
          'link_type': linkType,
        },
        options: _authOptions,
      );
      if (response.data == null) throw Exception('Drive link creation failed.');
      return GalleryExternalLink.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<GalleryExternalLink> updateDriveLink({
    required String albumId,
    required String linkId,
    String? title,
    String? url,
    String? linkType,
  }) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/drive-link/$linkId',
        data: {
          if (title != null) 'title': title,
          if (url != null) 'url': url,
          if (linkType != null) 'link_type': linkType,
        },
        options: _authOptions,
      );
      if (response.data == null) throw Exception('Drive link update failed.');
      return GalleryExternalLink.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<void> deleteDriveLink({
    required String albumId,
    required String linkId,
  }) async {
    try {
      await _apiClient.delete<void>(
        '${AppConfig.apiPrefix}/gallery/albums/$albumId/drive-link/$linkId',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map && detail['detail'] != null) {
      return '${detail['detail']}';
    }
    return e.response?.statusMessage ?? 'Gallery request failed.';
  }
}
