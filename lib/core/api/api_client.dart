import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session/session_controller.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';

/// Thin Dio wrapper ready for typed REST. No AI calls from the client.
class ApiClient {
  ApiClient({
    required String baseUrl,
    Dio? dio,
    String? Function()? accessToken,
    String? Function()? userId,
  }) : _accessToken = accessToken,
       _userId = userId,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 90),
               headers: const {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _accessToken?.call();
          final uid = _userId?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (uid != null && uid.isNotEmpty) {
            // Dev backends may still accept X-User-Id; production ignores it.
            options.headers['X-User-Id'] = uid;
          }
          return handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final String? Function()? _accessToken;
  final String? Function()? _userId;

  Dio get raw => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () =>
          _dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> put<T>(String path, {Object? data, Options? options}) {
    return _guard(() => _dio.put<T>(path, data: data, options: options));
  }

  Future<Response<T>> delete<T>(String path, {Object? data, Options? options}) {
    return _guard(() => _dio.delete<T>(path, data: data, options: options));
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppConfig.instance.apiBaseUrl,
    accessToken: () => ref.read(sessionProvider).accessToken,
    userId: () => ref.read(sessionProvider).email,
  );
});
