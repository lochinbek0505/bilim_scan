import 'package:flutter/material.dart';
import '../main.dart';
import '../models/login_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum UserRole { user, teacher, admin }

extension UserRoleExtension on UserRole {
  String get title {
    switch (this) {
      case UserRole.user:
        return 'O\'quvchi / Kursant';
      case UserRole.teacher:
        return 'O\'qituvchi / Nazoratchi';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get code {
    switch (this) {
      case UserRole.user:
        return 'STUDENT_ROLE';
      case UserRole.teacher:
        return 'TEACHER_ROLE';
      case UserRole.admin:
        return 'SYS_ADMIN';
    }
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  LoginModel? _currentUserModel;
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;
  String _statusLog = '';
  String _selectedGroup = '10-25-guruh o\'quvchilari';

  final TextEditingController loginController = TextEditingController(text: 'student_1025');
  final TextEditingController passwordController = TextEditingController(text: '••••••••');

  LoginModel? get currentUserModel => _currentUserModel;
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

  AuthProvider() {
    // Register auto-logout on 401/403 HTTP response
    ApiService().onUnauthorized = () {
      _currentUserModel = null;
      notifyListeners();
      navigateToLogin();
    };
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    await _storageService.initStorage();
    final savedData = await _storageService.getLoginData();
    if (savedData != null) {
      _currentUserModel = savedData;
      if (savedData.user?.username != null) {
        loginController.text = savedData.user!.username!;
      }
      notifyListeners();
    }
  }

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
    _statusLog = 'http://127.0.0.1:4257/api/auth/login so\'rovi yuborilmoqda...';
    notifyListeners();

    // Call API Service
    final result = await _authService.login(
      login: loginText,
      password: passwordText,
    );

    if (result != null) {
      _currentUserModel = result;
      _statusLog = 'Muvaffaqiyatli! Token va LoginModel saqlandi.';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      // Create fallback demo LoginModel for local test if server connection fails
      final fallbackModel = LoginModel(
        token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
        user: User(
          id: 'user_1025',
          username: loginText,
          role: _selectedRole.code,
          guruh: _selectedGroup,
        ),
      );

      _currentUserModel = fallbackModel;
      await _storageService.saveLoginData(fallbackModel);

      _statusLog = 'Lokal test: Token va LoginModel saqlandi!';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUserModel = null;
    notifyListeners();
    navigateToLogin();
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
