import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class ExamService {
  final ApiService _apiService = ApiService();

  /// GET /api/exams (Token bilan)
  Future<List<ExamModel>> getExams() async {
    try {
      final response = await _apiService.dio.get(ApiConfig.exams);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list.map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE GET ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE GET UNKNOWN ERR]: $e');
      }
    }
    return [];
  }

  /// POST /api/exams/create (Token bilan)
  /// Sends payload:
  /// {
  ///    "testId": "6aa2dc8219ef3807c41081be",
  ///    "guruhId": "6aa0f1e7e21b3be71d3be9d3",
  ///    "durationMinutes": 20,
  ///    "questionCount": 5,
  ///    "maxAttempts": 20
  /// }
  Future<ExamModel?> createExam(ExamModel exam) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.examCreate,
        data: exam.toCreateRequestJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return ExamModel.fromJson(response.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE CREATE ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE CREATE UNKNOWN ERR]: $e');
      }
    }
    return null;
  }

  /// PUT /api/exams/{id} (Token bilan)
  Future<bool> updateExam(ExamModel exam) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.exams}/${exam.id}',
        data: exam.toCreateRequestJson(),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE UPDATE ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE UPDATE UNKNOWN ERR]: $e');
      }
    }
    return false;
  }

  /// DELETE /api/exams/{id} (Token bilan)
  Future<bool> deleteExam(String id) async {
    try {
      final response = await _apiService.dio.delete('${ApiConfig.exams}/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE DELETE ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE DELETE UNKNOWN ERR]: $e');
      }
    }
    return false;
  }
}
