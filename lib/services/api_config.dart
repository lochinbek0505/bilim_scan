import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  // Dynamic Base API URL based on Platform
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:4257/api';
    }
    return 'http://127.0.0.1:4257/api';
  }

  // Endpoints
  static const String login = '/auth/login';
  static const String bosqichlar = '/admin/bosqichlar';
  static const String fanlar = '/admin/fanlar';
  static const String guruhlar = '/admin/guruhlar';
  static const String kafedralar = '/admin/kafedralar';

  static const String tests = '/tests';
  static const String eduPlans = '/edu-plans';
  static const String exams = '/exams';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);
}
