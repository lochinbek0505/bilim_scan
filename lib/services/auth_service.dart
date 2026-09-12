import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/login_model.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Login request to http://localhost:4257/api/auth/login (TOKENSIZ SO'ROV)
  Future<LoginModel?> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.login,
        data: {'username': login, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        LoginModel loginModel = LoginModel.fromJson(data);

        // Save LoginModel and token to local storage
        await _storageService.saveLoginData(loginModel);

        return loginModel;
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Lokal server bilan bog\'lanishda xatolik yuz berdi (${e.message})';

      if (kDebugMode) {
        debugPrint('❌ [AUTH LOGIN ERR]: $errorMessage');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AUTH UNKNOWN ERR]: $e');
      }
      return null;
    }
    return null;
  }

  Future<void> logout() async {
    await _storageService.clearStorage();
  }
}
