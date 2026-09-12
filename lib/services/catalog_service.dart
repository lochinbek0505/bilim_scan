import 'package:flutter/foundation.dart';
import '../models/catalog_request_model.dart';
import '../models/catalog_response.dart';
import '../models/fan_model.dart';
import '../models/guruh_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class CatalogService {
  final ApiService _apiService = ApiService();

  // Helper method for CatalogResponse list
  Future<List<CatalogResponse>> _getCatalogs(String endpoint) async {
    try {
      final response = await _apiService.dio.get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list
            .map((e) => CatalogResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CATALOG GET ERR] $endpoint: $e');
      }
    }
    return [];
  }

  // Helper method for CatalogResponse POST
  Future<CatalogResponse?> _createCatalog(String endpoint, CatalogRequestModel model) async {
    try {
      final response = await _apiService.dio.post(
        endpoint,
        data: model.toJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return CatalogResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CATALOG CREATE ERR] $endpoint: $e');
      }
    }
    return null;
  }

  // Helper method for CatalogResponse PUT
  Future<CatalogResponse?> _updateCatalog(String endpoint, String id, CatalogRequestModel model) async {
    try {
      final response = await _apiService.dio.put(
        '$endpoint/$id',
        data: model.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        return CatalogResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CATALOG UPDATE ERR] $endpoint/$id: $e');
      }
    }
    return null;
  }

  // Helper method for DELETE
  Future<bool> _deleteCatalog(String endpoint, String id) async {
    try {
      final response = await _apiService.dio.delete('$endpoint/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CATALOG DELETE ERR] $endpoint/$id: $e');
      }
    }
    return false;
  }

  // --- BOSQICHLAR (Course Levels) ---
  Future<List<CatalogResponse>> getBosqichlar() => _getCatalogs(ApiConfig.bosqichlar);
  Future<CatalogResponse?> createBosqich(CatalogRequestModel model) => _createCatalog(ApiConfig.bosqichlar, model);
  Future<CatalogResponse?> updateBosqich(CatalogRequestModel model, String id) => _updateCatalog(ApiConfig.bosqichlar, id, model);
  Future<bool> deleteBosqich(String id) => _deleteCatalog(ApiConfig.bosqichlar, id);

  // --- KAFEDRALAR (Departments) ---
  Future<List<CatalogResponse>> getKafedralar() => _getCatalogs(ApiConfig.kafedralar);
  Future<CatalogResponse?> createKafedra(CatalogRequestModel model) => _createCatalog(ApiConfig.kafedralar, model);
  Future<CatalogResponse?> updateKafedra(CatalogRequestModel model, String id) => _updateCatalog(ApiConfig.kafedralar, id, model);
  Future<bool> deleteKafedra(String id) => _deleteCatalog(ApiConfig.kafedralar, id);

  // --- GURUHLAR (Groups with Bosqich - Request: {"name": "...", "bosqichId": "..."}) ---
  Future<List<GuruhModel>> getGuruhlar() async {
    try {
      final response = await _apiService.dio.get(ApiConfig.guruhlar);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list
            .map((e) => GuruhModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GURUHLAR GET ERR]: $e');
      }
    }
    return [];
  }

  Future<GuruhModel?> createGuruh(GuruhRequestModel model) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.guruhlar,
        data: model.toJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return GuruhModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GURUH CREATE ERR]: $e');
      }
    }
    return null;
  }

  Future<GuruhModel?> updateGuruh(GuruhRequestModel model, String id) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.guruhlar}/$id',
        data: model.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        return GuruhModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GURUH UPDATE ERR]: $e');
      }
    }
    return null;
  }

  Future<bool> deleteGuruh(String id) => _deleteCatalog(ApiConfig.guruhlar, id);

  // --- FANLAR (Subjects with Kafedra - Request: {"name": "...", "kafedraId": "..."}) ---
  Future<List<FanModel>> getFanlar() async {
    try {
      final response = await _apiService.dio.get(ApiConfig.fanlar);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list
            .map((e) => FanModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FANLAR GET ERR]: $e');
      }
    }
    return [];
  }

  Future<FanModel?> createFan(FanRequestModel model) async {
    try {
      final response = await _apiService.dio.post(
        ApiConfig.fanlar,
        data: model.toJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return FanModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FAN CREATE ERR]: $e');
      }
    }
    return null;
  }

  Future<FanModel?> updateFan(FanRequestModel model, String id) async {
    try {
      final response = await _apiService.dio.put(
        '${ApiConfig.fanlar}/$id',
        data: model.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        return FanModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FAN UPDATE ERR]: $e');
      }
    }
    return null;
  }

  Future<bool> deleteFan(String id) => _deleteCatalog(ApiConfig.fanlar, id);
}
