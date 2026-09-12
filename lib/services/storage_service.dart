import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_model.dart';
import 'api_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  StorageService._internal();

  static const String _keyToken = 'auth_token';
  static const String _keyLoginData = 'login_data';

  /// App start initialization - restores token into ApiService
  Future<void> initStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      if (token != null && token.isNotEmpty) {
        ApiService().setAuthToken(token);
        if (kDebugMode) {
          debugPrint('🔑 [STORAGE] Saqlangan token ApiService ga yuklandi.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [STORAGE INIT ERR]: $e');
      }
    }
  }

  /// Save full LoginModel and token to secure local storage
  Future<void> saveLoginData(LoginModel loginModel) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = loginModel.token;
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_keyToken, token);
        ApiService().setAuthToken(token);
      }

      final jsonStr = jsonEncode(loginModel.toJson());
      await prefs.setString(_keyLoginData, jsonStr);

      if (kDebugMode) {
        debugPrint('💾 [STORAGE] LoginModel va Token muvaffaqiyatli saqlandi!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [STORAGE SAVE ERR]: $e');
      }
    }
  }

  /// Retrieve stored LoginModel
  Future<LoginModel?> getLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyLoginData);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return LoginModel.fromJson(map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [STORAGE GET LOGIN DATA ERR]: $e');
      }
    }
    return null;
  }

  /// Retrieve stored Token
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      return null;
    }
  }

  /// Clear all stored login data on logout
  Future<void> clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyLoginData);
      ApiService().clearAuthToken();
      if (kDebugMode) {
        debugPrint('🧹 [STORAGE] Saqlangan login ma\'lumotlari va token tozalandi.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [STORAGE CLEAR ERR]: $e');
      }
    }
  }
}
