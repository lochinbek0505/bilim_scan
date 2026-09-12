import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/test_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class TestService {
  final ApiService _apiService = ApiService();

  /// GET /api/tests (Token bilan)
  Future<List<TestModel>> getTests() async {
    try {
      final response = await _apiService.dio.get(ApiConfig.tests);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list.map((e) => TestModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE GET ERR]: ${e.message}');
      }
      return [];
    }
  }

  /// POST /api/tests (Token bilan)
  Future<TestModel?> createTest(TestModel test) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.tests,
        data: test.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TestModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE CREATE ERR]: ${e.message}');
      }
      return null;
    }
  }

  /// PUT /api/tests/{id} (Token bilan)
  Future<bool> updateTest(TestModel test) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.tests}/${test.id}',
        data: test.toJson(),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE UPDATE ERR]: ${e.message}');
      }
      return false;
    }
  }

  /// DELETE /api/tests/{id} (Token bilan)
  Future<bool> deleteTest(String id) async {
    try {
      final response = await _apiService.dio.delete('${ApiConfig.tests}/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE DELETE ERR]: ${e.message}');
      }
      return false;
    }
  }
}
