import 'package:flutter/foundation.dart';
import '../models/student_exam_model.dart';
import '../models/student_exam_start_model.dart';
import '../services/student_exam_service.dart';

class StudentExamProvider extends ChangeNotifier {
  final StudentExamService _service = StudentExamService();

  bool _isLoading = false;
  List<ExamSessionModel> _exams = [];
  StudentExamStartModel? _currentStartedExam;
  ExamResultResponse? _lastResult;

  // Answers map during test taking: questionId -> list of selected texts
  final Map<String, List<String>> _userAnswers = {};

  bool get isLoading => _isLoading;
  List<ExamSessionModel> get exams => _exams;
  StudentExamStartModel? get currentStartedExam => _currentStartedExam;
  ExamResultResponse? get lastResult => _lastResult;
  Map<String, List<String>> get userAnswers => _userAnswers;

  Future<void> fetchExams() async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.getExams();
    _exams = result;

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> startExam(String examSessionId, String studentId) async {
    _isLoading = true;
    _userAnswers.clear();
    _lastResult = null;
    notifyListeners();

    final response = await _service.startExam(examSessionId, studentId);
    if (response != null) {
      _currentStartedExam = response;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void selectSingleAnswer(String questionId, String optionText) {
    _userAnswers[questionId] = [optionText];
    notifyListeners();
  }

  void toggleMultipleAnswer(String questionId, String optionText) {
    final list = _userAnswers[questionId] ?? [];
    List<String> updated = List.from(list);
    if (updated.contains(optionText)) {
      updated.remove(optionText);
    } else {
      updated.add(optionText);
    }
    _userAnswers[questionId] = updated;
    notifyListeners();
  }

  void setWrittenAnswer(String questionId, String text) {
    if (text.trim().isEmpty) {
      _userAnswers.remove(questionId);
    } else {
      _userAnswers[questionId] = [text.trim()];
    }
    notifyListeners();
  }

  Future<bool> submitExam() async {
    if (_currentStartedExam == null) return false;

    _isLoading = true;
    notifyListeners();

    final studentExamId = _currentStartedExam!.studentExamId ?? _currentStartedExam!.id ?? '';

    final result = await _service.submitExam(
      studentExamId,
      _userAnswers,
    );

    if (result != null) {
      _lastResult = result;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void resetCurrentExam() {
    _currentStartedExam = null;
    _userAnswers.clear();
    _lastResult = null;
    notifyListeners();
  }
}
