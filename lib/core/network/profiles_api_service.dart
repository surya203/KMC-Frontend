import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class FeaturedProfile {
  const FeaturedProfile({
    required this.id,
    required this.fullName,
    required this.batchYear,
    this.currentTitle,
    this.organization,
    this.bio,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final int batchYear;
  final String? currentTitle;
  final String? organization;
  final String? bio;
  final String? photoUrl;

  String get subtitle {
    final parts = <String>[];
    if (currentTitle != null && currentTitle!.isNotEmpty) {
      parts.add(currentTitle!);
    }
    if (organization != null && organization!.isNotEmpty) {
      parts.add(organization!);
    }
    parts.add('Batch $batchYear');
    return parts.join(' · ');
  }

  factory FeaturedProfile.fromJson(Map<String, dynamic> json) {
    return FeaturedProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      batchYear: json['batch_year'] as int,
      currentTitle: json['current_title'] as String?,
      organization: json['organization'] as String?,
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class DirectoryProfile {
  const DirectoryProfile({
    required this.id,
    required this.fullName,
    required this.batchYear,
    this.degree,
    this.specialization,
    this.currentTitle,
    this.organization,
    this.city,
    this.country,
    this.photoUrl,
    this.membershipNumber,
    this.practiceLocation,
  });

  final String id;
  final String fullName;
  final int batchYear;
  final String? degree;
  final String? specialization;
  final String? currentTitle;
  final String? organization;
  final String? city;
  final String? country;
  final String? photoUrl;
  final String? membershipNumber;
  final String? practiceLocation;

  String get subtitle {
    final parts = <String>[];
    if (specialization != null && specialization!.isNotEmpty) {
      parts.add(specialization!);
    } else if (degree != null && degree!.isNotEmpty) {
      parts.add(degree!);
    }
    final place = city ?? practiceLocation;
    if (place != null && place.isNotEmpty) {
      parts.add(place);
    }
    if (currentTitle != null && currentTitle!.isNotEmpty) {
      parts.add(currentTitle!);
    }
    if (organization != null && organization!.isNotEmpty) {
      parts.add(organization!);
    }
    parts.add('Batch $batchYear');
    return parts.join(' · ');
  }

  factory DirectoryProfile.fromJson(Map<String, dynamic> json) {
    return DirectoryProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      batchYear: json['batch_year'] as int,
      degree: json['degree'] as String?,
      specialization: json['specialization'] as String?,
      currentTitle: json['current_title'] as String?,
      organization: json['organization'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      photoUrl: json['photo_url'] as String?,
      membershipNumber: json['membership_number'] as String?,
      practiceLocation: json['practice_location'] as String?,
    );
  }
}

class ProfileDetail {
  const ProfileDetail({
    required this.id,
    required this.fullName,
    required this.batchYear,
    this.degree,
    this.specialization,
    this.currentTitle,
    this.organization,
    this.city,
    this.country,
    this.bio,
    this.linkedinUrl,
    this.photoUrl,
    this.practiceLocation,
    this.phone,
    this.membershipNumber,
  });

  final String id;
  final String fullName;
  final int batchYear;
  final String? degree;
  final String? specialization;
  final String? currentTitle;
  final String? organization;
  final String? city;
  final String? country;
  final String? bio;
  final String? linkedinUrl;
  final String? photoUrl;
  final String? practiceLocation;
  final String? phone;
  final String? membershipNumber;

  factory ProfileDetail.fromJson(Map<String, dynamic> json) {
    return ProfileDetail(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      batchYear: json['batch_year'] as int,
      degree: json['degree'] as String?,
      specialization: json['specialization'] as String?,
      currentTitle: json['current_title'] as String?,
      organization: json['organization'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      photoUrl: json['photo_url'] as String?,
      practiceLocation: json['practice_location'] as String?,
      phone: json['phone'] as String?,
      membershipNumber: json['membership_number'] as String?,
    );
  }
}

class ProfilesPage {
  const ProfilesPage({
    required this.profiles,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  final List<DirectoryProfile> profiles;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
}

class MyProfile {
  const MyProfile({
    required this.id,
    required this.fullName,
    required this.batchYear,
    this.degree,
    this.specialization,
    this.currentTitle,
    this.organization,
    this.city,
    this.country,
    this.bio,
    this.linkedinUrl,
    this.photoUrl,
    this.phone,
    this.verificationStatus,
    this.isDirectoryVisible,
  });

  final String id;
  final String fullName;
  final int batchYear;
  final String? degree;
  final String? specialization;
  final String? currentTitle;
  final String? organization;
  final String? city;
  final String? country;
  final String? bio;
  final String? linkedinUrl;
  final String? photoUrl;
  final String? phone;
  final String? verificationStatus;
  final bool? isDirectoryVisible;

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    return MyProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      batchYear: json['batch_year'] as int,
      degree: json['degree'] as String?,
      specialization: json['specialization'] as String?,
      currentTitle: json['current_title'] as String?,
      organization: json['organization'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      photoUrl: json['photo_url'] as String?,
      phone: json['phone'] as String?,
      verificationStatus: json['verification_status'] as String?,
      isDirectoryVisible: json['is_directory_visible'] as bool?,
    );
  }

  MyProfile copyWith({
    String? photoUrl,
    String? phone,
    String? currentTitle,
    String? organization,
    String? city,
    String? bio,
    String? linkedinUrl,
    bool? isDirectoryVisible,
  }) {
    return MyProfile(
      id: id,
      fullName: fullName,
      batchYear: batchYear,
      degree: degree,
      specialization: specialization,
      currentTitle: currentTitle ?? this.currentTitle,
      organization: organization ?? this.organization,
      city: city ?? this.city,
      country: country,
      bio: bio ?? this.bio,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      verificationStatus: verificationStatus,
      isDirectoryVisible: isDirectoryVisible ?? this.isDirectoryVisible,
    );
  }
}

class ProfilesApiService {
  ProfilesApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<FeaturedProfile>> fetchFeatured() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/featured',
      );
      final profiles = response.data?['profiles'] as List<dynamic>? ?? [];
      return profiles
          .map((e) => FeaturedProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<ProfilesPage> fetchDirectory({
    String? search,
    int? batchYear,
    String? country,
    String? location,
    String? category,
    String? membershipNumber,
    String? phone,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'search': search,
        'batch_year': batchYear,
        'country': country,
        'location': location,
        'category': category,
        'membership_number': membershipNumber,
        'phone': phone,
        'page': page,
        'page_size': pageSize,
      };
      queryParameters.removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty),
      );
      final header = AuthService.authorizationHeader;
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles',
        queryParameters: queryParameters,
        options: header != null
            ? Options(headers: {'Authorization': header})
            : null,
      );
      final data = response.data ?? {};
      final profiles = data['profiles'] as List<dynamic>? ?? [];
      return ProfilesPage(
        profiles: profiles
            .map((e) => DirectoryProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: data['page'] as int? ?? page,
        pageSize: data['page_size'] as int? ?? pageSize,
        total: data['total'] as int? ?? 0,
        hasMore: data['has_more'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<ProfileDetail> fetchProfileById(String id) async {
    try {
      final header = AuthService.authorizationHeader;
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/$id',
        options: header != null
            ? Options(headers: {'Authorization': header})
            : null,
      );
      if (response.data == null) throw Exception('Profile not found.');
      return ProfileDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<MyProfile> fetchMyProfile() async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/me',
        options: Options(headers: {'Authorization': header}),
      );
      if (response.data == null) throw Exception('Profile not found.');
      return MyProfile.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<MyProfile> updateMyProfile(Map<String, dynamic> fields) async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Not signed in.');
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/me',
        data: fields,
        options: Options(headers: {'Authorization': header}),
      );
      if (response.data == null) throw Exception('Update failed.');
      return MyProfile.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_readDetail(e));
    }
  }

  Future<String> uploadProfilePhoto(PlatformFile file) async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Not signed in.');
    if (file.bytes == null) throw Exception('Could not read image file.');

    final mimeType = _mimeTypeFromFilename(file.name);
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/me/photo',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
            contentType: DioMediaType.parse(mimeType),
          ),
        }),
        options: Options(headers: {'Authorization': header}),
      );
      final url = response.data?['photo_url'] as String?;
      if (url == null || url.isEmpty) throw Exception('Upload failed.');
      return url;
    } on DioException catch (e) {
      // Some backends expect "photo" instead of "file"; retry once.
      final status = e.response?.statusCode ?? 0;
      if (status == 400 || status == 415 || status == 422) {
        try {
          final retry = await _apiClient.dio.post<Map<String, dynamic>>(
            '${AppConfig.apiPrefix}/profiles/me/photo',
            data: FormData.fromMap({
              'photo': MultipartFile.fromBytes(
                file.bytes!,
                filename: file.name,
                contentType: DioMediaType.parse(mimeType),
              ),
            }),
            options: Options(headers: {'Authorization': header}),
          );
          final url = retry.data?['photo_url'] as String?;
          if (url != null && url.isNotEmpty) return url;
        } on DioException {
          // Fall through to the original error detail.
        }
      }
      throw Exception(_readDetail(e));
    }
  }

  Future<void> removeProfilePhoto() async {
    final header = AuthService.authorizationHeader;
    if (header == null) throw Exception('Not signed in.');
    final options = Options(headers: {'Authorization': header});
    try {
      await _apiClient.delete<void>(
        '${AppConfig.apiPrefix}/profiles/me/photo',
        options: options,
      );
      return;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 404 || status == 405 || status == 422) {
        try {
          await _apiClient.patch<Map<String, dynamic>>(
            '${AppConfig.apiPrefix}/profiles/me',
            data: {'photo_url': null},
            options: options,
          );
          return;
        } on DioException catch (retry) {
          throw Exception(_readDetail(retry));
        }
      }
      throw Exception(_readDetail(e));
    }
  }

  String _mimeTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/jpeg';
  }

  String _readDetail(DioException e) {
    final detail = e.response?.data;
    if (detail is Map) {
      if (detail['detail'] != null) return _formatDetail(detail['detail']);
      final errors = detail['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((item) => _formatDetail(item)).join(' ');
      }
      if (detail['message'] != null) return '${detail['message']}';
    }
    if (detail is List && detail.isNotEmpty) {
      return detail.map((item) => _formatDetail(item)).join(' ');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Could not reach the server. Check that the backend is running.';
    }
    return e.response?.statusMessage ?? 'Profile request failed.';
  }

  String _formatDetail(Object detail) {
    if (detail is Map) {
      final msg = detail['msg'];
      if (msg != null) {
        final loc = detail['loc'];
        if (loc is List && loc.isNotEmpty) {
          final field = loc.last;
          if (field == 'phone') {
            return 'Mobile number must be exactly 10 digits (without +91).';
          }
          if (field == 'linkedin_url') {
            return 'Enter a valid LinkedIn URL (e.g. https://www.linkedin.com/in/your-name).';
          }
          return '$field: $msg';
        }
        return '$msg';
      }
    }
    return '$detail';
  }
}
