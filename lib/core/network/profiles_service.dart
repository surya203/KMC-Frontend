import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ProfileSummary {
  const ProfileSummary({
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
    this.bio,
    this.linkedinUrl,
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
  final String? bio;
  final String? linkedinUrl;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      id: '${json['id']}',
      fullName: '${json['full_name']}',
      batchYear: json['batch_year'] is int
          ? json['batch_year'] as int
          : int.tryParse('${json['batch_year']}') ?? 0,
      degree: json['degree'] as String?,
      specialization: json['specialization'] as String?,
      currentTitle: json['current_title'] as String?,
      organization: json['organization'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
    );
  }
}

class MyProfile extends ProfileSummary {
  const MyProfile({
    required super.id,
    required super.fullName,
    required super.batchYear,
    super.degree,
    super.specialization,
    super.currentTitle,
    super.organization,
    super.city,
    super.country,
    super.photoUrl,
    super.bio,
    super.linkedinUrl,
    this.phone,
    this.verificationStatus,
    this.isDirectoryVisible,
  });

  final String? phone;
  final String? verificationStatus;
  final bool? isDirectoryVisible;

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    return MyProfile(
      id: '${json['id']}',
      fullName: '${json['full_name']}',
      batchYear: json['batch_year'] is int
          ? json['batch_year'] as int
          : int.tryParse('${json['batch_year']}') ?? 0,
      degree: json['degree'] as String?,
      specialization: json['specialization'] as String?,
      currentTitle: json['current_title'] as String?,
      organization: json['organization'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      phone: json['phone'] as String?,
      verificationStatus: json['verification_status'] as String?,
      isDirectoryVisible: json['is_directory_visible'] as bool?,
    );
  }
}

class ProfilesPage {
  const ProfilesPage({
    required this.profiles,
    required this.page,
    required this.hasMore,
    required this.total,
  });

  final List<ProfileSummary> profiles;
  final int page;
  final bool hasMore;
  final int total;
}

class ProfilesService {
  ProfilesService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<ProfileSummary>> fetchFeatured() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/featured',
      );
      final profiles = response.data?['profiles'];
      if (response.statusCode == 200 && profiles is List) {
        return [
          for (final item in profiles)
            if (item is Map<String, dynamic>)
              ProfileSummary.fromJson(item),
        ];
      }
    } catch (_) {}
    return const [];
  }

  Future<ProfilesPage> searchProfiles({
    int? batchYear,
    String? country,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles',
        queryParameters: {
          'batch_year': ?batchYear,
          if (country != null && country.isNotEmpty) 'country': country,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final profiles = data['profiles'];
        return ProfilesPage(
          profiles: profiles is List
              ? [
                  for (final item in profiles)
                    if (item is Map<String, dynamic>)
                      ProfileSummary.fromJson(item),
                ]
              : const [],
          page: data['page'] is int
              ? data['page'] as int
              : int.tryParse('${data['page']}') ?? page,
          hasMore: data['has_more'] == true,
          total: data['total'] is int
              ? data['total'] as int
              : int.tryParse('${data['total']}') ?? 0,
        );
      }
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
    return const ProfilesPage(profiles: [], page: 1, hasMore: false, total: 0);
  }

  Future<ProfileSummary> fetchById(String profileId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/$profileId',
      );
      if (response.statusCode == 200 && response.data != null) {
        return ProfileSummary.fromJson(response.data!);
      }
      throw const ApiException('Profile not found.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<MyProfile> fetchMyProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/me',
      );
      if (response.statusCode == 200 && response.data != null) {
        return MyProfile.fromJson(response.data!);
      }
      throw const ApiException('Profile not found.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<MyProfile> updateMyProfile(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/me',
        data: body,
      );
      if (response.statusCode == 200 && response.data != null) {
        return MyProfile.fromJson(response.data!);
      }
      throw const ApiException('Could not update profile.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }

  Future<String> uploadPhoto(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _apiClient.postMultipart<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/profiles/me/photo',
        data: formData,
      );
      if (response.statusCode == 200 && response.data != null) {
        return '${response.data!['photo_url']}';
      }
      throw const ApiException('Could not upload photo.');
    } catch (error) {
      throw ApiClient.wrapError(error);
    }
  }
}
