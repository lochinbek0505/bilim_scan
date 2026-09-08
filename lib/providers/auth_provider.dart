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

  final TextEditingController serviceIdController = TextEditingController(text: '10-25-0842');
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
    final serviceId = serviceIdController.text.trim();
    final password = passwordController.text.trim();

    if (serviceId.isEmpty) {
      _errorMessage = 'O\'quvchi ID / Guvohnoma raqamini kiriting!';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Parolingizni kiriting!';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _isLoading = true;
    _statusLog = 'Lokal server bilan aloqa o\'rnatilmoqda...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));
    _statusLog = 'O\'quvchi ma\'lumotlari va bilim darajasi tekshirilmoqda...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    _statusLog = 'BilimScan tizimiga xush kelibsiz!';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
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
    serviceIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
