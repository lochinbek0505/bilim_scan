import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import '../models/edu_plan_model.dart';
import '../models/test_model.dart';
import '../services/catalog_service.dart';
import '../services/edu_plan_service.dart';
import '../services/test_service.dart';

class TestProvider extends ChangeNotifier {
  final TestService _service = TestService();
  final CatalogService _catalogService = CatalogService();
  final EduPlanService _eduPlanService = EduPlanService();

  List<TestModel> _tests = [];
  List<EduPlanModel> rawEduPlans = [];
  String _searchQuery = '';
  bool isLoading = false;

  // Multi-criteria filters
  String? _selectedFanFilter;
  String? _selectedKafedraFilter;
  String? _selectedEduPlanFilter;
  String? _selectedOquvYiliFilter;
  String? _selectedGuruhFilter;

  // Dropdown Options Mapping
  Map<String, String> fans = {};
  Map<String, String> kafedras = {};
  Map<String, String> eduPlans = {};
  Map<String, String> guruhlar = {};
  late final List<String> oquvYillari;

  TestProvider() {
    _initOquvYillari();
    fetchData();
  }

  void _initOquvYillari() {
    oquvYillari = List.generate(50, (index) {
      int startYear = 2024 + index;
      return '$startYear-${startYear + 1}';
    });
  }

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _service.getTests(),
        _catalogService.getFanlar(),
        _catalogService.getKafedralar(),
        _eduPlanService.getEduPlans(),
        _catalogService.getGuruhlar(),
      ]);

      final testsResult = futures[0] as List<TestModel>;
      if (testsResult.isNotEmpty) {
        _tests = testsResult;
      }

      final fanlarList = futures[1] as List<dynamic>;
      fans = {
        for (var fan in fanlarList)
          if (fan.id != null) fan.id!: fan.name ?? 'Noma\'lum fan',
      };

      final kafedralarList = futures[2] as List<dynamic>;
      kafedras = {
        for (var k in kafedralarList)
          if (k.id != null) k.id!: k.name ?? 'Noma\'lum kafedra',
      };

      final plansList = futures[3] as List<dynamic>;
      if (plansList.isNotEmpty) {
        rawEduPlans = List<EduPlanModel>.from(plansList);
      }
      eduPlans = {
        for (var plan in plansList)
          if (plan.id != null) plan.id!: plan.name ?? 'Noma\'lum reja',
      };

      final guruhlarList = futures[4] as List<dynamic>;
      guruhlar = {
        for (var g in guruhlarList)
          if (g.id != null) g.id!: g.name ?? 'Noma\'lum guruh',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching test data: $e');
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<List<QuestionModel>> fetchQuestionsForTest(String testId) async {
    final questions = await _service.getQuestionsByTestId(testId);
    final index = _tests.indexWhere((t) => t.id == testId);
    if (index != -1) {
      _tests[index] = _tests[index].copyWith(questions: questions);
      notifyListeners();
    }
    return questions;
  }

  List<TestModel> get tests {
    return _tests.where((test) {
      final matchesSearch = test.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesFan =
          _selectedFanFilter == null || test.fanId == _selectedFanFilter;
      final matchesKafedra =
          _selectedKafedraFilter == null ||
          test.kafedraId == _selectedKafedraFilter;
      final matchesEduPlan =
          _selectedEduPlanFilter == null ||
          test.eduPlanId == _selectedEduPlanFilter;
      final matchesOquvYili =
          _selectedOquvYiliFilter == null ||
          test.oquvYili == _selectedOquvYiliFilter;
      final matchesGuruh =
          _selectedGuruhFilter == null || test.guruhId == _selectedGuruhFilter;

      return matchesSearch &&
          matchesFan &&
          matchesKafedra &&
          matchesEduPlan &&
          matchesOquvYili &&
          matchesGuruh;
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

  Future<void> addTest(TestModel test) async {
    isLoading = true;
    notifyListeners();
    final result = await _service.createTest(test);
    if (result != null) {
      _tests.add(result);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateTest(TestModel test) async {
    isLoading = true;
    notifyListeners();
    final success = await _service.updateTest(test);
    if (success) {
      final index = _tests.indexWhere((t) => t.id == test.id);
      if (index != -1) {
        _tests[index] = test;
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTest(String id) async {
    isLoading = true;
    notifyListeners();
    final success = await _service.deleteTest(id);
    if (success) {
      _tests.removeWhere((t) => t.id == id);
    }
    isLoading = false;
    notifyListeners();
  }

  // Parse questions list from JSON
  List<QuestionModel> parseQuestionsFromJson(String jsonContent) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonContent);
      return jsonList
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('JSON Parse error in questions: $e');
      return [];
    }
  }

  // Parse questions from DOCX bytes
  List<QuestionModel> parseQuestionsFromDocxBytes(
    Uint8List bytes, [
    List<EduPlanTopicModel>? topics,
  ]) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentFile = archive.findFile('word/document.xml');
      if (documentFile == null) return [];

      final xmlContent = utf8.decode(
        documentFile.content as List<int>,
        allowMalformed: true,
      );

      final pMatches = RegExp(
        r'<w:p[^>]*>(.*?)</w:p>',
        dotAll: true,
      ).allMatches(xmlContent);
      List<String> lines = [];
      for (final m in pMatches) {
        final pContent = m.group(1) ?? '';
        final tMatches = RegExp(
          r'<w:t[^>]*>(.*?)</w:t>',
          dotAll: true,
        ).allMatches(pContent);
        final lineText = tMatches.map((t) => t.group(1) ?? '').join('').trim();
        if (lineText.isNotEmpty) {
          lines.add(_unescapeXml(lineText));
        }
      }

      return _parseQuestionsFromLines(lines, topics);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DOCX Parse error: $e');
      }
      return [];
    }
  }

  String _unescapeXml(String input) {
    return input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }

  List<QuestionModel> _parseQuestionsFromLines(
    List<String> lines, [
    List<EduPlanTopicModel>? topics,
  ]) {
    List<QuestionModel> questions = [];
    QuestionModel? currentQuestion;
    int trCounter = 1;
    Map<String, int> firstTrOfMajor = {};

    for (var line in lines) {
      // Check if line is a question start: "1.1) Question text" or "1.1 Question text" or "3.3)Python"
      final qMatch = RegExp(r'^(\d+)\.(\d+)\s*[\)\.]?\s*(.*)').firstMatch(line);

      if (qMatch != null) {
        if (currentQuestion != null) {
          questions.add(_finalizeQuestionType(currentQuestion));
        }

        final majorStr = qMatch.group(1) ?? '1';
        final majorNum = int.tryParse(majorStr) ?? 1;
        final title = (qMatch.group(3) ?? '').trim();
        final tr = trCounter++;

        EduPlanTopicModel? matchedTopic;
        if (topics != null && topics.isNotEmpty) {
          for (var t in topics) {
            if (t.tr == majorNum) {
              matchedTopic = t;
              break;
            }
          }
          if (matchedTopic == null &&
              majorNum - 1 >= 0 &&
              majorNum - 1 < topics.length) {
            matchedTopic = topics[majorNum - 1];
          }
        }

        matchedTopic ??= EduPlanTopicModel(
          tr: majorNum,
          name: '$majorNum-mavzu',
          soat: 2,
          type: 'Amaliy',
        );

        List<int> related = [];
        if (firstTrOfMajor.containsKey(majorStr)) {
          related.add(firstTrOfMajor[majorStr]!);
        } else {
          firstTrOfMajor[majorStr] = tr;
        }

        currentQuestion = QuestionModel(
          title: title,
          mavzu: matchedTopic,
          type: 'SINGLE_CHOICE',
          // Will be finalized later
          tr: tr,
          relatedQuestionTrs: related,
          options: [],
        );
      } else if (currentQuestion != null) {
        // Parse options or title continuation
        if (line.startsWith('@')) {
          currentQuestion = QuestionModel(
            title: currentQuestion.title,
            mavzu: currentQuestion.mavzu,
            type: 'WRITTEN',
            tr: currentQuestion.tr,
            relatedQuestionTrs: currentQuestion.relatedQuestionTrs,
            options: currentQuestion.options,
          );
          String text = line.substring(1).trim();
          if (text.isNotEmpty) {
            currentQuestion.options.add(OptionModel(text: text, isTrue: true));
          }
        } else if (line.startsWith('#')) {
          String text = line.replaceAll(RegExp(r'^#+'), '').trim();
          text = text.replaceAll(RegExp(r'^[A-Za-z0-9]+[\)\.]\s*'), '').trim();
          currentQuestion.options.add(OptionModel(text: text, isTrue: true));
        } else if (RegExp(r'^[A-Za-z0-9]+[\)\.]').hasMatch(line)) {
          String text = line
              .replaceAll(RegExp(r'^[A-Za-z0-9]+[\)\.]\s*'), '')
              .trim();
          currentQuestion.options.add(OptionModel(text: text, isTrue: false));
        } else if (currentQuestion.options.isEmpty) {
          // Continuation of multi-line question title
          currentQuestion = QuestionModel(
            title: '${currentQuestion.title} $line'.trim(),
            mavzu: currentQuestion.mavzu,
            type: currentQuestion.type,
            tr: currentQuestion.tr,
            relatedQuestionTrs: currentQuestion.relatedQuestionTrs,
            options: currentQuestion.options,
          );
        } else {
          String text = line
              .replaceAll(RegExp(r'^[A-Za-z0-9]+[\)\.]\s*'), '')
              .trim();
          if (text.isNotEmpty) {
            currentQuestion.options.add(OptionModel(text: text, isTrue: false));
          }
        }
      }
    }

    if (currentQuestion != null) {
      questions.add(_finalizeQuestionType(currentQuestion));
    }

    return questions;
  }

  QuestionModel _finalizeQuestionType(QuestionModel q) {
    if (q.type == 'WRITTEN') return q; // already set by @

    if (q.options.isEmpty) {
      return QuestionModel(
        title: q.title,
        mavzu: q.mavzu,
        type: 'OPEN',
        tr: q.tr,
        relatedQuestionTrs: q.relatedQuestionTrs,
        options: q.options,
      );
    }

    int trueCount = q.options.where((o) => o.isTrue).length;
    if (trueCount > 1) {
      return QuestionModel(
        title: q.title,
        mavzu: q.mavzu,
        type: 'MULTIPLE_CHOICE',
        tr: q.tr,
        relatedQuestionTrs: q.relatedQuestionTrs,
        options: q.options,
      );
    }

    return q; // SINGLE_CHOICE default
  }
}
