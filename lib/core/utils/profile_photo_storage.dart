import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'compress_profile_photo.dart';

/// Persists profile photo bytes locally so avatars work when remote URLs fail.
class ProfilePhotoStorage {
  ProfilePhotoStorage._();

  static final ProfilePhotoStorage instance = ProfilePhotoStorage._();

  String _bytesKey(String userId) => 'kmc_profile_photo_bytes_$userId';
  String _urlKey(String userId) => 'kmc_profile_photo_url_$userId';

  Future<bool> save({
    required String userId,
    required Uint8List bytes,
    String? url,
  }) async {
    if (userId.isEmpty || bytes.isEmpty) return false;
    if (!looksLikeImageBytes(bytes)) return false;

    try {
      final compressed = await compressProfilePhoto(bytes);
      final prefs = await SharedPreferences.getInstance();
      final encoded = base64Encode(compressed);
      final saved = await prefs.setString(_bytesKey(userId), encoded);
      if (!saved) return false;
      if (url != null && url.trim().isNotEmpty) {
        await prefs.setString(_urlKey(userId), url.split('?').first.trim());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> loadBytes(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_bytesKey(userId));
      if (encoded == null || encoded.isEmpty) return null;
      final bytes = base64Decode(encoded);
      if (bytes.isEmpty) return null;
      final result = Uint8List.fromList(bytes);
      if (!looksLikeImageBytes(result)) return null;
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<String?> loadUrl(String userId) async {
    if (userId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey(userId));
  }

  Future<void> clear(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bytesKey(userId));
    await prefs.remove(_urlKey(userId));
  }
}
