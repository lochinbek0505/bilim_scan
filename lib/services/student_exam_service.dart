import 'dart:convert';
import 'package:bilim_scan/models/student_exam_start_model.dart';
import 'package:flutter/foundation.dart';
import '../models/student_exam_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class StudentExamService {
  final ApiService _apiService = ApiService();

  dynamic _parseResponseBody(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  /// GET /api/exams/student/{studentId}/guruh/{guruhId}
  Future<List<StudentAvailableExamDto>> getExams({
    String? studentId,
    String? guruhId,
  }) async {
    try {
      final sId = (studentId != null && studentId.trim().isNotEmpty)
          ? studentId.trim()
          : '6aa046d379b786309791f3a7';
      final gId = (guruhId != null && guruhId.trim().isNotEmpty)
          ? guruhId.trim()
          : '6aa0f1e7e21b3be71d3be9d3';

      final endpoint = '${ApiConfig.exams}/student/$sId/guruh/$gId';
      final response = await _apiService.dio.get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        final List<dynamic> list = parsed is List
            ? parsed
            : (parsed is Map && parsed['data'] is List ? parsed['data'] : []);
        return list.map((e) => StudentAvailableExamDto.fromJson(e)).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [STUDENT EXAM GET ERR]: $e');
    }
    return [];
  }

  /// POST /api/exams/{examSessionId}/start/{studentId}
  Future<StudentExamStartModel?> startExam(String examSessionId, String studentId) async {
    try {
      final response = await _apiService.dio.post(
        '${ApiConfig.exams}/$examSessionId/start/$studentId',
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        return StudentExamStartModel.fromJson(parsed);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ [STUDENT EXAM START ERR]: $e');
        debugPrint(stack.toString());
      }
    }
    return null;
  }

  /// POST /api/exams/student-exam/{studentExamId}/submit
  /// Body: { "answers": { "qId1": ["Ans1"], "qId2": ["AnsA", "AnsB"] } }
  Future<ExamResultResponse?> submitExam(String studentExamId, Map<String, List<String>> answers) async {

    try {
      final response = await _apiService.dio.post(
        '${ApiConfig.exams}/student-exam/$studentExamId/submit',
        data: {
          'answers': answers,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        return ExamResultResponse.fromJson(parsed);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [STUDENT EXAM SUBMIT ERR]: $e');
    }
    return null;
  }
}
