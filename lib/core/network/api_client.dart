import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../auth/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._({
    TokenStorage? tokenStorage,
    Dio? dio,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          final path = error.requestOptions.path;
          if (path.contains('/auth/login') ||
              path.contains('/auth/refresh') ||
              _refreshing) {
            handler.next(error);
            return;
          }

          try {
            final refreshed = await _tryRefreshToken();
            if (!refreshed) {
              handler.next(error);
              return;
            }

            final token = await _tokenStorage.getAccessToken();
            final request = error.requestOptions;
            request.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(request);
            handler.resolve(response);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  final TokenStorage _tokenStorage;
  final Dio _dio;
  bool _refreshing = false;

  Dio get dio => _dio;

  TokenStorage get tokenStorage => _tokenStorage;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData data,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '${AppConfig.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        await _tokenStorage.saveTokens(
          accessToken: '${data['access_token']}',
          refreshToken: '${data['refresh_token']}',
        );
        return true;
      }
    } catch (_) {
      await _tokenStorage.clear();
    } finally {
      _refreshing = false;
    }
    return false;
  }

  static ApiException wrapError(Object error) {
    if (error is DioException) {
      return ApiException.fromDio(error);
    }
    return ApiException('$error');
  }
}
