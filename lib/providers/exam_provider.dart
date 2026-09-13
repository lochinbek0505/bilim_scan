import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';

class ExamProvider extends ChangeNotifier {
  final ExamService _service = ExamService();

  bool _isLoading = false;
  List<ExamModel> _exams = [];
  String _searchQuery = '';

  // Multi-criteria filters
  String? _selectedGuruhFilter;
  String? _selectedTestFilter;
  String? _selectedStatusFilter;

  // Mapping for Group IDs (Fallback for local display)
  final Map<String, String> guruhlarMap = {
    '6aa0f1e7e21b3be71d3be9d3': '10-25-guruh',
    '6aa4e443a3ff6e858f7ba3fc': 'SI 22-10',
    '6aa0f1e7e21b3be71d3be9d4': '1-O\'quv guruhi',
  };

  // Mapping for Test IDs (Fallback for local display)
  final Map<String, String> testsMap = {
    '6aa2dc8219ef3807c41081be': 'Matematika fanidan 1-oraliq nazorat',
    '6aa2dc8219ef3807c41081bf': 'Informatika algoritmlari nazorati',
  };

  final List<String> statusList = ['FAOL', 'REJALASHTIRILGAN', 'YAKUNLANGAN'];

  bool get isLoading => _isLoading;

  List<ExamModel> get exams {
    return _exams.where((exam) {
      final nameStr = exam.name ?? '';
      final matchesSearch = nameStr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exam.guruhId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exam.testId.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesGuruh = _selectedGuruhFilter == null || exam.guruhId == _selectedGuruhFilter;
      final matchesTest = _selectedTestFilter == null || exam.testId == _selectedTestFilter;
      final matchesStatus = _selectedStatusFilter == null || exam.status == _selectedStatusFilter;

      return matchesSearch && matchesGuruh && matchesTest && matchesStatus;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  String? get selectedGuruhFilter => _selectedGuruhFilter;
  String? get selectedTestFilter => _selectedTestFilter;
  String? get selectedStatusFilter => _selectedStatusFilter;

  bool get hasActiveFilters =>
      _selectedGuruhFilter != null ||
      _selectedTestFilter != null ||
      _selectedStatusFilter != null ||
      _searchQuery.isNotEmpty;

  ExamProvider() {
    _loadInitialSampleData();
    fetchExams();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
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
    _selectedGuruhFilter = null;
    _selectedTestFilter = null;
    _selectedStatusFilter = null;
    notifyListeners();
  }

  Future<void> fetchExams() async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.getExams();
    if (result.isNotEmpty) {
      _exams = result;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createExam(ExamModel exam) async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.createExam(exam);

    final createdExam = result ??
        ExamModel(
          id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
          name: exam.name ?? 'Imtihon',
          testId: exam.testId,
          guruhId: exam.guruhId,
          durationMinutes: exam.durationMinutes,
          questionCount: exam.questionCount,
          maxAttempts: exam.maxAttempts,
          status: 'FAOL',
        );

    _exams.add(createdExam);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> addExam(ExamModel exam) => createExam(exam);

  Future<bool> updateExam(ExamModel exam) async {
    _isLoading = true;
    notifyListeners();

    await _service.updateExam(exam);

    final index = _exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      _exams[index] = exam;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteExam(String id) async {
    await _service.deleteExam(id);
    _exams.removeWhere((e) => e.id == id);
    notifyListeners();
    return true;
  }

  void changeStatus(String id, String newStatus) {
    final index = _exams.indexWhere((e) => e.id == id);
    if (index != -1) {
      _exams[index] = _exams[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void _loadInitialSampleData() {
    _exams = [
      ExamModel(
        id: '6aa6851fa54e61873dc628df',
        name: 'Matematika 1-Oraliq Imtihoni (SI 22-10)',
        testId: '6aa2dc8219ef3807c41081be',
        guruhId: '6aa0f1e7e21b3be71d3be9d3',
        durationMinutes: 20,
        questionCount: 5,
        maxAttempts: 20,
        status: 'FAOL',
      ),
    ];
  }
}
