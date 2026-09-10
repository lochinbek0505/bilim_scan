import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/edu_plan_model.dart';

class EduPlanProvider extends ChangeNotifier {
  List<EduPlanModel> _eduPlans = [];
  String _searchQuery = '';

  // Multi-criteria filters
  String? _selectedFanFilter;
  String? _selectedKafedraFilter;
  String? _selectedOquvYiliFilter;
  String? _selectedOquvOyiFilter;

  final Map<String, String> fans = {
    '6aa0f1d0e21b3be71d3be9d1': 'Matematika',
    '6aa0f1d0e21b3be71d3be9d2': 'Informatika va AT',
    '6aa0f1d0e21b3be71d3be9d3': 'Fizika',
  };

  final Map<String, String> kafedras = {
    '6aa0f20fe21b3be71d3be9d5': 'Informatika va AT kafedrasi',
    '6aa0f20fe21b3be71d3be9d6': 'Aniqlik fanlar kafedrasi',
  };

  final List<String> oquvYillari = [
    '2025-2026',
    '2026-2027',
  ];

  final List<String> oquvOylari = [
    'Sentyabr',
    'Oktyabr',
    'Noyabr',
    'Dekabr',
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
  ];

  EduPlanProvider() {
    _loadInitialSampleData();
  }

  List<EduPlanModel> get eduPlans {
    return _eduPlans.where((plan) {
      final matchesSearch = plan.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFan = _selectedFanFilter == null || plan.fanId == _selectedFanFilter;
      final matchesKafedra = _selectedKafedraFilter == null || plan.kafedraId == _selectedKafedraFilter;
      final matchesOquvYili = _selectedOquvYiliFilter == null || plan.oquvYili == _selectedOquvYiliFilter;
      final matchesOquvOyi = _selectedOquvOyiFilter == null || plan.oquvOyi == _selectedOquvOyiFilter;

      return matchesSearch && matchesFan && matchesKafedra && matchesOquvYili && matchesOquvOyi;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  String? get selectedFanFilter => _selectedFanFilter;
  String? get selectedKafedraFilter => _selectedKafedraFilter;
  String? get selectedOquvYiliFilter => _selectedOquvYiliFilter;
  String? get selectedOquvOyiFilter => _selectedOquvOyiFilter;

  bool get hasActiveFilters =>
      _selectedFanFilter != null ||
      _selectedKafedraFilter != null ||
      _selectedOquvYiliFilter != null ||
      _selectedOquvOyiFilter != null ||
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

  void setOquvYiliFilter(String? oquvYili) {
    _selectedOquvYiliFilter = oquvYili;
    notifyListeners();
  }

  void setOquvOyiFilter(String? oquvOyi) {
    _selectedOquvOyiFilter = oquvOyi;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedFanFilter = null;
    _selectedKafedraFilter = null;
    _selectedOquvYiliFilter = null;
    _selectedOquvOyiFilter = null;
    notifyListeners();
  }

  void addEduPlan(EduPlanModel plan) {
    _eduPlans.add(plan);
    notifyListeners();
  }

  void updateEduPlan(EduPlanModel plan) {
    final index = _eduPlans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _eduPlans[index] = plan;
      notifyListeners();
    }
  }

  void deleteEduPlan(String id) {
    _eduPlans.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Parse topics list from JSON file content
  List<EduPlanTopicModel> parseTopicsFromJson(String jsonContent) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonContent);
      return jsonList.map((t) => EduPlanTopicModel.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('JSON Parse error in edu plan topics: $e');
      return [];
    }
  }

  void _loadInitialSampleData() {
    const rawTopicsJson = '''
[
  {
    "tr": 1,
    "title": "Sonli to'plamlar va ularning xossalari",
    "soat": 4,
    "tur": "Ma'ruza"
  },
  {
    "tr": 2,
    "title": "Pifagor teoremasi va geometrik ayniyatlar",
    "soat": 6,
    "tur": "Amaliy mashg'ulot"
  },
  {
    "tr": 3,
    "title": "Kvadrat tenglamalar va diskriminant usuli",
    "soat": 8,
    "tur": "Ma'ruza"
  },
  {
    "tr": 4,
    "title": "Trigonometrik funksiyalar va ayniyatlar",
    "soat": 6,
    "tur": "Laboratoriya"
  }
]
''';

    final topics = parseTopicsFromJson(rawTopicsJson);

    _eduPlans = [
      EduPlanModel(
        id: '6aa13b3d6ad50fd0eb448ce5',
        name: 'Matematika fanidan o\'quv rejasi',
        fanId: '6aa0f1d0e21b3be71d3be9d1',
        kafedraId: '6aa0f20fe21b3be71d3be9d5',
        oquvOyi: 'Sentyabr',
        oquvYili: '2026-2027',
        topics: topics,
      ),
    ];
  }
}
