import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/edu_plan_model.dart';
import '../../providers/catalog_provider.dart';
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
                'O\'QUV REJALARI VA FILTRLASH (EDU PLAN CRUD)',
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
              ),
              Text(
                'O\'quv yili, kafedra va fanlar bo\'yicha rejalar katalogi hamda Excel importi',
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

          Row(
            children: [
              Expanded(
                child: TextField(
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
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 1. Fan Filter
              _buildFilterDropdown(
                hint: 'Fan: Barchasi',
                value: provider.selectedFanFilter,
                items: provider.fans.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => provider.setFanFilter(val),
              ),

              const SizedBox(width: 12),

              // 2. Kafedra Filter
              _buildFilterDropdown(
                hint: 'Kafedra: Barchasi',
                value: provider.selectedKafedraFilter,
                items: provider.kafedras.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => provider.setKafedraFilter(val),
              ),

              const SizedBox(width: 12),

              // 3. O'quv Yili Filter
              _buildFilterDropdown(
                hint: 'O\'quv Yili: Barchasi',
                value: provider.selectedOquvYiliFilter,
                items: provider.oquvYillari.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                onChanged: (val) => provider.setOquvYiliFilter(val),
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

  // CREATE / EDIT EDU PLAN DIALOG (EXCEL .xlsx & JSON PARSER INTEGRATED)
  void _showEduPlanFormDialog(BuildContext context, EduPlanModel? planToEdit) {
    final eduPlanProvider = Provider.of<EduPlanProvider>(context, listen: false);
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);

    final nameController = TextEditingController(text: planToEdit?.name ?? '');
    String selectedOquvYili = planToEdit?.oquvYili ?? (eduPlanProvider.oquvYillari.isNotEmpty ? eduPlanProvider.oquvYillari.first : '2025-2026');
    final jsonImportController = TextEditingController();

    String selectedFanId = planToEdit?.fanId ??
        (catalogProvider.fanlar.isNotEmpty ? catalogProvider.fanlar.first.id! : eduPlanProvider.fans.keys.first);

    String selectedKafedraId = planToEdit?.kafedraId ??
        (catalogProvider.kafedralar.isNotEmpty ? catalogProvider.kafedralar.first.id! : eduPlanProvider.kafedras.keys.first);

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
                  planToEdit == null ? 'YANGI O\'QUV REJA YARATISH (/api/edu-plans)' : 'O\'QUV REJANI TAHRIRLASH',
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
                    _buildFormLabel('O\'QUV REJA NOMI (NAME)'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Masalan: INFORMATIKA VA AXBOROT TEXNOLOGIYALARI'),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        // FAN DROPDOWN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('FAN (fanId)'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedFanId,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: catalogProvider.fanlar.map((f) {
                                      return DropdownMenuItem<String>(value: f.id!, child: Text(f.name ?? 'Fan', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                    }).toList()..addAll(
                                      eduPlanProvider.fans.entries.where((e) => !catalogProvider.fanlar.any((f) => f.id == e.key)).map((e) {
                                        return DropdownMenuItem<String>(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                      })
                                    ),
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

                        // KAFEDRA DROPDOWN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('KAFEDRA (kafedraId)'),
                              const SizedBox(height: 4),
                              _buildDropdownContainer(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedKafedraId,
                                    dropdownColor: AppColors.cardDark,
                                    isExpanded: true,
                                    items: catalogProvider.kafedralar.map((k) {
                                      return DropdownMenuItem<String>(value: k.id!, child: Text(k.name ?? 'Kafedra', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                    }).toList()..addAll(
                                      eduPlanProvider.kafedras.entries.where((e) => !catalogProvider.kafedralar.any((k) => k.id == e.key)).map((e) {
                                        return DropdownMenuItem<String>(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                      })
                                    ),
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

                    _buildFormLabel('O\'QUV YILI (oquvYili)'),
                    const SizedBox(height: 4),
                    _buildDropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: eduPlanProvider.oquvYillari.contains(selectedOquvYili) ? selectedOquvYili : (eduPlanProvider.oquvYillari.isNotEmpty ? eduPlanProvider.oquvYillari.first : '2025-2026'),
                          dropdownColor: AppColors.cardDark,
                          isExpanded: true,
                          items: eduPlanProvider.oquvYillari.map((val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedOquvYili = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 10),

                    // EXCEL (.xlsx) AND JSON IMPORT SECTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFormLabel('MAVZULAR FAYLI (EXCEL .xlsx / JSON IMPORT)'),
                        Text('${currentTopics.length} ta mavzu yuklangan', style: AppTextStyles.badgeText.copyWith(color: const Color(0xFF14B8A6))),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // NATIVE FILE PICKER BUTTON FOR EXCEL (.xlsx)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
                      label: const Text('📂 KOMPYUTERDAN EXCEL (.xlsx) FAYLNI TANLASH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: AppColors.backgroundDark,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () async {
                        try {
                          final PlatformFile? file = await FilePicker.pickFile(
                            type: FileType.custom,
                            allowedExtensions: ['xlsx', 'xls', 'json'],
                          );

                          if (file != null) {
                            if (file.name.endsWith('.xlsx') || file.name.endsWith('.xls')) {
                              // Read Excel Bytes
                              final bytes = file.path != null && file.path!.isNotEmpty
                                  ? await File(file.path!).readAsBytes()
                                  : await file.readAsBytes();

                              final parsed = eduPlanProvider.parseTopicsFromExcelBytes(bytes);
                              final extractedTitle = parsed['title'] as String? ?? '';
                              final extractedTopics = parsed['topics'] as List<EduPlanTopicModel>? ?? [];

                              setModalState(() {
                                if (extractedTitle.isNotEmpty && nameController.text.isEmpty) {
                                  nameController.text = extractedTitle;
                                }
                                currentTopics = extractedTopics;
                              });

                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    content: Text('✔ Excel faylidan ${extractedTopics.length} ta mavzu va reja nomi muvaffaqiyatli o\'qindi!'),
                                    backgroundColor: const Color(0xFF14B8A6),
                                  ),
                                );
                              }
                            } else if (file.name.endsWith('.json')) {
                              final jsonStr = file.path != null && file.path!.isNotEmpty
                                  ? await File(file.path!).readAsString()
                                  : utf8.decode(await file.readAsBytes());

                              jsonImportController.text = jsonStr;
                              final parsedTopics = eduPlanProvider.parseTopicsFromJson(jsonStr);

                              setModalState(() {
                                currentTopics = parsedTopics;
                              });

                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    content: Text('✔ JSON faylidan ${parsedTopics.length} ta mavzu muvaffaqiyatli o\'qindi!'),
                                    backgroundColor: const Color(0xFF14B8A6),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Faylni o\'qishda xatolik: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: jsonImportController,
                      maxLines: 3,
                      style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textPrimary, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Yoki JSON matnini bu yerga joylashtiring...',
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
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final newPlan = EduPlanModel(
                    id: planToEdit?.id ?? '',
                    name: name,
                    fanId: selectedFanId,
                    kafedraId: selectedKafedraId,
                    oquvYili: selectedOquvYili,
                    topics: currentTopics,
                  );

                  if (planToEdit == null) {
                    await eduPlanProvider.createEduPlan(newPlan);
                  } else {
                    await eduPlanProvider.updateEduPlan(newPlan);
                  }

                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
                            child: Text('T/R ${t.tr}', style: AppTextStyles.badgeText.copyWith(color: const Color(0xFF14B8A6))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('Turi: ${t.type} • ${t.soat} soat', style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted)),
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
            onPressed: () async {
              await provider.deleteEduPlan(id);
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
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
