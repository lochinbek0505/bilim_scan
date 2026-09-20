import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/test_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class TestService {
  final ApiService _apiService = ApiService();

  /// GET /api/tests (Token bilan, ixtiyoriy fanId va kafedraId filtrlari bilan)
  Future<List<TestModel>> getTests({String? fanId, String? kafedraId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fanId != null && fanId.isNotEmpty) queryParams['fanId'] = fanId;
      if (kafedraId != null && kafedraId.isNotEmpty) queryParams['kafedraId'] = kafedraId;

      final response = await _apiService.dio.get(
        ApiConfig.tests,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

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

  /// GET /api/tests/{testId}/questions
  Future<List<QuestionModel>> getQuestionsByTestId(String testId) async {
    try {
      final response = await _apiService.dio.get('${ApiConfig.tests}/$testId/questions');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE GET QUESTIONS ERR]: ${e.message}');
      }
      return [];
    }
  }

  /// POST /api/tests (Token bilan)
  Future<TestModel?> createTest(TestModel test) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.tests,
        data: {
          "name": test.name,
          "fanId": test.fanId,
          "kafedraId": test.kafedraId,
          "eduPlanId": test.eduPlanId,
          "guruhId": test.guruhId,
          "oquvYili": test.oquvYili,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final created = TestModel.fromJson(response.data as Map<String, dynamic>);
        if (test.questions.isNotEmpty) {
           await uploadQuestionsBulk(created.id, test.questions);
        }
        return created.copyWith(questions: test.questions);
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE CREATE ERR]: ${e.message}');
      }
      return null;
    }
  }

  /// POST /api/tests/{testId}/questions/bulk
  Future<bool> uploadQuestionsBulk(String testId, List<QuestionModel> questions) async {
    final processedQuestions = questions.map((q) => q.withCalculatedMinimumTime()).toList();
    final payload = processedQuestions.map((q) => q.toJson()).toList();
    if (kDebugMode) {
      debugPrint('📤 [BULK UPLOAD QUESTIONS]: $payload');
    }
    try {
      final response = await _apiService.dio.post(
        '${ApiConfig.tests}/$testId/questions/bulk',
        data: payload,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE BULK UPLOAD ERR]: ${e.message}');
      }
      return false;
    }
  }

  /// PUT /api/tests/{id} (Token bilan)
  Future<bool> updateTest(TestModel test) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.tests}/${test.id}',
        data: {
          "name": test.name,
          "fanId": test.fanId,
          "kafedraId": test.kafedraId,
          "eduPlanId": test.eduPlanId,
          "guruhId": test.guruhId,
          "oquvYili": test.oquvYili,
        },
      );
      final isSuccess = response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204;
      if (isSuccess && test.questions.isNotEmpty) {
        await uploadQuestionsBulk(test.id, test.questions);
      }
      return isSuccess;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE UPDATE ERR]: ${e.message}');
        debugPrint('❌ [TEST SERVICE UPDATE ERR DATA]: ${e.response?.data}');
      }
      return false;
    }
  }

  /// DELETE /api/tests/{id} (Token bilan)
  Future<bool> deleteTest(String id) async {
    try {
      final response = await _apiService.dio.delete('${ApiConfig.tests}/$id');
      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [TEST SERVICE DELETE ERR]: ${e.message}');
        debugPrint('❌ [TEST SERVICE DELETE ERR DATA]: ${e.response?.data}');
      }
      return false;
    }
  }
}
