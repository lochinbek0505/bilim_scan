import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/test_model.dart';

class TestProvider extends ChangeNotifier {
  List<TestModel> _tests = [];
  String _searchQuery = '';

  // Multi-criteria filters
  String? _selectedFanFilter;
  String? _selectedKafedraFilter;
  String? _selectedEduPlanFilter;
  String? _selectedOquvYiliFilter;
  String? _selectedGuruhFilter;

  // Dropdown Options Mapping
  final Map<String, String> fans = {
    '6aa0f1d0e21b3be71d3be9d1': 'Matematika',
    '6aa0f1d0e21b3be71d3be9d2': 'Informatika va AT',
    '6aa0f1d0e21b3be71d3be9d3': 'Fizika',
  };

  final Map<String, String> kafedras = {
    '6aa0f20fe21b3be71d3be9d5': 'Informatika va AT kafedrasi',
    '6aa0f20fe21b3be71d3be9d6': 'Aniqlik fanlar kafedrasi',
  };

  final Map<String, String> eduPlans = {
    '6aa13b3d6ad50fd0eb448ce5': 'Matematika fanidan o\'quv rejasi',
    '6aa13b3d6ad50fd0eb448ce6': 'Informatika fanidan o\'quv rejasi',
  };

  final List<String> oquvYillari = [
    '2025-2026',
    '2026-2027',
  ];

  final List<String> guruhlar = [
    '10-25-guruh',
    '1-O\'quv guruhi',
    '2-O\'quv guruhi',
    '3-O\'quv guruhi',
  ];

  TestProvider() {
    _loadInitialSampleData();
  }

  List<TestModel> get tests {
    return _tests.where((test) {
      final matchesSearch = test.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFan = _selectedFanFilter == null || test.fanId == _selectedFanFilter;
      final matchesKafedra = _selectedKafedraFilter == null || test.kafedraId == _selectedKafedraFilter;
      final matchesEduPlan = _selectedEduPlanFilter == null || test.eduPlanId == _selectedEduPlanFilter;
      final matchesOquvYili = _selectedOquvYiliFilter == null || test.oquvYili == _selectedOquvYiliFilter;
      final matchesGuruh = _selectedGuruhFilter == null || test.guruhId == _selectedGuruhFilter;

      return matchesSearch && matchesFan && matchesKafedra && matchesEduPlan && matchesOquvYili && matchesGuruh;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  String? get selectedFanFilter => _selectedFanFilter;
  String? get selectedKafedraFilter => _selectedKafedraFilter;
  String? get selectedEduPlanFilter => _selectedEduPlanFilter;
  String? get selectedOquvYiliFilter => _selectedOquvYiliFilter;
  String? get selectedGuruhFilter => _selectedGuruhFilter;

  bool get hasActiveFilters =>
      _selectedFanFilter != null ||
      _selectedKafedraFilter != null ||
      _selectedEduPlanFilter != null ||
      _selectedOquvYiliFilter != null ||
      _selectedGuruhFilter != null ||
      _searchQuery.isNotEmpty;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFanFilter(String? fanId) {
    _selectedFanFilter = fanId;
    notifyListeners();
  }

  void setKafedraFilter(String? kafedraId) {
    _selectedKafedraFilter = kafedraId;
    notifyListeners();
  }

  void setEduPlanFilter(String? eduPlanId) {
    _selectedEduPlanFilter = eduPlanId;
    notifyListeners();
  }

  void setOquvYiliFilter(String? oquvYili) {
    _selectedOquvYiliFilter = oquvYili;
    notifyListeners();
  }

  void setGuruhFilter(String? guruhId) {
    _selectedGuruhFilter = guruhId;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedFanFilter = null;
    _selectedKafedraFilter = null;
    _selectedEduPlanFilter = null;
    _selectedOquvYiliFilter = null;
    _selectedGuruhFilter = null;
    notifyListeners();
  }

  void addTest(TestModel test) {
    _tests.add(test);
    notifyListeners();
  }

  void updateTest(TestModel test) {
    final index = _tests.indexWhere((t) => t.id == test.id);
    if (index != -1) {
      _tests[index] = test;
      notifyListeners();
    }
  }

  void deleteTest(String id) {
    _tests.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Parse questions list from JSON
  List<QuestionModel> parseQuestionsFromJson(String jsonContent) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonContent);
      return jsonList.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('JSON Parse error in questions: $e');
      return [];
    }
  }

  void _loadInitialSampleData() {
    const rawQuestionsJson = '''
[
  {
    "title": "Pifagor teoremasi qaysi turdagi uchburchaklar uchun o'rinli?",
    "mavzu": "Kirish",
    "type": "SINGLE_CHOICE",
    "tr": 1,
    "relatedQuestionTrs": [],
    "options": [
      { "text": "Faqat to'g'ri burchakli uchburchaklar uchun", "isTrue": true },
      { "text": "O'tkir burchakli uchburchaklar uchun", "isTrue": false },
      { "text": "O'tmas burchakli uchburchaklar uchun", "isTrue": false },
      { "text": "Ixtiyoriy uchburchaklar uchun", "isTrue": false }
    ]
  },
  {
    "title": "Yuqoridagi teoremaga asoslanib, katetlari 6 va 8 ga teng bo'lgan to'g'ri burchakli uchburchakning gipotenuzasini toping.",
    "mavzu": "Amaliy mashg'ulot",
    "type": "SINGLE_CHOICE",
    "tr": 2,
    "relatedQuestionTrs": [1],
    "options": [
      { "text": "10", "isTrue": true },
      { "text": "14", "isTrue": false },
      { "text": "12", "isTrue": false },
      { "text": "100", "isTrue": false }
    ]
  },
  {
    "title": "Quyidagi sonlardan qaysilari faqat o'ziga va 1 ga qoldiqsiz bo'linadigan tub sonlar hisoblanadi?",
    "mavzu": "Kirish",
    "type": "MULTIPLE_CHOICE",
    "tr": 3,
    "relatedQuestionTrs": [],
    "options": [
      { "text": "2", "isTrue": true },
      { "text": "9", "isTrue": false },
      { "text": "13", "isTrue": true },
      { "text": "15", "isTrue": false },
      { "text": "17", "isTrue": true }
    ]
  },
  {
    "title": "24 va 36 sonlarining eng katta umumiy bo'luvchisini (EKUB) toping.",
    "mavzu": "Amaliy mashg'ulot",
    "type": "OPEN",
    "tr": 4,
    "relatedQuestionTrs": [],
    "options": []
  },
  {
    "title": "Trigonometriyada qaysi ayniyatlar har doim to'g'ri?",
    "mavzu": "Kirish",
    "type": "MULTIPLE_CHOICE",
    "tr": 5,
    "relatedQuestionTrs": [],
    "options": [
      { "text": "sin²(x) + cos²(x) = 1", "isTrue": true },
      { "text": "tg(x) = cos(x) / sin(x)", "isTrue": false },
      { "text": "tg(x) = sin(x) / cos(x)", "isTrue": true },
      { "text": "sin(90°) = 0", "isTrue": false }
    ]
  },
  {
    "title": "Kvadrat tenglamani diskriminant (D) orqali yechish algoritmini bosqichma-bosqich tushuntirib yozing.",
    "mavzu": "Amaliy mashg'ulot",
    "type": "WRITTEN",
    "tr": 6,
    "relatedQuestionTrs": [],
    "options": []
  },
  {
    "title": "Yozgan algoritmingizdan foydalanib, x² - 5x + 6 = 0 tenglamaning ildizlarini toping.",
    "mavzu": "Amaliy mashg'ulot",
    "type": "SINGLE_CHOICE",
    "tr": 7,
    "relatedQuestionTrs": [6],
    "options": [
      { "text": "x₁ = -2, x₂ = -3", "isTrue": false },
      { "text": "x₁ = 2, x₂ = 3", "isTrue": true },
      { "text": "x₁ = 1, x₂ = 6", "isTrue": false },
      { "text": "Ildizga ega emas", "isTrue": false }
    ]
  },
  {
    "title": "Aylananing uzunligi 20π ga teng bo'lsa, uning radiusini hisoblang.",
    "mavzu": "Amaliy mashg'ulot",
    "type": "OPEN",
    "tr": 8,
    "relatedQuestionTrs": [],
    "options": []
  }
]
''';

    final questions = parseQuestionsFromJson(rawQuestionsJson);

    _tests = [
      TestModel(
        id: 'test_6aa0f1d0e21b3be71d3be9d1',
        name: 'Matematika fanidan 1-oraliq nazorat',
        fanId: '6aa0f1d0e21b3be71d3be9d1',
        kafedraId: '6aa0f20fe21b3be71d3be9d5',
        eduPlanId: '6aa13b3d6ad50fd0eb448ce5',
        guruhId: '10-25-guruh',
        oquvYili: '2026-2027',
        ajratilganVaqt: 60,
        questions: questions,
      ),
    ];
  }
}
