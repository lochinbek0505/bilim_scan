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
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE GET ERR]: ${e.message}');
      }
      return [];
    }
  }

  /// POST /api/exams (Token bilan)
  /// Sends payload: {"testId": "...", "guruhId": "...", "durationMinutes": 20, "questionCount": 5, "maxAttempts": 20}
  Future<ExamModel?> createExam(ExamModel exam) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.exams,
        data: exam.toApiRequestJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ExamModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE CREATE ERR]: ${e.message}');
      }
      return null;
    }
  }

  /// PUT /api/exams/{id} (Token bilan)
  Future<bool> updateExam(ExamModel exam) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.exams}/${exam.id}',
        data: exam.toApiRequestJson(),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EXAM SERVICE UPDATE ERR]: ${e.message}');
      }
      return false;
    }
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
      return false;
    }
  }
}
