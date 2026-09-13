import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/test_model.dart';
import '../../providers/test_provider.dart';

class TestManagementScreen extends StatefulWidget {
  const TestManagementScreen({super.key});

  @override
  State<TestManagementScreen> createState() => _TestManagementScreenState();
}

class _TestManagementScreenState extends State<TestManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testProvider = Provider.of<TestProvider>(context);

    return TacticalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary.withValues(alpha: 0.95),
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.goldPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TESTLARNI BOSHQARISH VA FILTRLASH',
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
              ),
              Text(
                'O\'quv rejasi, o\'quv yili, kafedra, fan va guruhlar bo\'yicha saralash',
                style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_task_outlined, size: 18, color: AppColors.backgroundDark),
                label: Text('YANGI TEST YARATISH', style: AppTextStyles.buttonText.copyWith(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => _showTestFormDialog(context, null),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // MULTI-CRITERIA FILTER PANEL
              _buildFilterPanel(testProvider),

              const SizedBox(height: 16),

              // Tests List
              Expanded(
                child: testProvider.tests.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: testProvider.tests.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final test = testProvider.tests[index];
                          return _buildTestCard(context, test, testProvider);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MULTI-CRITERIA FILTER PANEL
  Widget _buildFilterPanel(TestProvider testProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, color: AppColors.goldPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'KO\'P MEZONLI FILTRLASH PORTALI',
                    style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.goldPrimary),
                  ),
                ],
              ),
              if (testProvider.hasActiveFilters)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 16, color: AppColors.error),
                  label: Text('FILTRLARNI TOZALASH', style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _searchController.clear();
                    testProvider.resetFilters();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field Row
          TextField(
            controller: _searchController,
            onChanged: (val) => testProvider.setSearchQuery(val),
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Test nomi bo\'yicha kalit so\'z kiriting...',
              hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.goldPrimary, size: 20),
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.goldPrimary),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Dropdowns Row (Fan, Kafedra, EduPlan, O'quv Yili, Guruh)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // 1. Fan Filter
              _buildFilterDropdown(
                hint: 'Fan: Barchasi',
                value: testProvider.selectedFanFilter,
                items: testProvider.fans.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => testProvider.setFanFilter(val),
              ),

              // 2. Kafedra Filter
              _buildFilterDropdown(
                hint: 'Kafedra: Barchasi',
                value: testProvider.selectedKafedraFilter,
                items: testProvider.kafedras.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => testProvider.setKafedraFilter(val),
              ),

              // 3. EduPlan Filter
              _buildFilterDropdown(
                hint: 'O\'quv Reja: Barchasi',
                value: testProvider.selectedEduPlanFilter,
                items: testProvider.eduPlans.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => testProvider.setEduPlanFilter(val),
              ),

              // 4. O'quv Yili Filter
              _buildFilterDropdown(
                hint: 'O\'quv Yili: Barchasi',
                value: testProvider.selectedOquvYiliFilter,
                items: testProvider.oquvYillari.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => testProvider.setOquvYiliFilter(val),
              ),

              // 5. Guruh Filter
              _buildFilterDropdown(
                hint: 'Guruh: Barchasi',
                value: testProvider.selectedGuruhFilter,
                items: testProvider.guruhlar.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => testProvider.setGuruhFilter(val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: value != null ? AppColors.goldPrimary : AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          dropdownColor: AppColors.cardDark,
          hint: Text(hint, style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 12)),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('$hint (Barchasi)', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            ...items,
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('Kiritilgan filtrlar bo\'yicha test topilmadi', style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Filtr sozlamalarini o\'zgartiring yoki "FILTRLARNI TOZALASH" tugmasini bosing', style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestModel test, TestProvider testProvider) {
    final fanName = testProvider.fans[test.fanId] ?? test.fanId;
    final kafedraName = testProvider.kafedras[test.kafedraId] ?? test.kafedraId;
    final eduPlanName = testProvider.eduPlans[test.eduPlanId] ?? test.eduPlanId;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.goldPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(test.name, style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('$kafedraName • $fanName', style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.goldPrimary, size: 20),
                    tooltip: 'Tahrirlash',
                    onPressed: () => _showTestFormDialog(context, test),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    tooltip: 'O\'chirish',
                    onPressed: () => _confirmDeleteDialog(context, test.id, testProvider),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          // Badges & Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildBadge(Icons.timer_outlined, '${test.ajratilganVaqt} min', AppColors.goldPrimary),
                  _buildBadge(Icons.quiz_outlined, '${test.questions.length} ta savol', AppColors.emeraldAccent),
                  _buildBadge(Icons.calendar_month, 'Yil: ${test.oquvYili}', const Color(0xFF0EA5E9)),
                  _buildBadge(Icons.groups_outlined, 'Guruh: ${test.guruhId}', const Color(0xFFA855F7)),
                  _buildBadge(Icons.grid_view_outlined, eduPlanName, AppColors.info),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.emeraldAccent),
                label: Text('SAVOLLARNI KO\'RISH (${test.questions.length})', style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.emeraldAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.emeraldAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _showQuestionsViewerModal(context, test),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  // CREATE / EDIT TEST DIALOG WITH NATIVE FILE PICKER FOR JSON
  void _showTestFormDialog(BuildContext context, TestModel? testToEdit) {
    final testProvider = Provider.of<TestProvider>(context, listen: false);

    final nameController = TextEditingController(text: testToEdit?.name ?? '');
    final vaqtController = TextEditingController(text: (testToEdit?.ajratilganVaqt ?? 60).toString());
    final jsonImportController = TextEditingController();

    String selectedFanId = testToEdit?.fanId ?? testProvider.fans.keys.first;
    String selectedKafedraId = testToEdit?.kafedraId ?? testProvider.kafedras.keys.first;
    String selectedEduPlanId = testToEdit?.eduPlanId ?? testProvider.eduPlans.keys.first;
    String selectedOquvYili = testToEdit?.oquvYili ?? testProvider.oquvYillari.first;
    String selectedGuruh = testToEdit?.guruhId ?? testProvider.guruhlar.first;

    List<QuestionModel> currentQuestions = testToEdit != null ? List.from(testToEdit.questions) : [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
            ),
            title: Row(
              children: [
                Icon(
                  testToEdit == null ? Icons.add_circle_outline : Icons.edit_note,
                  color: AppColors.goldPrimary,
                ),
                const SizedBox(width: 10),
                Text(
                  testToEdit == null ? 'YANGI TEST YARATISH' : 'TESTNI TAHRIRLASH',
                  style: AppTextStyles.titleHeader.copyWith(fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFormLabel('TEST NOMI'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Masalan: Matematika fanidan 1-oraliq nazorat'),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('FAN'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedFanId,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: testProvider.fans.entries.map((e) {
                                      return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedFanId = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('KAFEDRA'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedKafedraId,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: testProvider.kafedras.entries.map((e) {
                                      return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedKafedraId = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('O\'QUV REJA (EDU PLAN)'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedEduPlanId,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: testProvider.eduPlans.entries.map((e) {
                                      return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedEduPlanId = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('GURUH'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedGuruh,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: testProvider.guruhlar.map((e) {
                                      return DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedGuruh = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('O\'QUV YILI'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedOquvYili,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: testProvider.oquvYillari.map((e) {
                                      return DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedOquvYili = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('VAQT (DAQIQA)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: vaqtController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('60'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 10),

                    // JSON Questions Import Section with Native File Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFormLabel('SAVOLLAR FAYLI (JSON IMPORT)'),
                        Text('${currentQuestions.length} ta savol yuklangan', style: AppTextStyles.badgeText.copyWith(color: AppColors.emeraldAccent)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open_outlined, size: 16),
                      label: const Text('KOMPYUTERDAN JSON FAYLNI TANLASH (.json)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: AppColors.backgroundDark,
                      ),
                      onPressed: () async {
                        try {
                          final PlatformFile? file = await FilePicker.pickFile(
                            type: FileType.custom,
                            allowedExtensions: ['json'],
                          );

                          if (file != null) {
                            String jsonContent = '';

                            if (file.path != null && file.path!.isNotEmpty) {
                              jsonContent = await File(file.path!).readAsString();
                            } else {
                              final bytes = await file.readAsBytes();
                              jsonContent = utf8.decode(bytes);
                            }

                            if (jsonContent.isNotEmpty) {
                              jsonImportController.text = jsonContent;
                              final parsed = testProvider.parseQuestionsFromJson(jsonContent);
                              if (parsed.isNotEmpty) {
                                setModalState(() {
                                  currentQuestions = parsed;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('✔ ${parsed.length} ta savol fayldan muvaffaqiyatli o\'qindi!'), backgroundColor: AppColors.emeraldAccent),
                                  );
                                }
                              }
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Faylni o\'qishda xatolik: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: jsonImportController,
                      maxLines: 4,
                      style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Yoki JSON matnini bu yerga nusxalab joylashtiring...',
                        hintStyle: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: const Text('MATNNI PARSE QILISH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldPrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final rawJson = jsonImportController.text.trim();
                        if (rawJson.isNotEmpty) {
                          final parsed = testProvider.parseQuestionsFromJson(rawJson);
                          if (parsed.isNotEmpty) {
                            setModalState(() {
                              currentQuestions = parsed;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${parsed.length} ta savol muvaffaqiyatli parse qilindi!'), backgroundColor: AppColors.emeraldAccent),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('JSON formati noto\'g\'ri! Coder JSON formatini tekshiring.'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('BEKOR QILISH', style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.backgroundDark),
                onPressed: () {
                  final name = nameController.text.trim();
                  final vaqt = int.tryParse(vaqtController.text.trim()) ?? 60;

                  if (name.isEmpty) return;

                  final newTest = TestModel(
                    id: testToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    fanId: selectedFanId,
                    kafedraId: selectedKafedraId,
                    eduPlanId: selectedEduPlanId,
                    guruhId: selectedGuruh,
                    oquvYili: selectedOquvYili,
                    ajratilganVaqt: vaqt,
                    questions: currentQuestions,
                  );

                  if (testToEdit == null) {
                    testProvider.addTest(newTest);
                  } else {
                    testProvider.updateTest(newTest);
                  }

                  Navigator.of(dialogContext).pop();
                },
                child: Text(testToEdit == null ? 'YARATISH' : 'SAQLASH'),
              ),
            ],
          );
        },
      ),
    );
  }

  // QUESTIONS INSPECTOR MODAL WITH MAVZU BADGE & LINKED QUESTIONS HIGHLIGHTING
  void _showQuestionsViewerModal(BuildContext context, TestModel test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.emeraldAccent)),
        title: Row(
          children: [
            const Icon(Icons.quiz_outlined, color: AppColors.emeraldAccent),
            const SizedBox(width: 10),
            Expanded(child: Text('${test.name} — SAVOLLAR RO\'YXATI (${test.questions.length} TA)', style: AppTextStyles.titleHeader.copyWith(fontSize: 15))),
          ],
        ),
        content: SizedBox(
          width: 640,
          height: 520,
          child: test.questions.isEmpty
              ? Center(child: Text('Hozircha savollar yuklanmagan.', style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)))
              : ListView.separated(
                  itemCount: test.questions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final q = test.questions[index];
                    final hasRelatedQuestions = q.relatedQuestionTrs.isNotEmpty;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasRelatedQuestions ? AppColors.goldPrimary : AppColors.cardBorder,
                          width: hasRelatedQuestions ? 1.5 : 1.0,
                        ),
                        boxShadow: hasRelatedQuestions
                            ? [
                                BoxShadow(
                                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TR + MAVZU + TYPE ROW
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // TR Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldPrimary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('SAVOL #${q.tr}', style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.goldPrimary)),
                                  ),
                                  const SizedBox(width: 8),

                                  // MAVZU BADGE
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldPrimary.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.emeraldAccent.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.menu_book, size: 12, color: AppColors.emeraldAccent),
                                        const SizedBox(width: 4),
                                        Text('Mavzu: ${q.mavzu}', style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.emeraldAccent)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // TYPE BADGE
                              _buildQuestionTypeBadge(q.type),
                            ],
                          ),

                          // LINKED / RELATED QUESTIONS HIGHLIGHT
                          if (hasRelatedQuestions) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.link_sharp, size: 14, color: AppColors.goldPrimary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '🔗 BOG\'LIQ SAVOL: #${q.relatedQuestionTrs.join(', #')}-SAVOLGA ASOSLANGAN',
                                    style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // QUESTION TITLE
                          Text(q.title, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),

                          // OPTIONS LIST
                          if (q.options.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: AppColors.cardBorder),
                            const SizedBox(height: 8),
                            ...q.options.map((opt) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: opt.isTrue ? AppColors.emeraldPrimary.withValues(alpha: 0.15) : AppColors.cardDark,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: opt.isTrue ? AppColors.emeraldAccent : AppColors.cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(opt.isTrue ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: opt.isTrue ? AppColors.emeraldAccent : AppColors.textMuted),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(opt.text, style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: opt.isTrue ? AppColors.emeraldAccent : AppColors.textSecondary))),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldAccent, foregroundColor: AppColors.backgroundDark),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('YOPISH'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeBadge(String type) {
    Color color = AppColors.goldPrimary;
    if (type == 'MULTIPLE_CHOICE') color = const Color(0xFFA855F7);
    if (type == 'OPEN') color = const Color(0xFF0EA5E9);
    if (type == 'WRITTEN') color = const Color(0xFFEC4899);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
      child: Text(type, style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: color)),
    );
  }

  void _confirmDeleteDialog(BuildContext context, String id, TestProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('TESTNI O\'CHIRISH', style: AppTextStyles.titleHeader.copyWith(color: AppColors.error)),
        content: Text('Haqiqatan ham ushbu testni o\'chirib tashlamoqchimisiz?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('BEKOR QILISH')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              provider.deleteTest(id);
              Navigator.of(context).pop();
            },
            child: const Text('O\'CHIRISH'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(label, style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.textSecondary));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.goldPrimary)),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}
