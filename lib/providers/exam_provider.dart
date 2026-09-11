import 'package:flutter/material.dart';
import '../models/exam_model.dart';

class ExamProvider extends ChangeNotifier {
  List<ExamModel> _exams = [];
  String _searchQuery = '';

  // Multi-criteria filters
  String? _selectedGuruhFilter;
  String? _selectedTestFilter;
  String? _selectedStatusFilter;

  // Mapping for Group IDs
  final Map<String, String> guruhlarMap = {
    '6aa0f1e7e21b3be71d3be9d3': '10-25-guruh',
    '6aa0f1e7e21b3be71d3be9d4': '1-O\'quv guruhi',
    '6aa0f1e7e21b3be71d3be9d5': '2-O\'quv guruhi',
  };

  // Mapping for Test IDs
  final Map<String, String> testsMap = {
    '6aa2dc8219ef3807c41081be': 'Matematika fanidan 1-oraliq nazorat',
    '6aa2dc8219ef3807c41081bf': 'Informatika algoritmlari nazorati',
    '6aa2dc8219ef3807c41081bg': 'Fizika va dinamika nazorat testi',
  };

  final List<String> statusList = ['FAOL', 'REJALASHTIRILGAN', 'YAKUNLANGAN'];

  ExamProvider() {
    _loadInitialSampleData();
  }

  List<ExamModel> get exams {
    return _exams.where((exam) {
      final matchesSearch = exam.name.toLowerCase().contains(_searchQuery.toLowerCase());
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

  void addExam(ExamModel exam) {
    _exams.add(exam);
    notifyListeners();
  }

  void updateExam(ExamModel exam) {
    final index = _exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      _exams[index] = exam;
      notifyListeners();
    }
  }

  void deleteExam(String id) {
    _exams.removeWhere((e) => e.id == id);
    notifyListeners();
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
        id: 'exam_1001',
        name: 'Matematika 1-Oraliq Imtihoni',
        testId: '6aa2dc8219ef3807c41081be',
        guruhId: '6aa0f1e7e21b3be71d3be9d3',
        durationMinutes: 20,
        questionCount: 5,
        maxAttempts: 20,
        status: 'FAOL',
      ),
      ExamModel(
        id: 'exam_1002',
        name: 'Informatika Algoritmlari Yakuniy Imtihon',
        testId: '6aa2dc8219ef3807c41081bf',
        guruhId: '6aa0f1e7e21b3be71d3be9d4',
        durationMinutes: 45,
        questionCount: 15,
        maxAttempts: 3,
        status: 'REJALASHTIRILGAN',
      ),
    ];
  }
}
