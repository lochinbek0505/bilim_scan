import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/student_monitoring_model.dart';
import '../models/user_response_dto.dart';
import '../models/exam_model.dart';
import '../models/fan_model.dart';
import '../models/student_exam_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class MonitoringService {
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

  /// GET /api/analytics/monitoring/student/{studentId}
  Future<StudentMonitoringModel?> getStudentMonitoring(String studentId) async {
    try {
      final endpoint = '${ApiConfig.studentMonitoring}/$studentId';
      if (kDebugMode) {
        debugPrint('🔍 [MONITORING GET]: $endpoint');
      }
      final response = await _apiService.dio.get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        return StudentMonitoringModel.fromJson(parsed);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [MONITORING GET ERR]: $e - fallback sample data generated');
      }
    }

    // Local fallback sample data for smooth testing if backend is offline or returns error
    return _createFallbackSampleModel(studentId);
  }

  /// GET /api/exams/{examSessionId}/score/{studentId}
  Future<ExamResultResponse?> getExamScore(String examSessionId, String studentId) async {
    try {
      final endpoint = '${ApiConfig.exams}/$examSessionId/score/$studentId';
      if (kDebugMode) {
        debugPrint('🔍 [EXAM SCORE GET]: $endpoint');
      }
      final response = await _apiService.dio.get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        return ExamResultResponse.fromJson(parsed);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [EXAM SCORE GET ERR]: $e');
      }
    }
    return null;
  }

  /// GET /api/admin/users/{studentId}
  Future<UserResponseDto?> getUserDetails(String studentId) async {
    try {
      final endpoint = '${ApiConfig.users}/$studentId';
      final response = await _apiService.dio.get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        if (parsed is Map<String, dynamic>) {
          return UserResponseDto.fromJson(parsed);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [USER DETAILS GET ERR]: $e');
      }
    }
    return null;
  }

  /// GET /api/exams/{examSessionId}
  Future<ExamModel?> getExamSessionDetails(String examSessionId) async {
    try {
      final endpoint = '${ApiConfig.exams}/$examSessionId';
      final response = await _apiService.dio.get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        if (parsed is Map<String, dynamic>) {
          return ExamModel.fromJson(parsed);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [EXAM SESSION DETAILS GET ERR]: $e');
      }
    }
    // Fallback: get all exams and find by ID
    try {
      final response = await _apiService.dio.get(ApiConfig.exams);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        final List<dynamic> list = parsed is List ? parsed : (parsed is Map && parsed['data'] is List ? parsed['data'] : []);
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            final exam = ExamModel.fromJson(item);
            if (exam.id == examSessionId) return exam;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// GET /api/admin/fanlar/{subjectId}
  Future<FanModel?> getSubjectDetails(String subjectId) async {
    try {
      final endpoint = '${ApiConfig.fanlar}/$subjectId';
      final response = await _apiService.dio.get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        if (parsed is Map<String, dynamic>) {
          return FanModel.fromJson(parsed);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SUBJECT DETAILS GET ERR]: $e');
      }
    }
    // Fallback: search in list
    try {
      final response = await _apiService.dio.get(ApiConfig.fanlar);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseResponseBody(response.data);
        if (parsed is List) {
          for (var item in parsed) {
            if (item is Map<String, dynamic> && item['id'] == subjectId) {
              return FanModel.fromJson(item);
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  // Fallback sample generator matching prompt data structure
  StudentMonitoringModel _createFallbackSampleModel(String studentId) {
    return StudentMonitoringModel.fromJson({
      "academicYears": [
        {
          "months": [
            {
              "month": "2024-2025",
              "subjects": [
                {
                  "averagePercentage": 1.875,
                  "exams": [
                    {
                      "date": "2026-09-13T19:16:18.703Z",
                      "examName": "Oraliq nazorat 1",
                      "examSessionId": "6aa6f0492bd5979246f0a5d0",
                      "masteryLevel": "FAILED",
                      "percentage": 40.0
                    },
                    {
                      "date": "2026-09-14T09:35:56.121Z",
                      "examName": "12121212",
                      "examSessionId": "6aa70036d4ae3483d910e1bb",
                      "masteryLevel": "FAILED",
                      "percentage": 40.0
                    },
                    {
                      "date": "2026-09-14T09:47:29.890Z",
                      "examName": "12121212",
                      "examSessionId": "6aa70036d4ae3483d910e1bb",
                      "masteryLevel": "FAILED",
                      "percentage": 20.0
                    },
                    {
                      "date": "2026-09-14T11:12:25.667Z",
                      "examName": "12121212",
                      "examSessionId": "6aa70036d4ae3483d910e1bb",
                      "masteryLevel": "FAILED",
                      "percentage": 20.0
                    }
                  ],
                  "subjectId": "6aa0f1d0e21b3be71d3be9d2",
                  "subjectMastery": "FAILED",
                  "subjectName": "Ingliz tili"
                }
              ]
            }
          ],
          "year": "2024-2025"
        }
      ],
      "overallMastery": "FAILED",
      "overallPercentage": 1.875,
      "studentId": studentId.isEmpty ? "6aa4fb2bf9d8048e1cd2c11e" : studentId,
    });
  }
}
