import 'package:flutter/material.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/login/student_login_screen.dart';
import '../../screens/student/student_dashboard_screen.dart';

enum AppType { student, admin }

/// BUILD TURI — faqat shu qatorni o'zgartiring:
///   AppType.student → kursant (o'quvchi) ilovasi
///   AppType.admin   → admin / o'qituvchi ilovasi
const AppType appType = AppType.student;

class AppConfig {
  static bool get isStudent => appType == AppType.student;
  static bool get isAdmin => appType == AppType.admin;

  /// Login sahifasi (splash va logout/401 dan keyin ochiladi)
  static Widget loginScreen() =>
      isStudent ? const StudentLoginScreen() : const LoginScreen();

  /// Token mavjud bo'lsa splash dan keyin ochiladigan asosiy sahifa
  static Widget homeScreen() =>
      isStudent ? const StudentDashboardScreen() : const HomeScreen();
}
