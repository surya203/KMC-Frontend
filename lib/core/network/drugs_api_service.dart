import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../config/app_config.dart';
import '../utils/media_url.dart';
import 'api_client.dart';

class DrugItem {
  const DrugItem({
    required this.id,
    required this.name,
    this.brandName,
    this.genericName,
    this.indications,
    this.form,
    this.dosageStrengths = const [],
    this.tagline,
    this.description,
    this.headerImageUrl,
    this.detailImageUrl,
    this.isPublished = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? brandName;
  final String? genericName;
  final String? indications;
  final String? form;
  final List<String> dosageStrengths;
  final String? tagline;
  final String? description;
  final String? headerImageUrl;
  final String? detailImageUrl;
  final bool isPublished;
  final int sortOrder;

  factory DrugItem.fromJson(Map<String, dynamic> json) {
    final strengths = json['dosage_strengths'];
    return DrugItem(
      id: json['id'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : (json['brand_name'] as String? ?? 'Untitled drug'),
      brandName: json['brand_name'] as String?,
      genericName: json['generic_name'] as String?,
      indications: json['indications'] as String?,
      form: json['form'] as String?,
      dosageStrengths: strengths is List
          ? strengths.map((e) => e.toString()).toList()
          : const [],
      tagline: json['tagline'] as String?,
      description: json['description'] as String?,
      headerImageUrl: resolveMediaUrl(
        json['header_image_url'] as String? ?? json['image_url'] as String?,
      ),
      detailImageUrl: resolveMediaUrl(
        json['detail_image_url'] as String? ??
            json['header_image_url'] as String? ??
            json['image_url'] as String?,
      ),
      isPublished: json['is_published'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class DrugHeaderCard {
  const DrugHeaderCard({
    required this.id,
    required this.name,
    this.headerImageUrl,
    this.isPublished = false,
  });

  final String id;
  final String name;
  final String? headerImageUrl;
  final bool isPublished;

  factory DrugHeaderCard.fromJson(Map<String, dynamic> json) {
    return DrugHeaderCard(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Drug',
      headerImageUrl: resolveMediaUrl(json['header_image_url'] as String?),
      isPublished: json['is_published'] as bool? ?? false,
    );
  }
}

class DrugsApiService {
  DrugsApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  String get _adminBase => '${AppConfig.apiPrefix}/admin/drugs';
  String get _publicBase => '${AppConfig.apiPrefix}/drugs';

  Future<DrugHeaderCard?> fetchHeaderCard() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('$_publicBase/header');
      final data = response.data;
      if (data == null) return null;
      return DrugHeaderCard.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<DrugItem>> fetchPublishedDrugs() async {
    final response = await _client.get<Map<String, dynamic>>(_publicBase);
    final list = response.data?['drugs'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(DrugItem.fromJson)
        .toList();
  }

  Future<DrugItem> fetchPublishedDrug(String id) async {
    final response = await _client.get<Map<String, dynamic>>('$_publicBase/$id');
    return DrugItem.fromJson(response.data!);
  }

  Future<List<DrugItem>> fetchAdminDrugs() async {
    final response = await _client.get<Map<String, dynamic>>(_adminBase);
    final list = response.data?['drugs'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(DrugItem.fromJson)
        .toList();
  }

  Future<DrugItem> createDrug({
    required String name,
    String? description,
    String? genericName,
    String? indications,
    String? form,
    List<String> dosageStrengths = const [],
    String? tagline,
    bool isPublished = true,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      _adminBase,
      data: {
        'name': name,
        'brand_name': name,
        'description': description,
        'generic_name': genericName,
        'indications': indications,
        'form': form,
        'dosage_strengths': dosageStrengths,
        'tagline': tagline,
        'is_published': isPublished,
      },
    );
    return DrugItem.fromJson(response.data!);
  }

  Future<DrugItem> updateDrug({
    required String id,
    String? name,
    String? description,
    String? genericName,
    String? indications,
    String? form,
    List<String>? dosageStrengths,
    String? tagline,
    bool? isPublished,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) {
      payload['name'] = name;
      payload['brand_name'] = name;
    }
    if (description != null) payload['description'] = description;
    if (genericName != null) payload['generic_name'] = genericName;
    if (indications != null) payload['indications'] = indications;
    if (form != null) payload['form'] = form;
    if (dosageStrengths != null) payload['dosage_strengths'] = dosageStrengths;
    if (tagline != null) payload['tagline'] = tagline;
    if (isPublished != null) payload['is_published'] = isPublished;

    final response = await _client.patch<Map<String, dynamic>>(
      '$_adminBase/$id',
      data: payload,
    );
    return DrugItem.fromJson(response.data!);
  }

  Future<void> deleteDrug(String id) async {
    await _client.delete('$_adminBase/$id');
  }

  Future<DrugItem> uploadDrugImage({
    required String id,
    required PlatformFile file,
    required String kind,
  }) async {
    if (file.bytes == null) {
      throw Exception('Selected file has no bytes.');
    }
    final response = await _client.post<Map<String, dynamic>>(
      '$_adminBase/$id/image',
      queryParameters: {'kind': kind},
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      }),
      options: Options(contentType: 'multipart/form-data'),
    );
    return DrugItem.fromJson(response.data!);
  }
}
