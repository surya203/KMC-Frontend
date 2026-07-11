import 'package:flutter/foundation.dart';

import '../network/auth_service.dart';
import '../network/profiles_api_service.dart';
import '../utils/compress_profile_photo.dart';
import '../utils/media_url.dart';
import '../utils/profile_photo_loader.dart';
import '../utils/profile_photo_storage.dart';
import 'auth_session.dart';

/// Shared profile display state for My Profile and dashboard top bar.
class ProfileSession extends ChangeNotifier {
  ProfileSession._();

  static final ProfileSession instance = ProfileSession._();

  String? fullName;
  String? photoUrl;
  Uint8List? photoBytes;
  String? _profileId;
  bool _loaded = false;

  String? get profileId => _profileId;

  List<String> get _storageIds {
    final ids = <String>[];
    final authId = AuthService.currentUser?.id;
    if (authId != null && authId.isNotEmpty) ids.add(authId);
    if (_profileId != null &&
        _profileId!.isNotEmpty &&
        !ids.contains(_profileId!)) {
      ids.add(_profileId!);
    }
    return ids;
  }

  Future<void> ensureLoaded({bool force = false}) async {
    await AuthSession.instance.ensureReady();
    if (!AuthSession.instance.isAuthenticated) {
      await clear();
      return;
    }

    await _hydrateFromLocal();

    if (!force && _loaded && photoBytes != null) return;

    try {
      final profile = await ProfilesApiService().fetchMyProfile();
      await updateFromProfile(profile);
    } catch (_) {
      if (photoBytes == null) {
        await _hydrateFromLocal(markLoaded: true);
      }
    }
  }

  Future<void> _hydrateFromLocal({bool markLoaded = false}) async {
    for (final id in _storageIds) {
      final bytes = await ProfilePhotoLoader.instance.loadLocal(id);
      if (bytes != null && bytes.isNotEmpty) {
        photoBytes = bytes;
        photoUrl ??= await ProfilePhotoStorage.instance.loadUrl(id);
        if (markLoaded) _loaded = true;
        notifyListeners();
        return;
      }
    }
  }

  Future<void> updateFromProfile(MyProfile profile) async {
    fullName = profile.fullName;
    _profileId = profile.id;
    photoUrl = _normalizeUrl(profile.photoUrl);

    Uint8List? bytes;
    for (final id in _storageIds) {
      bytes = await ProfilePhotoLoader.instance.loadLocal(id);
      if (bytes != null && bytes.isNotEmpty) break;
    }

    if (bytes == null && photoUrl != null) {
      bytes = await ProfilePhotoLoader.instance.load(
        photoUrl,
        userId: profile.id,
      );
    }

    photoBytes = bytes;
    if (bytes != null) {
      await ProfilePhotoLoader.instance.remember(
        photoUrl,
        bytes,
        userId: profile.id,
      );
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setPhoto({
    required String profileId,
    required String? url,
    required Uint8List bytes,
  }) async {
    _profileId = profileId;
    photoUrl = _normalizeUrl(url);
    final compressed = await compressProfilePhoto(bytes);
    photoBytes = compressed;
    await ProfilePhotoLoader.instance.remember(
      photoUrl,
      compressed,
      userId: profileId,
    );
    _loaded = true;
    notifyListeners();
  }

  /// Saves photo bytes immediately using auth user id before profile fetch.
  Future<void> saveLocalPreview(Uint8List bytes) async {
    final authId = AuthService.currentUser?.id;
    if (authId == null || authId.isEmpty) return;
    final compressed = await compressProfilePhoto(bytes);
    photoBytes = compressed;
    await ProfilePhotoLoader.instance.remember(
      photoUrl,
      compressed,
      userId: authId,
    );
    notifyListeners();
  }

  Future<void> clearPhoto() async {
    for (final id in _storageIds) {
      ProfilePhotoLoader.instance.forget(photoUrl, userId: id);
      await ProfilePhotoStorage.instance.clear(id);
    }
    photoUrl = null;
    photoBytes = null;
    _loaded = true;
    notifyListeners();
  }

  Future<void> clear() async {
    final ids = List<String>.from(_storageIds);
    fullName = null;
    photoUrl = null;
    photoBytes = null;
    _profileId = null;
    _loaded = false;
    ProfilePhotoLoader.instance.clear();
    for (final id in ids) {
      await ProfilePhotoStorage.instance.clear(id);
    }
    notifyListeners();
  }

  String? _normalizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http')) return trimmed.split('?').first;
    return resolveMediaUrl(trimmed);
  }
}
