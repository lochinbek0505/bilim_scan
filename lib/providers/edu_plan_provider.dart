import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import '../models/edu_plan_model.dart';
import '../services/edu_plan_service.dart';
import '../services/catalog_service.dart';

class EduPlanProvider extends ChangeNotifier {
  final EduPlanService _service = EduPlanService();
  final CatalogService _catalogService = CatalogService();

  bool _isLoading = false;
  List<EduPlanModel> _eduPlans = [];
  String _searchQuery = '';

  // Multi-criteria filters
  String? _selectedFanFilter;
  String? _selectedKafedraFilter;
  String? _selectedOquvYiliFilter;

  Map<String, String> fans = {};
  Map<String, String> kafedras = {};

  late final List<String> oquvYillari;
  final List<String> oquvOylari = [
    'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr', 'Yanvar',
    'Fevral', 'Mart', 'Aprel', 'May', 'Iyun', 'Iyul', 'Avgust'
  ];

  bool get isLoading => _isLoading;

  List<EduPlanModel> get eduPlans {
    return _eduPlans.where((plan) {
      final matchesSearch = plan.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFan = _selectedFanFilter == null || plan.fanId == _selectedFanFilter;
      final matchesKafedra = _selectedKafedraFilter == null || plan.kafedraId == _selectedKafedraFilter;
      final matchesOquvYili = _selectedOquvYiliFilter == null || plan.oquvYili == _selectedOquvYiliFilter;

      return matchesSearch && matchesFan && matchesKafedra && matchesOquvYili;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  String? get selectedFanFilter => _selectedFanFilter;
  String? get selectedKafedraFilter => _selectedKafedraFilter;
  String? get selectedOquvYiliFilter => _selectedOquvYiliFilter;

  bool get hasActiveFilters =>
      _selectedFanFilter != null ||
      _selectedKafedraFilter != null ||
      _selectedOquvYiliFilter != null ||
      _searchQuery.isNotEmpty;

  EduPlanProvider() {
    _initOquvYillari();
    fetchEduPlans();
  }

  void _initOquvYillari() {
    oquvYillari = List.generate(50, (index) {
      int startYear = 2024 + index;
      return '$startYear-${startYear + 1}';
    });
  }

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

  void resetFilters() {
    _searchQuery = '';
    _selectedFanFilter = null;
    _selectedKafedraFilter = null;
    _selectedOquvYiliFilter = null;
    notifyListeners();
  }

  Future<void> fetchEduPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _service.getEduPlans(),
        _catalogService.getFanlar(),
        _catalogService.getKafedralar(),
      ]);

      final plansResult = futures[0] as List<EduPlanModel>;
      if (plansResult.isNotEmpty) {
        _eduPlans = plansResult;
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching edu plans and catalog data: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createEduPlan(EduPlanModel plan) async {
    _isLoading = true;
    notifyListeners();

    final result = await _service.createEduPlan(plan);

    if (result != null) {
      _eduPlans.add(result);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> addEduPlan(EduPlanModel plan) => createEduPlan(plan);

  Future<bool> updateEduPlan(EduPlanModel plan) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.updateEduPlan(plan);

    if (success) {
      final index = _eduPlans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _eduPlans[index] = plan;
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteEduPlan(String id) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.deleteEduPlan(id);
    if (success) {
      _eduPlans.removeWhere((p) => p.id == id);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Parse topics list from JSON string content
  List<EduPlanTopicModel> parseTopicsFromJson(String jsonContent) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonContent);
      return jsonList.map((t) => EduPlanTopicModel.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [JSON PARSE ERR]: $e');
      }
      return [];
    }
  }

  // PARSE EXCEL (.xlsx) FILE
  // Uses standard decoder first, and falls back to Zip/XML parser for custom number format IDs
  Map<String, dynamic> parseTopicsFromExcelBytes(Uint8List bytes) {
    String extractedTitle = '';
    final List<EduPlanTopicModel> topics = [];

    // Try 1: Standard Excel package decoder
    try {
      final excel = Excel.decodeBytes(bytes);

      for (final tableKey in excel.tables.keys) {
        final table = excel.tables[tableKey];
        if (table == null || table.rows.isEmpty) continue;

        int trCol = -1;
        int nameCol = -1;
        int soatCol = -1;
        int typeCol = -1;

        for (int r = 0; r < table.rows.length; r++) {
          final row = table.rows[r];
          if (row.isEmpty) continue;

          final rowText = row.map((c) => c?.value?.toString().trim() ?? '').join(' ');

          if (extractedTitle.isEmpty && rowText.isNotEmpty && !rowText.toLowerCase().contains('t/r')) {
            for (final cell in row) {
              final val = cell?.value?.toString().trim() ?? '';
              if (val.length > 5 && !val.toLowerCase().contains('t/r')) {
                extractedTitle = val;
                break;
              }
            }
          }

          if (trCol == -1) {
            for (int c = 0; c < row.length; c++) {
              final cellVal = row[c]?.value?.toString().trim().toLowerCase() ?? '';
              if (cellVal.contains('t/r') || cellVal == 'tr' || cellVal == '№') {
                trCol = c;
              } else if (cellVal.contains('mavzu') || cellVal.contains('mazmuni') || cellVal.contains('nomi')) {
                nameCol = c;
              } else if (cellVal.contains('soat')) {
                soatCol = c;
              } else if (cellVal.contains('turi') || cellVal.contains('mashg‘ulot') || cellVal.contains('mashgulot')) {
                typeCol = c;
              }
            }
            if (trCol != -1) continue;
          }

          if (trCol != -1) {
            final trValRaw = trCol < row.length ? row[trCol]?.value?.toString().trim() ?? '' : '';
            final parsedTr = int.tryParse(trValRaw);

            if (parsedTr != null) {
              final nameVal = nameCol != -1 && nameCol < row.length ? row[nameCol]?.value?.toString().trim() ?? '' : '';
              final soatValRaw = soatCol != -1 && soatCol < row.length ? row[soatCol]?.value?.toString().trim() ?? '' : '';
              final parsedSoat = int.tryParse(soatValRaw) ?? 2;
              final typeVal = typeCol != -1 && typeCol < row.length ? row[typeCol]?.value?.toString().trim() ?? '' : 'Amaliy';

              if (nameVal.isNotEmpty) {
                topics.add(
                  EduPlanTopicModel(
                    tr: parsedTr,
                    name: nameVal,
                    soat: parsedSoat,
                    type: typeVal.isEmpty ? 'Amaliy' : typeVal,
                  ),
                );
              }
            }
          }
        }
      }

      if (topics.isNotEmpty) {
        return {
          'title': extractedTitle,
          'topics': topics,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [EXCEL PACKAGE DECODER FAILED, SWITCHING TO ZIP/XML FALLBACK]: $e');
      }
    }

    // Try 2: Fallback Zip / XML Spreadsheet Parser
    try {
      final zipResult = _parseXlsxViaZipXml(bytes);
      return zipResult;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ZIP/XML FALLBACK PARSER ERR]: $e');
      }
    }

    return {
      'title': extractedTitle,
      'topics': topics,
    };
  }

  // ROBUST ZIP/XML FALLBACK PARSER FOR XLSX
  Map<String, dynamic> _parseXlsxViaZipXml(Uint8List bytes) {
    String extractedTitle = '';
    final List<EduPlanTopicModel> topics = [];

    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Extract sharedStrings.xml
    final List<String> sharedStrings = [];
    final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedStringsFile != null) {
      final xmlContent = utf8.decode(sharedStringsFile.content as List<int>, allowMalformed: true);
      final matches = RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true).allMatches(xmlContent);
      for (final m in matches) {
        sharedStrings.add(_unescapeXml(m.group(1) ?? ''));
      }
    }

    // 2. Find Sheet File
    ArchiveFile? sheetFile;
    for (final file in archive) {
      if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
        sheetFile = file;
        break;
      }
    }

    if (sheetFile == null) return {'title': '', 'topics': []};

    final sheetXml = utf8.decode(sheetFile.content as List<int>, allowMalformed: true);

    // 3. Parse Rows and Cells
    final rowRegExp = RegExp(r'<row[^>]*>(.*?)</row>', dotAll: true);
    final cellRegExp = RegExp(r'<c\s+r="([A-Z]+)\d+"(?:\s+s="\d+")?(?:\s+t="([^"]+)")?[^>]*>(?:<v>(.*?)</v>|<is><t>(.*?)</t></is>)?', dotAll: true);

    final rowMatches = rowRegExp.allMatches(sheetXml);

    int trCol = -1;
    int nameCol = -1;
    int soatCol = -1;
    int typeCol = -1;

    for (final rMatch in rowMatches) {
      final rowContent = rMatch.group(1) ?? '';
      final Map<int, String> rowCells = {};

      final cellMatches = cellRegExp.allMatches(rowContent);
      for (final cMatch in cellMatches) {
        final colLetters = cMatch.group(1) ?? 'A';
        final typeAttr = cMatch.group(2) ?? '';
        final valContent = cMatch.group(3) ?? '';
        final inlineValContent = cMatch.group(4) ?? '';

        final colIndex = _colLettersToIndex(colLetters);
        String cellText = '';

        if (typeAttr == 's') {
          final strIndex = int.tryParse(valContent);
          if (strIndex != null && strIndex >= 0 && strIndex < sharedStrings.length) {
            cellText = sharedStrings[strIndex];
          }
        } else if (inlineValContent.isNotEmpty) {
          cellText = _unescapeXml(inlineValContent);
        } else {
          cellText = _unescapeXml(valContent);
        }

        rowCells[colIndex] = cellText.trim();
      }

      if (rowCells.isEmpty) continue;

      final fullRowText = rowCells.values.join(' ');

      if (extractedTitle.isEmpty && fullRowText.isNotEmpty && !fullRowText.toLowerCase().contains('t/r')) {
        for (final cellVal in rowCells.values) {
          if (cellVal.length > 5 && !cellVal.toLowerCase().contains('t/r')) {
            extractedTitle = cellVal;
            break;
          }
        }
      }

      if (trCol == -1) {
        for (final entry in rowCells.entries) {
          final cellVal = entry.value.toLowerCase();
          if (cellVal.contains('t/r') || cellVal == 'tr' || cellVal == '№') {
            trCol = entry.key;
          } else if (cellVal.contains('mavzu') || cellVal.contains('mazmuni') || cellVal.contains('nomi')) {
            nameCol = entry.key;
          } else if (cellVal.contains('soat')) {
            soatCol = entry.key;
          } else if (cellVal.contains('turi') || cellVal.contains('mashg‘ulot') || cellVal.contains('mashgulot')) {
            typeCol = entry.key;
          }
        }
        if (trCol != -1) continue;
      }

      if (trCol != -1) {
        final trStr = rowCells[trCol] ?? '';
        final parsedTr = int.tryParse(trStr);

        if (parsedTr != null) {
          final nameVal = rowCells[nameCol] ?? (rowCells[trCol + 1] ?? '');
          final soatStr = rowCells[soatCol] ?? (rowCells[trCol + 2] ?? '2');
          final parsedSoat = int.tryParse(soatStr) ?? 2;
          final typeVal = rowCells[typeCol] ?? 'Amaliy';

          if (nameVal.isNotEmpty) {
            topics.add(
              EduPlanTopicModel(
                tr: parsedTr,
                name: nameVal,
                soat: parsedSoat,
                type: typeVal.isEmpty ? 'Amaliy' : typeVal,
              ),
            );
          }
        }
      }
    }

    return {
      'title': extractedTitle,
      'topics': topics,
    };
  }

  int _colLettersToIndex(String col) {
    int result = 0;
    for (int i = 0; i < col.length; i++) {
      result = result * 26 + (col.codeUnitAt(i) - 64);
    }
    return result - 1;
  }

  String _unescapeXml(String input) {
    return input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }


}
