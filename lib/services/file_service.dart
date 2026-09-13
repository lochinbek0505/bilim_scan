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
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.dio.post(
        ApiConfig.fileUploadProfile,
        data: formData,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        // Return relative path string e.g. /uploads/profiles/...
        return response.data.toString();
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FILE UPLOAD ERR]: ${e.message}');
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
        return response.data.toString();
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FILE UPLOAD BYTES ERR]: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FILE UPLOAD UNKNOWN ERR]: $e');
      }
    }
    return null;
  }
}
