import 'package:flutter/material.dart';

enum UserRole { kursant, oqituvchi, admin }

extension UserRoleExtension on UserRole {
  String get title {
    switch (this) {
      case UserRole.kursant:
        return 'O\'quvchi / Kursant';
      case UserRole.oqituvchi:
        return 'O\'qituvchi / Nazoratchi';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get code {
    switch (this) {
      case UserRole.kursant:
        return 'STUDENT_ROLE';
      case UserRole.oqituvchi:
        return 'TEACHER_ROLE';
      case UserRole.admin:
        return 'SYS_ADMIN';
    }
  }
}

class AuthProvider extends ChangeNotifier {
  UserRole _selectedRole = UserRole.kursant;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;
  String _statusLog = '';
  String _selectedGroup = '10-25-guruh o\'quvchilari';

  final TextEditingController loginController = TextEditingController(text: 'student_1025');
  final TextEditingController passwordController = TextEditingController(text: '••••••••');

  UserRole get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;
  String get statusLog => _statusLog;
  String get selectedGroup => _selectedGroup;

  final List<String> availableGroups = [
    '10-25-guruh o\'quvchilari',
    '1-O\'quv guruhi',
    '2-O\'quv guruhi',
    '3-O\'quv guruhi',
    'Informatika va AT kafedrasi',
  ];

  void setRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setGroup(String group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleRememberMe(bool? value) {
    _rememberMe = value ?? false;
    notifyListeners();
  }

  Future<bool> login() async {
    final loginText = loginController.text.trim();
    final passwordText = passwordController.text.trim();

    if (loginText.isEmpty) {
      _errorMessage = 'Login (foydalanuvchi nomi)ni kiriting!';
      notifyListeners();
      return false;
    }

    if (passwordText.isEmpty) {
      _errorMessage = 'Parolni kiriting!';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _isLoading = true;
    _statusLog = 'Lokal server bilan bog\'lanilmoqda...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));
    _statusLog = 'Login va parol tasdiqlanmoqda...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    _statusLog = 'Muvaffaqiyatli! BilimScan tizimiga xush kelibsiz!';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));
    _isLoading = false;
    notifyListeners();

    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
