import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/exam_model.dart';
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

              // Filter Portal
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
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

  // Filter Panel
  Widget _buildFilterPanel(ExamProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
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
                  const Icon(Icons.filter_list, color: AppColors.goldPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text('FILTRLASH', style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.goldPrimary)),
                ],
              ),
              if (provider.hasActiveFilters)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 14, color: AppColors.error),
                  label: Text('TOZALASH', style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _searchController.clear();
                    provider.resetFilters();
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.setSearchQuery(val),
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Imtihon nomi bo\'yicha qidirish...',
                    hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: AppColors.goldPrimary, size: 18),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.goldPrimary)),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Guruh Dropdown Filter
              _buildFilterDropdown(
                hint: 'Guruh: Barchasi',
                value: provider.selectedGuruhFilter,
                items: provider.guruhlarMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => provider.setGuruhFilter(val),
              ),
              const SizedBox(width: 10),

              // Status Dropdown Filter
              _buildFilterDropdown(
                hint: 'Status: Barchasi',
                value: provider.selectedStatusFilter,
                items: provider.statusList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
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
          Icon(Icons.quiz_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('Hech qanday imtihon topilmadi', style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Yangi imtihon yaratish uchun "+ YANGI IMTIHON YARATISH" tugmasini bosing', style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamModel exam, ExamProvider provider) {
    final testName = provider.testsMap[exam.testId] ?? exam.testId;
    final guruhName = provider.guruhlarMap[exam.guruhId] ?? exam.guruhId;

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
                    child: const Icon(Icons.assignment_late_outlined, color: AppColors.goldPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.name, style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Test: $testName • Guruh: $guruhName', style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),

              Row(
                children: [
                  _buildStatusBadge(exam.status),
                  const SizedBox(width: 8),
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

          // Badges & Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildBadge(Icons.timer_outlined, 'Vaqt: ${exam.durationMinutes} min', AppColors.goldPrimary),
                  _buildBadge(Icons.help_outline, 'Savollar: ${exam.questionCount} ta', AppColors.emeraldAccent),
                  _buildBadge(Icons.loop, 'Urinishlar: ${exam.maxAttempts} ta', const Color(0xFF0EA5E9)),
                  _buildBadge(Icons.vpn_key_outlined, 'TestID: ${exam.testId.substring(0, 8)}...', AppColors.info),
                ],
              ),

              OutlinedButton.icon(
                icon: const Icon(Icons.code_outlined, size: 16, color: AppColors.goldPrimary),
                label: Text('JSON SO\'ROVINI KO\'RISH', style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.goldPrimary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.goldPrimary),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _showJsonPayloadModal(context, exam),
              ),
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

    final nameController = TextEditingController(text: examToEdit?.name ?? 'Matematika fanidan 1-oraliq nazorat imtihoni');
    final durationController = TextEditingController(text: (examToEdit?.durationMinutes ?? 20).toString());
    final questionCountController = TextEditingController(text: (examToEdit?.questionCount ?? 5).toString());
    final maxAttemptsController = TextEditingController(text: (examToEdit?.maxAttempts ?? 20).toString());

    String selectedTestId = examToEdit?.testId ?? examProvider.testsMap.keys.first;
    String selectedGuruhId = examToEdit?.guruhId ?? examProvider.guruhlarMap.keys.first;
    String selectedStatus = examToEdit?.status ?? 'FAOL';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentApiJson = {
            "testId": selectedTestId,
            "guruhId": selectedGuruhId,
            "durationMinutes": int.tryParse(durationController.text) ?? 20,
            "questionCount": int.tryParse(questionCountController.text) ?? 5,
            "maxAttempts": int.tryParse(maxAttemptsController.text) ?? 20,
          };

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
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFormLabel('IMTIHON NOMI'),
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
                              _buildFormLabel('TESTNI TANLANG (testId)'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: examProvider.testsMap.containsKey(selectedTestId) ? selectedTestId : examProvider.testsMap.keys.first,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: examProvider.testsMap.entries.map((e) {
                                      return DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedTestId = val);
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
                              _buildFormLabel('GURUHNINI TANLANG (guruhId)'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: examProvider.guruhlarMap.containsKey(selectedGuruhId) ? selectedGuruhId : examProvider.guruhlarMap.keys.first,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: examProvider.guruhlarMap.entries.map((e) {
                                      return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
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

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('DAVOMIYLIGI (durationMinutes)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: durationController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('20'),
                                onChanged: (val) => setModalState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('SAVOLLAR SONI (questionCount)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: questionCountController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('5'),
                                onChanged: (val) => setModalState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('MAX URINISH (maxAttempts)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: maxAttemptsController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('20'),
                                onChanged: (val) => setModalState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 10),

                    // GENERATED API JSON PREVIEW
                    _buildFormLabel('GENERATSIYA QILINGAN JSON SO\'ROVI (API PAYLOAD):'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(currentApiJson),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.goldPrimary),
                      ),
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
                  final duration = int.tryParse(durationController.text.trim()) ?? 20;
                  final count = int.tryParse(questionCountController.text.trim()) ?? 5;
                  final attempts = int.tryParse(maxAttemptsController.text.trim()) ?? 20;

                  if (name.isEmpty) return;

                  final newExam = ExamModel(
                    id: examToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    testId: selectedTestId,
                    guruhId: selectedGuruhId,
                    durationMinutes: duration,
                    questionCount: count,
                    maxAttempts: attempts,
                    status: selectedStatus,
                  );

                  if (examToEdit == null) {
                    examProvider.addExam(newExam);
                  } else {
                    examProvider.updateExam(newExam);
                  }

                  Navigator.of(dialogContext).pop();
                },
                child: Text(examToEdit == null ? 'YARATISH' : 'SAQLASH'),
              ),
            ],
          );
        },
      ),
    );
  }

  // JSON PAYLOAD MODAL
  void _showJsonPayloadModal(BuildContext context, ExamModel exam) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(exam.toApiRequestJson());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.goldPrimary)),
        title: Row(
          children: [
            const Icon(Icons.code_outlined, color: AppColors.goldPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text('${exam.name} — API JSON SO\'ROVI', style: AppTextStyles.titleHeader.copyWith(fontSize: 15))),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Serverga yuboriladigan aniq JSON ob\'ekti:', style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.goldPrimary),
                ),
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.goldPrimary),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.backgroundDark),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('YOPISH'),
          ),
        ],
      ),
    );
  }

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
            onPressed: () {
              provider.deleteExam(id);
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
