import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String? _discoveredHost;

  static void setDiscoveredHost(String host) {
    _discoveredHost = host;
    if (kDebugMode) {
      debugPrint('📡 [API CONFIG] Dinamik server IP saqlandi: $host ($hostUrl)');
    }
  }

  static String? get discoveredHost => _discoveredHost;

  // Host Server Base URL (without /api suffix)
  static String get hostUrl {
    if (_discoveredHost != null && _discoveredHost!.isNotEmpty) {
      return 'http://$_discoveredHost:4257';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:4257';
    }
    return 'http://127.0.0.1:4257';
  }

  // Dynamic API Base URL
  static String get baseUrl => '$hostUrl/api';

  // File Server Helper
  static String getFileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final formattedPath = path.startsWith('/') ? path : '/$path';
    return '$hostUrl$formattedPath';
  }

  // Endpoints
  static const String login = '/auth/login';
  static const String users = '/admin/users';
  static const String bosqichlar = '/admin/bosqichlar';
  static const String fanlar = '/admin/fanlar';
  static const String guruhlar = '/admin/guruhlar';
  static const String kafedralar = '/admin/kafedralar';
  static const String fileUploadProfile = '/files/upload-profile';
  static const String adminExam = '/exams/admin/all';
  static const String tests = '/tests';
  static const String eduPlans = '/edu-plans';
  static const String exams = '/exams';
  static const String examCreate = '/exams/create';
  static const String studentMonitoring = '/analytics/monitoring/student';
  static const String statisticsLyceum = '/analytics/statistics/lyceum';
  static const String statisticsGroup = '/analytics/statistics/group';
  static const String statisticsStage = '/analytics/statistics/stage';
  static const String statisticsSubject = '/analytics/statistics/subject';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
