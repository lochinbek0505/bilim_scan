import 'package:flutter/foundation.dart';
import '../models/user_create_dto.dart';
import '../models/user_response_dto.dart';
import 'api_config.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  /// GET /api/admin/users
  Future<List<UserResponseDto>> getAllUsers() async {
    try {
      final response = await _apiService.dio.get(ApiConfig.users);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list
            .map((e) => UserResponseDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [USER SERVICE GET ALL ERR]: $e');
      }
    }
    return [];
  }

  /// GET /api/admin/users/{id}
  Future<UserResponseDto?> getUserById(String id) async {
    try {
      final response = await _apiService.dio.get('${ApiConfig.users}/$id');
      if (response.statusCode == 200 && response.data != null) {
        return UserResponseDto.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [USER SERVICE GET BY ID ERR]: $e');
      }
    }
    return null;
  }

  /// POST /api/admin/users
  Future<UserResponseDto?> createUser(UserCreateDto dto) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.users,
        data: dto.toJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return UserResponseDto.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [USER SERVICE CREATE ERR]: $e');
      }
    }
    return null;
  }

  /// PUT /api/admin/users/{id}
  Future<UserResponseDto?> updateUser(String id, UserCreateDto dto) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.users}/$id',
        data: dto.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        return UserResponseDto.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [USER SERVICE UPDATE ERR]: $e');
      }
    }
    return null;
  }

  /// DELETE /api/admin/users/{id}
  Future<bool> deleteUser(String id) async {
    try {
      final response = await _apiService.dio.delete('${ApiConfig.users}/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [USER SERVICE DELETE ERR]: $e');
      }
    }
    return false;
  }
}
