import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/exam_model.dart';
import '../../models/guruh_model.dart';
import '../../models/test_model.dart';
import '../../providers/exam_provider.dart';
import '../../providers/test_provider.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);

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
                'IMTIHONLARNI YARATISH VA BOSHQARISH',
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
              ),
              Text(
                'Mavjud testlar va guruhlar asosida imtihon seanslarini shakllantirish',
                style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.note_add_outlined, size: 18, color: AppColors.backgroundDark),
                label: Text('YANGI IMTIHON YARATISH', style: AppTextStyles.buttonText.copyWith(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => _showExamFormDialog(context, null),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Metrics Summary Row
              _buildMetricsSummaryRow(examProvider),

              const SizedBox(height: 16),

              // Filter Panel
              _buildFilterPanel(examProvider),

              const SizedBox(height: 16),

              // Exams List
              Expanded(
                child: examProvider.exams.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: examProvider.exams.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final exam = examProvider.exams[index];
                          return _buildExamCard(context, exam, examProvider);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Metrics Summary
  Widget _buildMetricsSummaryRow(ExamProvider provider) {
    final total = provider.exams.length;
    final active = provider.exams.where((e) => e.status == 'FAOL').length;
    final planned = provider.exams.where((e) => e.status == 'REJALASHTIRILGAN').length;

    return Row(
      children: [
        Expanded(child: _buildMetricChip('BARCHA IMTIHONLAR', '$total ta', Icons.quiz_outlined, AppColors.goldPrimary)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricChip('FAOL SEANSLAR', '$active ta', Icons.play_circle_outline, AppColors.emeraldAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricChip('REJALASHTIRILGAN', '$planned ta', Icons.schedule, const Color(0xFF0EA5E9))),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: AppColors.textMuted)),
              Text(value, style: AppTextStyles.bodyText.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  // MULTI-CRITERIA FILTER PANEL
  Widget _buildFilterPanel(ExamProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
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
                  Text('IMTIHONLARNI SARALASH VA QIDIRISH', style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.goldPrimary)),
                ],
              ),
              if (provider.hasActiveFilters)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 16, color: AppColors.error),
                  label: Text('TOZALASH', style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _searchController.clear();
                    provider.resetFilters();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.setSearchQuery(val),
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Imtihon nomi yoki guruh bo\'yicha qidirish...',
                    hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.goldPrimary, size: 20),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.goldPrimary)),
                  ),
                ),
              ),

              // Bosqich Filter
              _buildFilterDropdown(
                hint: 'Bosqich: Barchasi',
                value: provider.selectedBosqichFilter,
                items: provider.bosqichlarMap.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))))
                    .toList(),
                onChanged: (val) => provider.setBosqichFilter(val),
              ),

              // Guruh Filter
              _buildFilterDropdown(
                hint: 'Guruh: Barchasi',
                value: provider.selectedGuruhFilter,
                items: provider.rawGuruhlar
                    .where((g) => g.id != null && (provider.selectedBosqichFilter == null || g.bosqich?.id == provider.selectedBosqichFilter))
                    .map((g) => DropdownMenuItem(value: g.id!, child: Text(g.name ?? 'Guruh', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))))
                    .toList(),
                onChanged: (val) => provider.setGuruhFilter(val),
              ),

              // Test Filter (FIXED: calls setTestFilter)
              _buildFilterDropdown(
                hint: 'Test: Barchasi',
                value: provider.selectedTestFilter,
                items: provider.testsMap.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))))
                    .toList(),
                onChanged: (val) => provider.setTestFilter(val),
              ),

              // Status Filter
              _buildFilterDropdown(
                hint: 'Status: Barchasi',
                value: provider.selectedStatusFilter,
                items: provider.statusList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))))
                    .toList(),
                onChanged: (val) => provider.setStatusFilter(val),
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
            DropdownMenuItem<String?>(value: null, child: Text('$hint (Barchasi)', style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
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
          Icon(Icons.notes_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('Imtihon seanslari topilmadi', style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Yangi imtihon yaratish uchun "+ YANGI IMTIHON YARATISH" tugmasini bosing', style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamModel exam, ExamProvider provider) {
    final guruhName = exam.guruh?.name ?? provider.guruhlarMap[exam.guruhId] ?? exam.guruhId;
    final bosqichName = exam.guruh?.bosqich?.name;

    return Container(
      padding: const EdgeInsets.all(20),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_late_outlined, color: AppColors.goldPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.name ?? 'Imtihon', style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        'Guruh: $guruhName ${bosqichName != null ? "($bosqichName)" : ""}',
                        style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),

              Row(
                children: [
                  _buildStatusBadge(exam.status),
                  const SizedBox(width: 8),
                  if (exam.active && exam.status == 'FAOL')
                    IconButton(
                      icon: const Icon(Icons.pause_circle_outline, color: AppColors.warning, size: 20),
                      tooltip: 'Imtihonni to\'xtatish',
                      onPressed: () => _confirmDisableDialog(context, exam.id, provider),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.goldPrimary, size: 20),
                    tooltip: 'Tahrirlash',
                    onPressed: () => _showExamFormDialog(context, exam),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    tooltip: 'O\'chirish',
                    onPressed: () => _confirmDeleteDialog(context, exam.id, provider),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          // Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(Icons.timer_outlined, 'Vaqt: ${exam.durationMinutes} min', AppColors.goldPrimary),
              _buildBadge(Icons.help_outline, 'Savollar: ${exam.questionCount} ta', AppColors.emeraldAccent),
              _buildBadge(Icons.loop, 'Urinishlar: ${exam.maxAttempts} ta', const Color(0xFF0EA5E9)),
              _buildBadge(Icons.play_arrow_outlined, 'Status: ${exam.active ? "FAOL" : "NOFAOL"}', AppColors.info),
              if (exam.combinedTestIds != null && exam.combinedTestIds!.isNotEmpty)
                _buildBadge(Icons.merge_type, 'Birlashgan: ${exam.combinedTestIds!.length} ta test', AppColors.goldPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.goldPrimary;
    if (status == 'FAOL') color = AppColors.emeraldAccent;
    if (status == 'YAKUNLANGAN') color = AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(status, style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: color)),
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

  // CREATE / EDIT EXAM FORM DIALOG
  void _showExamFormDialog(BuildContext context, ExamModel? examToEdit) {
    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    final testProvider = Provider.of<TestProvider>(context, listen: false);

    final nameController = TextEditingController(text: examToEdit?.name ?? '');
    final durationController = TextEditingController(text: (examToEdit?.durationMinutes ?? 20).toString());
    final questionCountController = TextEditingController(text: (examToEdit?.questionCount ?? 5).toString());
    final maxAttemptsController = TextEditingController(text: (examToEdit?.maxAttempts ?? 20).toString());

    List<TestModel> allTests = testProvider.tests.isNotEmpty ? testProvider.tests : examProvider.rawTests;
    final allGuruhs = examProvider.rawGuruhlar;
    final allBosqichs = examProvider.rawBosqichlar;

    String? selectedTestId = examToEdit?.testId;
    if (selectedTestId == null || !allTests.any((t) => t.id == selectedTestId)) {
      selectedTestId = allTests.isNotEmpty ? allTests.first.id : null;
    }

    String? selectedGuruhId = examToEdit?.guruhId;
    if (selectedGuruhId == null || !allGuruhs.any((g) => g.id == selectedGuruhId)) {
      selectedGuruhId = allGuruhs.isNotEmpty ? allGuruhs.first.id : null;
    }

    String? selectedBosqichId = allGuruhs
        .firstWhere((g) => g.id == selectedGuruhId, orElse: () => GuruhModel())
        .bosqich
        ?.id;
    if (selectedBosqichId == null && allBosqichs.isNotEmpty) {
      selectedBosqichId = allBosqichs.first.id;
    }

    // Combined Test IDs selection state
    Set<String> selectedCombinedTestIds = {};
    if (examToEdit?.combinedTestIds != null && examToEdit!.combinedTestIds!.isNotEmpty) {
      selectedCombinedTestIds = Set.from(examToEdit.combinedTestIds!);
    } else if (selectedTestId != null && selectedTestId.isNotEmpty) {
      selectedCombinedTestIds = {selectedTestId};
    }

    // Dialog level filters
    String? dialogFanId;
    String? dialogKafedraId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredGuruhlar = allGuruhs
              .where((g) => g.id != null && (selectedBosqichId == null || g.bosqich?.id == selectedBosqichId))
              .toList();

          if (selectedGuruhId == null || !filteredGuruhlar.any((g) => g.id == selectedGuruhId)) {
            selectedGuruhId = filteredGuruhlar.isNotEmpty ? filteredGuruhlar.first.id : null;
          }

          // Compute names of selected tests for the dropdown button text
          final selectedTestNames = allTests
              .where((t) => selectedCombinedTestIds.contains(t.id))
              .map((t) => t.name)
              .toList();

          final primaryTestId = selectedCombinedTestIds.isNotEmpty
              ? selectedCombinedTestIds.first
              : (selectedTestId ?? '');

          final combinedList = selectedCombinedTestIds.toList();

          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
            ),
            title: Row(
              children: [
                Icon(
                  examToEdit == null ? Icons.note_add_outlined : Icons.edit_note,
                  color: AppColors.goldPrimary,
                ),
                const SizedBox(width: 10),
                Text(
                  examToEdit == null ? 'YANGI IMTIHON YARATISH' : 'IMTIHONNI TAHRIRLASH',
                  style: AppTextStyles.titleHeader.copyWith(fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFormLabel('IMTIHON NOMI (NAME)'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Masalan: Yagona birlashgan fanlar bo\'yicha imtihon'),
                    ),
                    const SizedBox(height: 14),

                    // BOSQICH & GURUH SELECTOR ROW
                    Row(
                      children: [
                        // BOSQICH SELECTOR
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('BOSQICH (KURS)'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: selectedBosqichId,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    hint: const Text('Bosqich tanlang', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    items: allBosqichs.map((b) {
                                      return DropdownMenuItem<String?>(
                                        value: b.id,
                                        child: Text(b.name ?? 'Bosqich', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setModalState(() {
                                        selectedBosqichId = val;
                                        final newFiltered = allGuruhs
                                            .where((g) => g.id != null && (val == null || g.bosqich?.id == val))
                                            .toList();
                                        selectedGuruhId = newFiltered.isNotEmpty ? newFiltered.first.id : null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // GURUH SELECTOR
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('GURUH'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: selectedGuruhId,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    hint: const Text('Guruh tanlang', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    items: filteredGuruhlar.map((g) {
                                      return DropdownMenuItem<String?>(
                                        value: g.id,
                                        child: Text(
                                          '${g.name ?? "Guruh"} ${g.bosqich?.name != null ? "(${g.bosqich?.name})" : ""}',
                                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedGuruhId = val);
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

                    // MULTI-SELECT TEST DROPDOWN BUTTON FIELD
                    _buildFormLabel('TESTLARNI TANLANG VA BIRLASHTIRING'),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final updated = await _showMultiSelectTestPickerModal(
                          context: context,
                          testProvider: testProvider,
                          allTests: allTests,
                          initialSelectedIds: selectedCombinedTestIds,
                          initialFanId: dialogFanId,
                          initialKafedraId: dialogKafedraId,
                        );
                        if (updated != null) {
                          setModalState(() {
                            selectedCombinedTestIds = updated.selectedTestIds;
                            dialogFanId = updated.fanId;
                            dialogKafedraId = updated.kafedraId;
                            if (updated.testsList.isNotEmpty) {
                              allTests = updated.testsList;
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedCombinedTestIds.isNotEmpty
                                ? AppColors.goldPrimary
                                : AppColors.cardBorder,
                            width: selectedCombinedTestIds.isNotEmpty ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.playlist_add_check, color: AppColors.goldPrimary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedCombinedTestIds.isEmpty
                                    ? 'Testlarni tanlang (Multi-select dropdown)...'
                                    : '${selectedCombinedTestIds.length} ta test tanlandi: ${selectedTestNames.join(", ")}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selectedCombinedTestIds.isNotEmpty
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: selectedCombinedTestIds.isNotEmpty
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppColors.goldPrimary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('DAVOMIYLIGI (MINUT)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: durationController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('20'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('SAVOLLAR SONI'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: questionCountController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('5'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('MAX URINISH'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: maxAttemptsController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('20'),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                onPressed: () async {
                  if (primaryTestId.isEmpty || selectedGuruhId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kamida bitta Test va Guruh tanlanishi shart!'), backgroundColor: AppColors.error),
                    );
                    return;
                  }

                  final name = nameController.text.trim();
                  final duration = int.tryParse(durationController.text.trim()) ?? 20;
                  final count = int.tryParse(questionCountController.text.trim()) ?? 5;
                  final attempts = int.tryParse(maxAttemptsController.text.trim()) ?? 20;

                  final newExam = ExamModel(
                    id: examToEdit?.id ?? '',
                    name: name.isEmpty ? 'Imtihon' : name,
                    testId: primaryTestId,
                    guruhId: selectedGuruhId!,
                    durationMinutes: duration,
                    questionCount: count,
                    maxAttempts: attempts,
                    status: 'FAOL',
                    combinedTestIds: combinedList.isNotEmpty ? combinedList : null,
                  );

                  if (examToEdit == null) {
                    await examProvider.createExam(newExam);
                  } else {
                    await examProvider.updateExam(newExam);
                  }

                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: Text(examToEdit == null ? 'YARATISH' : 'SAQLASH'),
              ),
            ],
          );
        },
      ),
    );
  }

  // MULTI-SELECT TEST PICKER MODAL (GET /api/tests?fanId=...&kafedraId=...)
  Future<_MultiTestPickerResult?> _showMultiSelectTestPickerModal({
    required BuildContext context,
    required TestProvider testProvider,
    required List<TestModel> allTests,
    required Set<String> initialSelectedIds,
    String? initialFanId,
    String? initialKafedraId,
  }) {
    Set<String> tempSelectedIds = Set.from(initialSelectedIds);
    String? fanFilter = initialFanId;
    String? kafedraFilter = initialKafedraId;
    String searchQuery = '';
    bool isFetching = false;
    List<TestModel> currentDisplayTests = List.from(allTests);

    return showDialog<_MultiTestPickerResult>(
      context: context,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setPickerState) {
          Future<void> reloadFilteredTests() async {
            setPickerState(() => isFetching = true);
            final fetched = await testProvider.fetchTestsFiltered(
              fanId: fanFilter,
              kafedraId: kafedraFilter,
            );
            setPickerState(() {
              currentDisplayTests = fetched;
              isFetching = false;
            });
          }

          final visibleTests = currentDisplayTests.where((t) {
            final matchesSearch = searchQuery.isEmpty ||
                t.name.toLowerCase().contains(searchQuery.toLowerCase());
            return matchesSearch;
          }).toList();

          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.playlist_add_check, color: AppColors.goldPrimary),
                    const SizedBox(width: 10),
                    Text(
                      'TESTLARNI TANLANG VA BIRLASHTIRING',
                      style: AppTextStyles.titleHeader.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                Text(
                  '${tempSelectedIds.length} ta tanlandi',
                  style: AppTextStyles.badgeText.copyWith(color: AppColors.goldPrimary, fontSize: 12),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              height: 480,
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    onChanged: (val) => setPickerState(() => searchQuery = val),
                    style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Test nomini qidirish...').copyWith(
                      prefixIcon: const Icon(Icons.search, color: AppColors.goldPrimary, size: 20),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Fan & Kafedra Filter Dropdowns
                  Row(
                    children: [
                      // FAN FILTER
                      Expanded(
                        child: _buildDropdownContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: fanFilter,
                              dropdownColor: AppColors.cardDark,
                              isExpanded: true,
                              hint: const Text('Barcha fanlar', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('Barcha fanlar', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                                ...testProvider.fans.entries.map((e) => DropdownMenuItem<String?>(
                                      value: e.key,
                                      child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                    )),
                              ],
                              onChanged: (val) {
                                fanFilter = val;
                                reloadFilteredTests();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // KAFEDRA FILTER
                      Expanded(
                        child: _buildDropdownContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: kafedraFilter,
                              dropdownColor: AppColors.cardDark,
                              isExpanded: true,
                              hint: const Text('Barcha kafedralar', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('Barcha kafedralar', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                                ...testProvider.kafedras.entries.map((e) => DropdownMenuItem<String?>(
                                      value: e.key,
                                      child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                    )),
                              ],
                              onChanged: (val) {
                                kafedraFilter = val;
                                reloadFilteredTests();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jami: ${visibleTests.length} ta test topildi',
                        style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setPickerState(() {
                                for (var t in visibleTests) {
                                  tempSelectedIds.add(t.id);
                                }
                              });
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: const Text('BARCHASINI BELGILASH', style: TextStyle(fontSize: 11, color: AppColors.goldPrimary)),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setPickerState(() => tempSelectedIds.clear());
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: const Text('TOZALASH', style: TextStyle(fontSize: 11, color: AppColors.error)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Tests Checklist
                  Expanded(
                    child: isFetching
                        ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
                        : visibleTests.isEmpty
                            ? const Center(
                                child: Text('Testlar topilmadi', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: ListView.separated(
                                  itemCount: visibleTests.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.cardBorder),
                                  itemBuilder: (context, index) {
                                    final test = visibleTests[index];
                                    final isChecked = tempSelectedIds.contains(test.id);
                                    final fanName = testProvider.fans[test.fanId] ?? '';

                                    return CheckboxListTile(
                                      dense: true,
                                      value: isChecked,
                                      activeColor: AppColors.goldPrimary,
                                      checkColor: AppColors.backgroundDark,
                                      title: Text(
                                        test.name,
                                        style: TextStyle(
                                          color: isChecked ? AppColors.goldPrimary : AppColors.textPrimary,
                                          fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: fanName.isNotEmpty
                                          ? Text('Fan: $fanName', style: const TextStyle(color: AppColors.textMuted, fontSize: 11))
                                          : null,
                                      onChanged: (val) {
                                        setPickerState(() {
                                          if (val == true) {
                                            tempSelectedIds.add(test.id);
                                          } else {
                                            tempSelectedIds.remove(test.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(modalContext).pop(),
                child: Text('BEKOR QILISH', style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: AppColors.backgroundDark,
                ),
                onPressed: () {
                  Navigator.of(modalContext).pop(
                    _MultiTestPickerResult(
                      selectedTestIds: tempSelectedIds,
                      fanId: fanFilter,
                      kafedraId: kafedraFilter,
                      testsList: currentDisplayTests,
                    ),
                  );
                },
                child: Text('TAYYOR (${tempSelectedIds.length})'),
              ),
            ],
          );
        },
      ),
    );
  }

  // CONFIRM DISABLE DIALOG (PATCH /api/exams/{id}/disable)
  void _confirmDisableDialog(BuildContext context, String id, ExamProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Row(
          children: [
            const Icon(Icons.pause_circle_outline, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('IMTIHONNI TO\'XTATISH', style: AppTextStyles.titleHeader.copyWith(color: AppColors.warning, fontSize: 16)),
          ],
        ),
        content: Text(
          'Imtihon seansini to\'xtatishni va talabalar uchun yopishni tasdiqlaysizmi?',
          style: AppTextStyles.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('BEKOR QILISH'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: AppColors.backgroundDark),
            onPressed: () async {
              final success = await provider.disableExam(id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Imtihon muvaffaqiyatli to'xtatildi va talabalar uchun yopildi"
                          : "Imtihonni to'xtatishda xatolik yuz berdi!",
                    ),
                    backgroundColor: success ? AppColors.emeraldAccent : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('TO\'XTATISH'),
          ),
        ],
      ),
    );
  }

  // CONFIRM DELETE DIALOG (DELETE /api/exams/{id})
  void _confirmDeleteDialog(BuildContext context, String id, ExamProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('IMTIHONNI O\'CHIRISH', style: AppTextStyles.titleHeader.copyWith(color: AppColors.error)),
        content: Text('Haqiqatan ham ushbu imtihon seansini o\'chirib tashlamoqchimisiz?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('BEKOR QILISH')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await provider.deleteExam(id);
              if (context.mounted) Navigator.of(context).pop();
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _MultiTestPickerResult {
  final Set<String> selectedTestIds;
  final String? fanId;
  final String? kafedraId;
  final List<TestModel> testsList;

  _MultiTestPickerResult({
    required this.selectedTestIds,
    this.fanId,
    this.kafedraId,
    required this.testsList,
  });
}
