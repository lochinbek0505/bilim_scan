import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/edu_plan_model.dart';
import '../../providers/edu_plan_provider.dart';

class EduPlanManagementScreen extends StatefulWidget {
  const EduPlanManagementScreen({super.key});

  @override
  State<EduPlanManagementScreen> createState() => _EduPlanManagementScreenState();
}

class _EduPlanManagementScreenState extends State<EduPlanManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eduPlanProvider = Provider.of<EduPlanProvider>(context);

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
                'O\'QUV REJALARI VA FILTRLASH',
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
              ),
              Text(
                'O\'quv yili, oyi, kafedra va fanlar bo\'yicha rejalar katalogi',
                style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_chart, size: 18, color: AppColors.backgroundDark),
                label: Text('YANGI O\'QUV REJA', style: AppTextStyles.buttonText.copyWith(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => _showEduPlanFormDialog(context, null),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // MULTI-CRITERIA FILTER PANEL
              _buildFilterPanel(eduPlanProvider),

              const SizedBox(height: 16),

              // Edu Plans List
              Expanded(
                child: eduPlanProvider.eduPlans.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: eduPlanProvider.eduPlans.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final plan = eduPlanProvider.eduPlans[index];
                          return _buildEduPlanCard(context, plan, eduPlanProvider);
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
  Widget _buildFilterPanel(EduPlanProvider provider) {
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
                  const Icon(Icons.filter_alt_outlined, color: Color(0xFF14B8A6), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'O\'QUV REJA FILTRLASH PORTALI',
                    style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: const Color(0xFF14B8A6)),
                  ),
                ],
              ),
              if (provider.hasActiveFilters)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 16, color: AppColors.error),
                  label: Text('FILTRLARNI TOZALASH', style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    _searchController.clear();
                    provider.resetFilters();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => provider.setSearchQuery(val),
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'O\'quv reja nomi bo\'yicha kalit so\'z kiriting...',
              hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF14B8A6), size: 20),
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF14B8A6)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Dropdowns Row (Fan, Kafedra, O'quv Yili, O'quv Oyi)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // 1. Fan Filter
              _buildFilterDropdown(
                hint: 'Fan: Barchasi',
                value: provider.selectedFanFilter,
                items: provider.fans.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => provider.setFanFilter(val),
              ),

              // 2. Kafedra Filter
              _buildFilterDropdown(
                hint: 'Kafedra: Barchasi',
                value: provider.selectedKafedraFilter,
                items: provider.kafedras.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => provider.setKafedraFilter(val),
              ),

              // 3. O'quv Yili Filter
              _buildFilterDropdown(
                hint: 'O\'quv Yili: Barchasi',
                value: provider.selectedOquvYiliFilter,
                items: provider.oquvYillari.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => provider.setOquvYiliFilter(val),
              ),

              // 4. O'quv Oyi Filter
              _buildFilterDropdown(
                hint: 'O\'quv Oyi: Barchasi',
                value: provider.selectedOquvOyiFilter,
                items: provider.oquvOylari.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => provider.setOquvOyiFilter(val),
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
        border: Border.all(color: value != null ? const Color(0xFF14B8A6) : AppColors.cardBorder),
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
          Text('Kiritilgan filtrlar bo\'yicha o\'quv reja topilmadi', style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Filtr sozlamalarini o\'zgartiring yoki "FILTRLARNI TOZALASH" tugmasini bosing', style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildEduPlanCard(BuildContext context, EduPlanModel plan, EduPlanProvider provider) {
    final fanName = provider.fans[plan.fanId] ?? plan.fanId;
    final kafedraName = provider.kafedras[plan.kafedraId] ?? plan.kafedraId;

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
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF14B8A6), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('$kafedraName • $fanName', style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF14B8A6), size: 20),
                    tooltip: 'Tahrirlash',
                    onPressed: () => _showEduPlanFormDialog(context, plan),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    tooltip: 'O\'chirish',
                    onPressed: () => _confirmDeleteDialog(context, plan.id, provider),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          // Badges & Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBadge(Icons.calendar_today, 'O\'quv yili: ${plan.oquvYili}', AppColors.goldPrimary),
                  const SizedBox(width: 10),
                  _buildBadge(Icons.event_outlined, 'Oyi: ${plan.oquvOyi}', AppColors.emeraldAccent),
                  const SizedBox(width: 10),
                  _buildBadge(Icons.topic_outlined, '${plan.topics.length} ta mavzu', const Color(0xFF14B8A6)),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.list_alt_outlined, size: 16, color: Color(0xFF14B8A6)),
                label: Text('MAVZULARNI KO\'RISH (${plan.topics.length})', style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: const Color(0xFF14B8A6))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF14B8A6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _showTopicsViewerModal(context, plan),
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

  // CREATE / EDIT EDU PLAN DIALOG
  void _showEduPlanFormDialog(BuildContext context, EduPlanModel? planToEdit) {
    final eduPlanProvider = Provider.of<EduPlanProvider>(context, listen: false);

    final nameController = TextEditingController(text: planToEdit?.name ?? '');
    final oquvOyiController = TextEditingController(text: planToEdit?.oquvOyi ?? 'Sentyabr');
    final oquvYiliController = TextEditingController(text: planToEdit?.oquvYili ?? '2026-2027');
    final jsonImportController = TextEditingController();

    String selectedFanId = planToEdit?.fanId ?? eduPlanProvider.fans.keys.first;
    String selectedKafedraId = planToEdit?.kafedraId ?? eduPlanProvider.kafedras.keys.first;

    List<EduPlanTopicModel> currentTopics = planToEdit != null ? List.from(planToEdit.topics) : [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
            ),
            title: Row(
              children: [
                Icon(
                  planToEdit == null ? Icons.add_chart : Icons.edit_calendar,
                  color: const Color(0xFF14B8A6),
                ),
                const SizedBox(width: 10),
                Text(
                  planToEdit == null ? 'YANGI O\'QUV REJA YARATISH' : 'O\'QUV REJANI TAHRIRLASH',
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
                    _buildFormLabel('REJA NOMI'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Masalan: Matematika fanidan o\'quv rejasi'),
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
                                    items: eduPlanProvider.fans.entries.map((e) {
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
                                    items: eduPlanProvider.kafedras.entries.map((e) {
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
                              _buildFormLabel('O\'QUV OYI'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: oquvOyiController,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('Sentyabr'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('O\'QUV YILI'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: oquvYiliController,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('2026-2027'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 10),

                    // JSON Topics Import Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFormLabel('MAVZULAR FAYLI (JSON TOPICS)'),
                        Text('${currentTopics.length} ta mavzu yuklangan', style: AppTextStyles.badgeText.copyWith(color: const Color(0xFF14B8A6))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: jsonImportController,
                      maxLines: 4,
                      style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Mavzular JSON fayli kontentini joylashtiring...',
                        hintStyle: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: const Text('MAVZULAR FAYLINI PARSE QILISH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final rawJson = jsonImportController.text.trim();
                        if (rawJson.isNotEmpty) {
                          final parsed = eduPlanProvider.parseTopicsFromJson(rawJson);
                          if (parsed.isNotEmpty) {
                            setModalState(() {
                              currentTopics = parsed;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${parsed.length} ta mavzu muvaffaqiyatli yuklandi!'), backgroundColor: const Color(0xFF14B8A6)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('JSON formati noto\'g\'ri!'), backgroundColor: AppColors.error),
                            );
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6), foregroundColor: AppColors.backgroundDark),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final newPlan = EduPlanModel(
                    id: planToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    fanId: selectedFanId,
                    kafedraId: selectedKafedraId,
                    oquvOyi: oquvOyiController.text.trim(),
                    oquvYili: oquvYiliController.text.trim(),
                    topics: currentTopics,
                  );

                  if (planToEdit == null) {
                    eduPlanProvider.addEduPlan(newPlan);
                  } else {
                    eduPlanProvider.updateEduPlan(newPlan);
                  }

                  Navigator.of(dialogContext).pop();
                },
                child: Text(planToEdit == null ? 'YARATISH' : 'SAQLASH'),
              ),
            ],
          );
        },
      ),
    );
  }

  // TOPICS VIEWER MODAL
  void _showTopicsViewerModal(BuildContext context, EduPlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF14B8A6))),
        title: Row(
          children: [
            const Icon(Icons.list_alt_outlined, color: Color(0xFF14B8A6)),
            const SizedBox(width: 10),
            Expanded(child: Text('${plan.name} — MAVZULAR RO\'YXATI (${plan.topics.length} TA)', style: AppTextStyles.titleHeader.copyWith(fontSize: 15))),
          ],
        ),
        content: SizedBox(
          width: 580,
          height: 420,
          child: plan.topics.isEmpty
              ? Center(child: Text('Hozircha mavzular yuklanmagan.', style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)))
              : ListView.separated(
                  itemCount: plan.topics.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = plan.topics[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFF14B8A6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text('TR ${t.tr}', style: AppTextStyles.badgeText.copyWith(color: const Color(0xFF14B8A6))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${t.tur} • ${t.soat} soat', style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6), foregroundColor: AppColors.backgroundDark),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('YOPISH'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDialog(BuildContext context, String id, EduPlanProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('O\'QUV REJANI O\'CHIRISH', style: AppTextStyles.titleHeader.copyWith(color: AppColors.error)),
        content: Text('Haqiqatan ham ushbu o\'quv rejani o\'chirib tashlamoqchimisiz?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('BEKOR QILISH')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              provider.deleteEduPlan(id);
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
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
