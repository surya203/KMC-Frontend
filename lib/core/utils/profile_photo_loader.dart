import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../network/auth_service.dart';
import '../utils/compress_profile_photo.dart';
import '../utils/media_url.dart';
import 'profile_photo_storage.dart';

/// Loads and caches profile photos for profile page and top bar avatars.
class ProfilePhotoLoader {
  ProfilePhotoLoader._();

  static final ProfilePhotoLoader instance = ProfilePhotoLoader._();

  final Map<String, Uint8List> _cache = {};
  final Dio _remoteDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.bytes,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  String? _baseKey(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final withoutQuery = url.split('?').first.trim();
    return resolveMediaUrl(withoutQuery);
  }

  Uint8List? cachedForUser(String userId) => _cache['local_$userId'];

  Uint8List? cached(String? url) {
    final key = _baseKey(url);
    if (key == null) return null;
    return _cache[key];
  }

  Future<void> remember(
    String? url,
    Uint8List bytes, {
    required String userId,
  }) async {
    if (userId.isEmpty || bytes.isEmpty) return;
    if (!looksLikeImageBytes(bytes)) return;

    final compressed = await compressProfilePhoto(bytes);
    final key = _baseKey(url) ?? 'local_$userId';
    _cache[key] = compressed;
    _cache['local_$userId'] = compressed;

    await ProfilePhotoStorage.instance.save(
      userId: userId,
      bytes: compressed,
      url: url,
    );

    final authId = AuthService.currentUser?.id;
    if (authId != null && authId.isNotEmpty && authId != userId) {
      _cache['local_$authId'] = compressed;
      await ProfilePhotoStorage.instance.save(
        userId: authId,
        bytes: compressed,
        url: url,
      );
    }
  }

  void forget(String? url, {String? userId}) {
    final key = _baseKey(url);
    if (key != null) _cache.remove(key);
    if (userId != null && userId.isNotEmpty) {
      _cache.remove('local_$userId');
    }
  }

  void clear() => _cache.clear();

  Future<Uint8List?> loadLocal(String userId) async {
    if (userId.isEmpty) return null;

    final memory = _cache['local_$userId'];
    if (memory != null && memory.isNotEmpty) return memory;

    final stored = await ProfilePhotoStorage.instance.loadBytes(userId);
    if (stored != null && stored.isNotEmpty) {
      _cache['local_$userId'] = stored;
      return stored;
    }
    return null;
  }

  Future<Uint8List?> load(String? url, {required String userId}) async {
    final local = await loadLocal(userId);
    if (local != null) return local;

    final key = _baseKey(url);
    if (key == null) return null;

    final remote = await _fetchRemote(key);
    if (remote != null) {
      _cache[key] = remote;
      _cache['local_$userId'] = remote;
      await ProfilePhotoStorage.instance.save(
        userId: userId,
        bytes: remote,
        url: key,
      );
      return remote;
    }
    return null;
  }

  Future<Uint8List?> _fetchRemote(String url) async {
    final header = AuthService.authorizationHeader;
    final attempts = <Map<String, String>?>[
      if (header != null) {'Authorization': header},
      null,
    ];

    for (final headers in attempts) {
      try {
        final response = await _remoteDio.get<List<int>>(
          url,
          options: Options(headers: headers),
        );
        if (response.statusCode == 200 &&
            response.data != null &&
            response.data!.isNotEmpty) {
          final bytes = Uint8List.fromList(response.data!);
          if (looksLikeImageBytes(bytes)) return bytes;
        }
      } catch (_) {
        // Try next strategy.
      }
    }
    return null;
  }
}
