import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

class FileService {
  final ApiService _apiService = ApiService();

  /// Upload profile image file using filepath
  Future<String?> uploadProfileImageFile(String filePath) async {
    try {
      // 1. Fayl nomini yo'ldan ajratib olamiz (server ko'pincha filename talab qiladi)
      final fileName = filePath.split('/').last;

      // 2. MultipartFile ni alohida o'zgaruvchida kutib olamiz
      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      // 3. FormData yaratamiz
      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await _apiService.dio.post(
        ApiConfig.fileUploadProfile,
        data: formData,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        if (kDebugMode) {
          print(response.data);
        }
        
        // 4. Serverdan kelgan javobni Map qilib tahlil qilamiz
        final data = response.data;
        if (data is Map<String, dynamic> && data['url'] != null) {
          return data['url'].toString(); // url manzilini qaytaramiz
        }
        
        return response.data.toString(); // ehtiyot chorasi
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FILE UPLOAD ERR]: ${e.message}');
        debugPrint('❌ [RESPONSE DATA]: ${e.response?.data}'); // Backend yuborgan xatoni ko'rish uchun
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FILE UPLOAD UNKNOWN ERR]: $e');
      }
    }
    return null;
  }

  /// Upload profile image file using raw bytes and filename
  Future<String?> uploadProfileImageBytes(Uint8List bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _apiService.dio.post(
        ApiConfig.fileUploadProfile,
        data: formData,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['url'] != null) {
          return data['url'].toString();
        }
        return response.data.toString();
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FILE UPLOAD BYTES ERR]: ${e.message}');
        debugPrint('❌ [FILE UPLOAD BYTES ERR TYPE]: ${e.type}');
        debugPrint('❌ [FILE UPLOAD BYTES ERR ERROR]: ${e.error}');
        debugPrint('❌ [FILE UPLOAD BYTES ERR RESPONSE]: ${e.response?.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FILE UPLOAD UNKNOWN ERR]: $e');
      }
    }
    return null;
  }
}
