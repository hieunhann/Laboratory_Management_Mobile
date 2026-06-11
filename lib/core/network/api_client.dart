import 'dart:convert';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request interceptor: tự động gắn Bearer token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // 401 → xóa token, để app redirect về login
          if (error.response?.statusCode == 401) {
            await SecureStorageService.clearAll();
          }
          return handler.next(error);
        },
      ),
    );

    // Log interceptor (chỉ trong debug)
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ),
    );

    return dio;
  }

  // ─── Convenience Methods ─────────────────────────────────
  static Future<Response> get(String path, {Map<String, dynamic>? params}) {
    return instance.get(path, queryParameters: params);
  }

  static Future<Response> post(String path, {dynamic data}) {
    return instance.post(path, data: data);
  }

  static Future<Response> put(String path, {dynamic data}) {
    return instance.put(path, data: data);
  }

  static Future<Response> patch(String path, {dynamic data}) {
    return instance.patch(path, data: data);
  }

  static Future<Response> delete(String path, {dynamic data}) {
    return instance.delete(path, data: data);
  }

  // ─── Public API (không cần auth) ─────────────────────────
  static Dio get publicInstance {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return dio;
  }
}
