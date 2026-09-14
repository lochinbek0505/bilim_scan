import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/edu_plan_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class EduPlanService {
  final ApiService _apiService = ApiService();

  /// GET /api/edu-plans (Token bilan)
  Future<List<EduPlanModel>> getEduPlans() async {
    try {
      final response = await _apiService.dio.get(ApiConfig.eduPlans);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list.map((e) => EduPlanModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE GET ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE GET UNKNOWN ERR]: $e');
      }
    }
    return [];
  }

  /// POST /api/edu-plans (EduPlanRequestDto: {"name": "...", "fanId": "...", "kafedraId": "...", "oquvYili": "..."})
  /// THEN POST /api/edu-plans/{planId}/topics/bulk
  Future<EduPlanModel?> createEduPlan(EduPlanModel plan) async {
    try {
      // Step 1: Create EduPlan
      final response = await _apiService.dio.post(
        ApiConfig.eduPlans,
        data: plan.toRequestDtoJson(),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final createdPlan = EduPlanModel.fromJson(response.data as Map<String, dynamic>);
        final planId = createdPlan.id;

        // Step 2: Bulk upload topics if topics list is not empty
        if (plan.topics.isNotEmpty && planId.isNotEmpty) {
          await uploadTopicsBulk(planId, plan.topics);
        }

        return createdPlan.copyWith(topics: plan.topics);
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE CREATE ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE CREATE UNKNOWN ERR]: $e');
      }
    }
    return null;
  }

  /// POST /api/edu-plans/{planId}/topics/bulk
  /// Body: [ { "t/r": 1, "name": "Kirish", "soat": 2, "type": "Nazariy" }, ... ]
  Future<bool> uploadTopicsBulk(String planId, List<EduPlanTopicModel> topics) async {
    try {
      final topicsPayload = topics.map((t) => t.toBulkRequestJson()).toList();

      final response = await _apiService.dio.post(
        '${ApiConfig.eduPlans}/$planId/topics/bulk',
        data: topicsPayload,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE BULK TOPICS ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE BULK TOPICS UNKNOWN ERR]: $e');
      }
    }
    return false;
  }

  /// PUT /api/edu-plans/{id} (Token bilan)
  Future<bool> updateEduPlan(EduPlanModel plan) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.eduPlans}/${plan.id}',
        data: plan.toRequestDtoJson(),
      );
      if (response.statusCode == 200 && plan.topics.isNotEmpty) {
        await uploadTopicsBulk(plan.id, plan.topics);
      }
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE UPDATE ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE UPDATE UNKNOWN ERR]: $e');
      }
    }
    return false;
  }

  /// DELETE /api/edu-plans/{id} (Token bilan)
  Future<bool> deleteEduPlan(String id) async {
    try {
      final response = await _apiService.dio.delete('${ApiConfig.eduPlans}/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE DELETE ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE DELETE UNKNOWN ERR]: $e');
      }
    }
    return false;
  }
}
