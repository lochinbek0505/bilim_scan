import 'package:flutter/material.dart';
import '../models/catalog_response.dart';
import '../models/fan_model.dart';
import '../models/guruh_model.dart';
import '../models/user_create_dto.dart';
import '../models/user_response_dto.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service = UserService();

  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedRoleFilter; // null (All), USER, TEACHER, ADMIN

  List<UserResponseDto> _users = [];

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedRoleFilter => _selectedRoleFilter;

  List<UserResponseDto> get users {
    return _users.where((u) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          (u.username ?? '').toLowerCase().contains(query) ||
          u.fullName.toLowerCase().contains(query);

      final matchesRole = _selectedRoleFilter == null || u.role == _selectedRoleFilter;

      return matchesSearch && matchesRole;
    }).toList();
  }

  UserProvider() {
    _loadInitialSampleData();
    fetchUsers();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRoleFilter(String? role) {
    _selectedRoleFilter = role;
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.getAllUsers();
    if (result.isNotEmpty) {
      _users = result;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createUser(UserCreateDto dto) async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.createUser(dto);

    if (result != null) {
      _users.add(result);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateUser(String id, UserCreateDto dto) async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.updateUser(id, dto);

    final idx = _users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      if (result != null) {
        _users[idx] = result;
      } else {
        _users[idx] = UserResponseDto(
          id: id,
          username: dto.username ?? _users[idx].username,
          role: dto.role ?? _users[idx].role,
          firstName: dto.firstName ?? _users[idx].firstName,
          lastName: dto.lastName ?? _users[idx].lastName,
          patronymic: dto.patronymic ?? _users[idx].patronymic,
          profileImageUrl: dto.profileImageUrl ?? _users[idx].profileImageUrl,
          bosqich: dto.bosqichId != null ? CatalogResponse(id: dto.bosqichId, name: '1-Kurs') : _users[idx].bosqich,
          guruh: dto.guruhId != null ? GuruhModel(id: dto.guruhId, name: '10-25-guruh') : _users[idx].guruh,
          kafedra: dto.kafedraId != null ? CatalogResponse(id: dto.kafedraId, name: 'Kafedra') : _users[idx].kafedra,
          fan: dto.fanId != null ? FanModel(id: dto.fanId, name: 'Fan') : _users[idx].fan,
        );
      }
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    notifyListeners();
    final result = await _service.deleteUser(id);
    if (result) {
      _users.removeWhere((u) => u.id == id);
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  void _loadInitialSampleData() {
    _users = [
      UserResponseDto(
        id: 'usr_001',
        username: 'student_1025',
        role: 'USER',
        firstName: 'Daler',
        lastName: 'Narzullaev',
        patronymic: 'Baxrullaevich',
        bosqich: CatalogResponse(id: '6aa0f1d0e21b3be71d3be101', name: '1-Kurs bosqichi'),
        guruh: GuruhModel(id: '6aa0f1e7e21b3be71d3be9d3', name: '10-25-guruh'),
      ),
      UserResponseDto(
        id: 'usr_002',
        username: 'teacher_sharof',
        role: 'TEACHER',
        firstName: 'Sharof',
        lastName: 'Mamasarulov',
        patronymic: '',
        kafedra: CatalogResponse(id: '6aa0f20fe21b3be71d3be9d5', name: 'Informatika va AT kafedrasi'),
        fan: FanModel(id: '6aa0f1d0e21b3be71d3be9d2', name: 'Informatika va AT'),
      ),
      UserResponseDto(
        id: 'usr_003',
        username: 'admin_master',
        role: 'ADMIN',
        firstName: 'Tizim',
        lastName: 'Administratori',
        patronymic: '',
      ),
    ];
  }
}
