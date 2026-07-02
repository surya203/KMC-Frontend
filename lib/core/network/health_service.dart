import 'api_client.dart';

class HealthService {
  HealthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<bool> checkHealth() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/health');
      return response.statusCode == 200 &&
          response.data?['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }
}
