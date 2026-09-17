import 'package:flutter/foundation.dart';
import '../models/catalog_response.dart';
import '../models/exam_model.dart';
import '../models/guruh_model.dart';
import '../models/test_model.dart';
import '../services/catalog_service.dart';
import '../services/exam_service.dart';
import '../services/test_service.dart';

class ExamProvider extends ChangeNotifier {
  final ExamService _service = ExamService();
  final CatalogService _catalogService = CatalogService();
  final TestService _testService = TestService();

  bool _isLoading = false;
  List<ExamModel> _exams = [];
  List<CatalogResponse> rawBosqichlar = [];
  List<GuruhModel> rawGuruhlar = [];
  List<TestModel> rawTests = [];

  String _searchQuery = '';

  // Multi-criteria filters
  String? _selectedBosqichFilter;
  String? _selectedGuruhFilter;
  String? _selectedTestFilter;
  String? _selectedStatusFilter;

  Map<String, String> bosqichlarMap = {};
  Map<String, String> guruhlarMap = {};
  Map<String, String> testsMap = {};

  final List<String> statusList = ['FAOL', 'REJALASHTIRILGAN', 'YAKUNLANGAN'];

  bool get isLoading => _isLoading;

  List<ExamModel> get exams {
    return _exams.where((exam) {
      final nameStr = exam.name ?? '';
      final matchesSearch = nameStr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exam.guruhId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exam.testId.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesBosqich = _selectedBosqichFilter == null ||
          (exam.guruh?.bosqich?.id == _selectedBosqichFilter) ||
          (rawGuruhlar.any((g) => g.id == exam.guruhId && g.bosqich?.id == _selectedBosqichFilter));

      final matchesGuruh = _selectedGuruhFilter == null || exam.guruhId == _selectedGuruhFilter;
      final matchesTest = _selectedTestFilter == null || exam.testId == _selectedTestFilter;
      final matchesStatus = _selectedStatusFilter == null || exam.status == _selectedStatusFilter;

      return matchesSearch && matchesBosqich && matchesGuruh && matchesTest && matchesStatus;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  String? get selectedBosqichFilter => _selectedBosqichFilter;
  String? get selectedGuruhFilter => _selectedGuruhFilter;
  String? get selectedTestFilter => _selectedTestFilter;
  String? get selectedStatusFilter => _selectedStatusFilter;

  bool get hasActiveFilters =>
      _selectedBosqichFilter != null ||
      _selectedGuruhFilter != null ||
      _selectedTestFilter != null ||
      _selectedStatusFilter != null ||
      _searchQuery.isNotEmpty;

  ExamProvider() {
    fetchInitialData();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setBosqichFilter(String? bosqichId) {
    _selectedBosqichFilter = bosqichId;
    if (bosqichId != null && _selectedGuruhFilter != null) {
      final g = rawGuruhlar.firstWhere((e) => e.id == _selectedGuruhFilter, orElse: () => GuruhModel());
      if (g.bosqich?.id != bosqichId) {
        _selectedGuruhFilter = null;
      }
    }
    notifyListeners();
  }

  void setGuruhFilter(String? guruhId) {
    _selectedGuruhFilter = guruhId;
    notifyListeners();
  }

  void setTestFilter(String? testId) {
    _selectedTestFilter = testId;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedBosqichFilter = null;
    _selectedGuruhFilter = null;
    _selectedTestFilter = null;
    _selectedStatusFilter = null;
    notifyListeners();
  }

  Future<void> fetchInitialData({bool isAdmin = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        isAdmin ? _service.getExamAdmin() : _service.getExams(),
        _catalogService.getBosqichlar(),
        _catalogService.getGuruhlar(),
        _testService.getTests(),
      ]);

      final examsResult = futures[0] as List<ExamModel>;
      _exams = examsResult;

      rawBosqichlar = futures[1] as List<CatalogResponse>;
      bosqichlarMap = {
        for (var b in rawBosqichlar)
          if (b.id != null) b.id!: b.name ?? 'Bosqich',
      };

      rawGuruhlar = futures[2] as List<GuruhModel>;
      guruhlarMap = {
        for (var g in rawGuruhlar)
          if (g.id != null) g.id!: g.name ?? 'Guruh',
      };

      rawTests = futures[3] as List<TestModel>;
      testsMap = {
        for (var t in rawTests)
          t.id: t.name,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching exam initial data: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchExams({bool isAdmin = true}) => fetchInitialData(isAdmin: isAdmin);
  Future<void> fetchAdminExams() => fetchInitialData(isAdmin: true);

  Future<bool> createExam(ExamModel exam) async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.createExam(exam);
    if (result != null) {
      _exams.add(result);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> addExam(ExamModel exam) => createExam(exam);

  Future<bool> updateExam(ExamModel exam) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.updateExam(exam);
    if (success) {
      final index = _exams.indexWhere((e) => e.id == exam.id);
      if (index != -1) {
        _exams[index] = exam;
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteExam(String id) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.deleteExam(id);
    if (success) {
      _exams.removeWhere((e) => e.id == id);
    }
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> disableExam(String id) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.disableExam(id);
    if (success) {
      final index = _exams.indexWhere((e) => e.id == id);
      if (index != -1) {
        _exams[index] = _exams[index].copyWith(active: false, status: 'YAKUNLANGAN');
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  void changeStatus(String id, String newStatus) {
    final index = _exams.indexWhere((e) => e.id == id);
    if (index != -1) {
      _exams[index] = _exams[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }
}
