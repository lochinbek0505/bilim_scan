import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio dio;
  String? _authToken;
  VoidCallback? onUnauthorized;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Dio Interceptor for Auth, 401/403 Handling & Logging
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final isLoginEndpoint = options.path.contains(ApiConfig.login);

          // Attach Bearer token to all non-login requests
          if (!isLoginEndpoint &&
              _authToken != null &&
              _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          if (kDebugMode) {
            debugPrint(
              '🌐 [API REQ] ${options.method} -> ${options.baseUrl}${options.path}',
            );
            if (options.headers.containsKey('Authorization')) {
              debugPrint('🔑 [API AUTH] Token attached');
            } else {
              debugPrint('🔓 [API PUBLIC] Tokensiz so\'rov');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '✅ [API RESP] ${response.statusCode} <- ${response.requestOptions.path}',
            );
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;

          if (kDebugMode) {
            debugPrint(
              '❌ [API ERR] ${statusCode ?? 'NET_ERR'} <- ${error.requestOptions.path}',
            );
            debugPrint('❌ [API ERR MSG]: ${error.message}');
            debugPrint('❌ [API ERR TYPE]: ${error.type}');
            debugPrint('❌ [API ERR ERROR_OBJ]: ${error.error}');
          }

          // 401 (Unauthorized) OR 403 (Forbidden) -> Perform automatic logout
          if (statusCode == 401 || statusCode == 403) {
            if (kDebugMode) {
              debugPrint(
                '🚨 [AUTH LOGOUT] HTTP $statusCode xatoligi keldi! Token yaroqsiz yoki ruxsat yo\'q. Avtomatik logout bajarilmoqda...',
              );
            }

            // Clear local storage and stored auth token
            await StorageService().clearStorage();

            // Trigger onUnauthorized callback
            onUnauthorized?.call();
          }

          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String newBaseUrl) {
    dio.options.baseUrl = newBaseUrl;
    if (kDebugMode) {
      debugPrint('🔄 [API SERVICE] Dio BaseUrl yangilandi: $newBaseUrl');
    }
  }

  // Token Store Methods
  void setAuthToken(String token) {
    _authToken = token;
    if (kDebugMode) {
      debugPrint('🔑 [API SERVICE] Yangi auth token saqlandi');
    }
  }

  void clearAuthToken() {
    _authToken = null;
    if (kDebugMode) {
      debugPrint('🔒 [API SERVICE] Token tozalandi');
    }
  }

  String? get authToken => _authToken;
}
