import 'package:flutter/material.dart';
import '../models/catalog_response.dart';
import '../models/fan_model.dart';
import '../models/guruh_model.dart';
import '../models/user_create_dto.dart';
import '../models/user_response_dto.dart';
import '../services/credentials_service.dart';
import '../services/docx_import_service.dart';
import '../services/file_service.dart';
import '../services/user_service.dart';
import 'catalog_provider.dart';

/// Word importining yakuniy natijasi
class DocxUserImportResult {
  final List<UserCredential> created;
  final List<String> skipped; // tizimda allaqachon bor kursantlar
  final List<String> failed; // server yaratolmagan kursantlar / guruhlar

  const DocxUserImportResult({required this.created, required this.skipped, required this.failed});
}

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
      await _rememberCredential(result, dto.password);
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
    if (result != null) await _rememberCredential(result, dto.password);

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
      await CredentialsService().remove(id);
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Server parolni qaytarmaydi, shuning uchun eksport uchun lokal saqlab qo'yamiz
  Future<void> _rememberCredential(UserResponseDto user, String? password) async {
    if (user.id == null || password == null || password.isEmpty) return;
    await CredentialsService().saveAll([
      UserCredential(
        userId: user.id!,
        fullName: user.fullName,
        username: user.username ?? '',
        password: password,
        guruhId: user.guruh?.id,
        guruhName: user.guruh?.name,
        bosqichName: user.bosqich?.name,
      ),
    ]);
  }

  /// Guruh(lar) kesimida eksport uchun login/parollar. Paroli saqlanmaganlar bo'sh parol bilan qaytadi.
  Future<List<UserCredential>> credentialsForGroups(Set<String> guruhIds) async {
    final saved = await CredentialsService().loadAll();
    return _users.where((u) => u.role == 'USER' && guruhIds.contains(u.guruh?.id)).map((u) {
      final c = saved[u.id];
      return UserCredential(
        userId: u.id ?? '',
        fullName: u.fullName,
        username: u.username ?? c?.username ?? '',
        password: c?.password ?? '',
        guruhId: u.guruh?.id,
        guruhName: u.guruh?.name,
        bosqichName: u.bosqich?.name,
      );
    }).toList();
  }

  /// Word ro'yxatidan kursantlarni guruh kesimida yaratadi: guruh bo'lmasa tanlangan bosqichda ochiladi,
  /// har bir kursantga F.I.O dan login va tasodifiy parol generatsiya qilinadi, foto profil rasmi bo'lib yuklanadi.
  /// Shu guruhda F.I.Sh. bir xil kursant bo'lsa, u o'tkazib yuboriladi.
  Future<DocxUserImportResult> importStudentsFromDocx(
    List<DocxGroup> groups, {
    required Map<String, String> bosqichIdByGroup,
    required CatalogProvider catalogProvider,
    void Function(int done, int total)? onProgress,
  }) async {
    String nameKey(String name) => name.toLowerCase().replaceAll(RegExp(r"[^a-zа-яёўқғҳ0-9]"), '');

    final created = <UserCredential>[];
    final skipped = <String>[];
    final failed = <String>[];
    final takenUsernames = _users.map((u) => (u.username ?? '').toLowerCase()).toSet();
    final total = groups.fold(0, (sum, g) => sum + g.students.length);
    var done = 0;

    GuruhModel? findGuruh(String name, String bosqichId) {
      final key = groupKey(name);
      final matches = catalogProvider.allGuruhlar.where((g) => groupKey(g.name ?? '') == key).toList();
      return matches.where((g) => g.bosqich?.id == bosqichId).firstOrNull ?? matches.firstOrNull;
    }

    for (final group in groups) {
      final bosqichId = bosqichIdByGroup[group.name]!;
      final bosqichName = catalogProvider.allBosqichlar.where((b) => b.id == bosqichId).firstOrNull?.name;

      var guruh = findGuruh(group.name, bosqichId);
      if (guruh == null && await catalogProvider.createGuruh(group.name, bosqichId)) {
        guruh = findGuruh(group.name, bosqichId);
      }
      if (guruh?.id == null) {
        failed.addAll(group.students.map((s) => '${group.name}: ${s.fullName} (guruh yaratilmadi)'));
        done += group.students.length;
        onProgress?.call(done, total);
        continue;
      }

      final existing = _users.where((u) => u.role == 'USER' && u.guruh?.id == guruh!.id).map((u) => nameKey(u.fullName)).toSet();

      for (final row in group.students) {
        final (lastName, firstName, patronymic) = row.nameParts;
        if (existing.contains(nameKey([lastName, firstName, patronymic].where((s) => s.isNotEmpty).join(' ')))) {
          skipped.add('${guruh!.name}: ${row.fullName}');
        } else {
          String? imageUrl;
          if (row.photoBytes != null) {
            imageUrl = await FileService().uploadProfileImageBytes(
              row.photoBytes!,
              'docx_${DateTime.now().millisecondsSinceEpoch}_${row.rowNumber}${row.photoExtension}',
            );
          }

          final username = CredentialsService.generateUsername(firstName, lastName, takenUsernames);
          final password = CredentialsService.generatePassword(firstName);
          final user = await _service.createUser(UserCreateDto(
            username: username,
            password: password,
            role: 'USER',
            firstName: firstName,
            lastName: lastName,
            patronymic: patronymic,
            profileImageUrl: imageUrl,
            bosqichId: bosqichId,
            guruhId: guruh!.id,
          ));

          if (user == null) {
            failed.add('${guruh.name}: ${row.fullName}');
          } else {
            takenUsernames.add(username);
            _users.add(user);
            created.add(UserCredential(
              userId: user.id ?? username,
              fullName: user.fullName,
              username: user.username ?? username,
              password: password,
              guruhId: guruh.id,
              guruhName: guruh.name,
              bosqichName: bosqichName,
            ));
          }
        }
        onProgress?.call(++done, total);
      }
    }

    await CredentialsService().saveAll(created);
    notifyListeners();
    return DocxUserImportResult(created: created, skipped: skipped, failed: failed);
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
