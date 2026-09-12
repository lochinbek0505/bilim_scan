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
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE GET ERR]: ${e.message}');
      }
      return [];
    }
  }

  /// POST /api/edu-plans (Token bilan)
  Future<EduPlanModel?> createEduPlan(EduPlanModel plan) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.eduPlans,
        data: plan.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return EduPlanModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE CREATE ERR]: ${e.message}');
      }
      return null;
    }
  }

  /// PUT /api/edu-plans/{id} (Token bilan)
  Future<bool> updateEduPlan(EduPlanModel plan) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.eduPlans}/${plan.id}',
        data: plan.toJson(),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EDU PLAN SERVICE UPDATE ERR]: ${e.message}');
      }
      return false;
    }
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
      return false;
    }
  }
}
