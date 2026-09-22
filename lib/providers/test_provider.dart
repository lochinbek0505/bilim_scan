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

  Future<List<TestModel>> fetchTestsFiltered({String? fanId, String? kafedraId}) async {
    return await _service.getTests(fanId: fanId, kafedraId: kafedraId);
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

  Future<bool> addTest(TestModel test) async {
    isLoading = true;
    notifyListeners();
    final processedQuestions = test.questions.map((q) => q.withCalculatedMinimumTime()).toList();
    final testToSend = test.copyWith(questions: processedQuestions);
    final result = await _service.createTest(testToSend);
    if (result != null) {
      _tests.add(result);
      isLoading = false;
      notifyListeners();
      return true;
    }
    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateTest(TestModel test) async {
    isLoading = true;
    notifyListeners();
    final processedQuestions = test.questions.map((q) => q.withCalculatedMinimumTime()).toList();
    final testToSend = test.copyWith(questions: processedQuestions);
    final success = await _service.updateTest(testToSend);
    if (success) {
      final index = _tests.indexWhere((t) => t.id == test.id);
      if (index != -1) {
        _tests[index] = testToSend;
      }
    }
    isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteTest(String id) async {
    isLoading = true;
    notifyListeners();
    final success = await _service.deleteTest(id);
    if (success) {
      _tests.removeWhere((t) => t.id == id);
    }
    isLoading = false;
    notifyListeners();
    return success;
  }

  // Parse questions list from JSON
  List<QuestionModel> parseQuestionsFromJson(String jsonContent) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonContent);
      return jsonList
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>).withCalculatedMinimumTime())
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
        final parsedLine = _extractParagraphTextWithMath(pContent).trim();
        if (parsedLine.isNotEmpty) {
          lines.add(parsedLine);
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

  String _extractParagraphTextWithMath(String pContent) {
    return _parseParagraphSequentially(pContent).trim();
  }

  String _parseParagraphSequentially(String pContent) {
    final sb = StringBuffer();
    // Match either an Office Math element <m:oMath>...</m:oMath> or a text run <w:r>...</w:r>
    final regex = RegExp(r'(<m:oMath[^>]*>.*?</m:oMath>)|(<w:r[^>]*>.*?</w:r>)', dotAll: true);
    final matches = regex.allMatches(pContent);

    if (matches.isEmpty) {
      // Fallback: just extract <w:t> tags
      final tMatches = RegExp(r'<(?:w|m):t[^>]*>(.*?)</(?:w|m):t>', dotAll: true).allMatches(pContent);
      return tMatches.map((t) => _unescapeXml(t.group(1) ?? '')).join('').trim();
    }

    for (final match in matches) {
      if (match.group(1) != null) {
        // It's a Math block
        sb.write(_parseMathBlock(match.group(1)!));
      } else if (match.group(2) != null) {
        // It's a text run
        sb.write(_parseTextRun(match.group(2)!));
      }
    }
    return sb.toString();
  }

  String _parseTextRun(String rContent) {
    final isSup = rContent.contains('val="superscript"');
    final isSub = rContent.contains('val="subscript"');

    final tMatches = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true).allMatches(rContent);
    var text = tMatches.map((t) => t.group(1) ?? '').join('');

    final symMatch = RegExp(r'<w:sym[^>]*w:char="([^"]+)"[^>]*>', dotAll: true).firstMatch(rContent);
    if (symMatch != null) {
      final hex = symMatch.group(1) ?? '';
      final charCode = int.tryParse(hex, radix: 16);
      if (charCode != null) {
        text += String.fromCharCode(charCode);
      }
    }

    if (text.isEmpty) return '';

    text = _unescapeXml(text);
    if (isSup) return _toSuperscript(text);
    if (isSub) return _toSubscript(text);
    return text;
  }

  String _parseMathBlock(String mContent) {
    String xml = mContent;

    // 1. Replace math fractions <m:f> -> (num/den)
    xml = xml.replaceAllMapped(RegExp(r'<m:f(?:>|\s[^>]*>)(.*?)</m:f>', dotAll: true), (match) {
      final fBody = match.group(1) ?? '';
      final numMatch = RegExp(r'<m:num(?:>|\s[^>]*>)(.*?)</m:num>', dotAll: true).firstMatch(fBody);
      final denMatch = RegExp(r'<m:den(?:>|\s[^>]*>)(.*?)</m:den>', dotAll: true).firstMatch(fBody);
      final numText = _extractTextFromXmlChunk(numMatch?.group(1) ?? '');
      final denText = _extractTextFromXmlChunk(denMatch?.group(1) ?? '');
      if (numText.isNotEmpty && denText.isNotEmpty) {
        return '($numText/$denText)';
      }
      return _extractTextFromXmlChunk(fBody);
    });

    // 2. Replace superscripts <m:sSup> -> base^exp
    xml = xml.replaceAllMapped(RegExp(r'<m:sSup(?:>|\s[^>]*>)(.*?)</m:sSup>', dotAll: true), (match) {
      final body = match.group(1) ?? '';
      final eMatch = RegExp(r'<m:e(?:>|\s[^>]*>)(.*?)</m:e>', dotAll: true).firstMatch(body);
      final supMatch = RegExp(r'<m:sup(?:>|\s[^>]*>)(.*?)</m:sup>', dotAll: true).firstMatch(body);
      final baseText = _extractTextFromXmlChunk(eMatch?.group(1) ?? '');
      final supText = _extractTextFromXmlChunk(supMatch?.group(1) ?? '');
      if (supText.isNotEmpty) {
        return '$baseText${_toSuperscript(supText)}';
      }
      return baseText;
    });

    // 3. Replace subscripts <m:sSub> -> base_sub
    xml = xml.replaceAllMapped(RegExp(r'<m:sSub(?:>|\s[^>]*>)(.*?)</m:sSub>', dotAll: true), (match) {
      final body = match.group(1) ?? '';
      final eMatch = RegExp(r'<m:e(?:>|\s[^>]*>)(.*?)</m:e>', dotAll: true).firstMatch(body);
      final subMatch = RegExp(r'<m:sub(?:>|\s[^>]*>)(.*?)</m:sub>', dotAll: true).firstMatch(body);
      final baseText = _extractTextFromXmlChunk(eMatch?.group(1) ?? '');
      final subText = _extractTextFromXmlChunk(subMatch?.group(1) ?? '');
      if (subText.isNotEmpty) {
        return '$baseText${_toSubscript(subText)}';
      }
      return baseText;
    });

    // 4. Replace sub-sup <m:sSubSup> -> base_sub^sup
    xml = xml.replaceAllMapped(RegExp(r'<m:sSubSup(?:>|\s[^>]*>)(.*?)</m:sSubSup>', dotAll: true), (match) {
      final body = match.group(1) ?? '';
      final eMatch = RegExp(r'<m:e(?:>|\s[^>]*>)(.*?)</m:e>', dotAll: true).firstMatch(body);
      final subMatch = RegExp(r'<m:sub(?:>|\s[^>]*>)(.*?)</m:sub>', dotAll: true).firstMatch(body);
      final supMatch = RegExp(r'<m:sup(?:>|\s[^>]*>)(.*?)</m:sup>', dotAll: true).firstMatch(body);
      final baseText = _extractTextFromXmlChunk(eMatch?.group(1) ?? '');
      final subText = _extractTextFromXmlChunk(subMatch?.group(1) ?? '');
      final supText = _extractTextFromXmlChunk(supMatch?.group(1) ?? '');
      return '$baseText${_toSubscript(subText)}${_toSuperscript(supText)}';
    });

    // 5. Replace radicals <m:rad> -> √(elem)
    xml = xml.replaceAllMapped(RegExp(r'<m:rad(?:>|\s[^>]*>)(.*?)</m:rad>', dotAll: true), (match) {
      final body = match.group(1) ?? '';
      final degMatch = RegExp(r'<m:deg(?:>|\s[^>]*>)(.*?)</m:deg>', dotAll: true).firstMatch(body);
      final eMatch = RegExp(r'<m:e(?:>|\s[^>]*>)(.*?)</m:e>', dotAll: true).firstMatch(body);
      final degText = _extractTextFromXmlChunk(degMatch?.group(1) ?? '');
      final elemText = _extractTextFromXmlChunk(eMatch?.group(1) ?? '');
      if (degText.isNotEmpty && degText != '2') {
        return '${_toSuperscript(degText)}√($elemText)';
      }
      return '√($elemText)';
    });

    // Finally extract all remaining text from <m:t> or <w:t> tags
    return _extractTextFromXmlChunk(xml);
  }

  String _extractTextFromXmlChunk(String chunk) {
    if (chunk.isEmpty) return '';
    final tMatches = RegExp(r'<(?:w|m):t[^>]*>(.*?)</(?:w|m):t>', dotAll: true).allMatches(chunk);
    return tMatches.map((t) => _unescapeXml(t.group(1) ?? '')).join('');
  }

  String _toSuperscript(String str) {
    const normal = '0123456789+-=()nixyabcdekmpt';
    const superChars = '⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿⁱˣʸªᵇᶜᵈᵉᵏᵐᵖᵗ';
    final sb = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      final idx = normal.indexOf(char);
      if (idx != -1) {
        sb.write(superChars[idx]);
      } else {
        sb.write(char);
      }
    }
    return sb.toString();
  }

  String _toSubscript(String str) {
    const normal = '0123456789+-=()aeoxhklmnpst';
    const subChars = '₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎ₐₑₒₓₕₖₗₘₙₚₛₜ';
    final sb = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      final idx = normal.indexOf(char);
      if (idx != -1) {
        sb.write(subChars[idx]);
      } else {
        sb.write(char);
      }
    }
    return sb.toString();
  }

  String _unescapeXml(String input) {
    return input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&#178;', '²')
        .replaceAll('&#179;', '³')
        .replaceAll('&#185;', '¹');
  }

  List<QuestionModel> _parseQuestionsFromLines(
    List<String> lines, [
    List<EduPlanTopicModel>? topics,
  ]) {
    List<_TempParsedQuestion> rawParsedList = [];
    QuestionModel? currentQuestion;
    String? currentNumCode;
    List<String> currentRelatedCodes = [];
    int trCounter = 1;

    // Pattern to match question header: e.g. "1.1)[2.3,5.7] title", "1.1) title", "1.1 [2.3] title"
    final qHeaderRegex = RegExp(
      r'^\s*(\d+(?:\.\d+)?)\s*[\)\.]?\s*(?:\[([^\]]+)\])?\s*(.*)',
    );

    // Pattern to check topic header line like "2-mavzu: ...", "2. mavzu: ..."
    final topicHeaderRegex = RegExp(
      r'^\s*\d+[\s\-\.]*mavzu',
      caseSensitive: false,
    );

    EduPlanTopicModel? activeTopic;

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Check if line is a topic header line
      if (topicHeaderRegex.hasMatch(trimmedLine)) {
        final numMatch = RegExp(r'^\s*(\d+)').firstMatch(trimmedLine);
        if (numMatch != null) {
          final majorNum = int.tryParse(numMatch.group(1) ?? '1') ?? 1;
          if (topics != null && topics.isNotEmpty) {
            for (var t in topics) {
              if (t.tr == majorNum) {
                activeTopic = t;
                break;
              }
            }
          }
          activeTopic ??= EduPlanTopicModel(
            tr: majorNum,
            name: '$majorNum-mavzu',
            soat: 2,
            type: 'Amaliy',
          );
        }
        continue;
      }

      // Check if line is a question start
      final qMatch = qHeaderRegex.firstMatch(trimmedLine);

      if (qMatch != null &&
          !RegExp(r'^[A-Za-z]\)').hasMatch(trimmedLine) &&
          !trimmedLine.startsWith('#') &&
          !trimmedLine.startsWith('@')) {
        final fullNumStr = qMatch.group(1) ?? '1';
        final majorStr = fullNumStr.contains('.') ? fullNumStr.split('.').first : fullNumStr;
        final majorNum = int.tryParse(majorStr) ?? 1;
        final rawBrackets = qMatch.group(2) ?? '';
        final title = (qMatch.group(3) ?? '').trim();

        // Extract related codes from brackets if present e.g. [2.3,5.7]
        List<String> relatedCodes = [];
        if (rawBrackets.trim().isNotEmpty) {
          relatedCodes = rawBrackets
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }

        if (currentQuestion != null) {
          rawParsedList.add(
            _TempParsedQuestion(
              numCode: currentNumCode ?? '',
              relatedCodes: currentRelatedCodes,
              question: _finalizeQuestionType(currentQuestion),
            ),
          );
        }

        final tr = trCounter++;

        // Determine topic for this question
        EduPlanTopicModel? matchedTopic = activeTopic;
        if (topics != null && topics.isNotEmpty) {
          for (var t in topics) {
            if (t.tr == majorNum) {
              matchedTopic = t;
              break;
            }
          }
          if (matchedTopic == null && majorNum - 1 >= 0 && majorNum - 1 < topics.length) {
            matchedTopic = topics[majorNum - 1];
          }
        }

        matchedTopic ??= EduPlanTopicModel(
          tr: majorNum,
          name: '$majorNum-mavzu',
          soat: 2,
          type: 'Amaliy',
        );

        currentNumCode = fullNumStr;
        currentRelatedCodes = relatedCodes;

        currentQuestion = QuestionModel(
          title: title,
          mavzu: matchedTopic,
          type: 'SINGLE_CHOICE',
          minimumTime: 0,
          tr: tr,
          relatedQuestionTrs: const [],
          options: [],
        );
      } else if (currentQuestion != null) {
        // Parse options or title continuation
        if (trimmedLine.startsWith('@')) {
          currentQuestion = QuestionModel(
            title: currentQuestion.title,
            mavzu: currentQuestion.mavzu,
            type: 'WRITTEN',
            tr: currentQuestion.tr,
            minimumTime: 0,
            relatedQuestionTrs: currentQuestion.relatedQuestionTrs,
            options: currentQuestion.options,
          );
          String text = trimmedLine.substring(1).trim();
          if (text.isNotEmpty) {
            currentQuestion.options.add(OptionModel(text: text, isTrue: true));
          }
        } else if (trimmedLine.startsWith('#')) {
          String text = trimmedLine.replaceAll(RegExp(r'^#+'), '').trim();
          text = text.replaceAll(RegExp(r'^[A-Za-z0-9]+[\)\.]\s*'), '').trim();
          currentQuestion.options.add(OptionModel(text: text, isTrue: true));
        } else if (RegExp(r'^[A-Za-z0-9]+[\)\.]').hasMatch(trimmedLine)) {
          String text = trimmedLine
              .replaceAll(RegExp(r'^[A-Za-z0-9]+[\)\.]\s*'), '')
              .trim();
          currentQuestion.options.add(OptionModel(text: text, isTrue: false));
        } else if (currentQuestion.options.isEmpty) {
          // Continuation of multi-line question title
          currentQuestion = QuestionModel(
            title: '${currentQuestion.title} $trimmedLine'.trim(),
            mavzu: currentQuestion.mavzu,
            type: currentQuestion.type,
            tr: currentQuestion.tr,
            minimumTime: 0,
            relatedQuestionTrs: currentQuestion.relatedQuestionTrs,
            options: currentQuestion.options,
          );
        } else {
          String text = trimmedLine
              .replaceAll(RegExp(r'^[A-Za-z0-9]+[\)\.]\s*'), '')
              .trim();
          if (text.isNotEmpty) {
            currentQuestion.options.add(OptionModel(text: text, isTrue: false));
          }
        }
      }
    }

    if (currentQuestion != null) {
      rawParsedList.add(
        _TempParsedQuestion(
          numCode: currentNumCode ?? '',
          relatedCodes: currentRelatedCodes,
          question: _finalizeQuestionType(currentQuestion),
        ),
      );
    }

    // Map numCode -> tr (e.g. "1.1" -> 1, "2.3" -> 3, "5.7" -> 4)
    final Map<String, int> numCodeToTr = {};
    for (var temp in rawParsedList) {
      if (temp.numCode.isNotEmpty) {
        numCodeToTr[temp.numCode] = temp.question.tr;
      }
    }

    // Second pass: Resolve related codes to question trs
    final List<QuestionModel> finalizedQuestions = [];
    for (var temp in rawParsedList) {
      List<int> resolvedTrs = [];
      for (var code in temp.relatedCodes) {
        if (numCodeToTr.containsKey(code)) {
          resolvedTrs.add(numCodeToTr[code]!);
        } else {
          final pInt = int.tryParse(code);
          if (pInt != null) {
            resolvedTrs.add(pInt);
          }
        }
      }

      finalizedQuestions.add(
        temp.question.copyWith(
          relatedQuestionTrs: resolvedTrs,
        ),
      );
    }

    return finalizedQuestions;
  }

  QuestionModel _finalizeQuestionType(QuestionModel q) {
    final QuestionModel finalized = () {
      if (q.type == 'WRITTEN') return q; // already set by @

      if (q.options.isEmpty) {
        return QuestionModel(
          id: q.id,
          title: q.title,
          mavzu: q.mavzu,
          type: 'OPEN',
          tr: q.tr,
          minimumTime: q.minimumTime,
          relatedQuestionTrs: q.relatedQuestionTrs,
          relatedQuestionIds: q.relatedQuestionIds,
          options: q.options,
        );
      }

      int trueCount = q.options.where((o) => o.isTrue).length;
      if (trueCount > 1) {
        return QuestionModel(
          id: q.id,
          title: q.title,
          mavzu: q.mavzu,
          type: 'MULTIPLE_CHOICE',
          tr: q.tr,
          minimumTime: q.minimumTime,
          relatedQuestionTrs: q.relatedQuestionTrs,
          relatedQuestionIds: q.relatedQuestionIds,
          options: q.options,
        );
      }

      return q; // SINGLE_CHOICE default
    }();

    return finalized.withCalculatedMinimumTime();
  }
}

class _TempParsedQuestion {
  final String numCode;
  final List<String> relatedCodes;
  final QuestionModel question;

  _TempParsedQuestion({
    required this.numCode,
    required this.relatedCodes,
    required this.question,
  });
}
