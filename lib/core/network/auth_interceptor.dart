import 'package:dio/dio.dart';

import '../auth/auth_refresh.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;

  static bool _isAuthEndpoint(String path) {
    final prefix = AppConfig.apiPrefix;
    return path.contains('$prefix/auth/login') ||
        path.contains('$prefix/auth/refresh') ||
        path.contains('$prefix/auth/forgot-password') ||
        path.contains('$prefix/auth/reset-password');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final header = AuthService.authorizationHeader;
    if (header != null &&
        !options.headers.containsKey('Authorization') &&
        !_isAuthEndpoint(options.path)) {
      options.headers['Authorization'] = header;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['auth_retried'] == true;

    if (status != 401 ||
        alreadyRetried ||
        _isAuthEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final tokens = await AuthRefresh.refreshIfNeeded();
    if (tokens == null) {
      handler.next(err);
      return;
    }

    try {
      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      request.extra['auth_retried'] = true;
      final response = await _dio.fetch(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
