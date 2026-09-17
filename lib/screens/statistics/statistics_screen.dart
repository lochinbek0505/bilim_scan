import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/catalog_response.dart';
import '../../models/fan_model.dart';
import '../../models/guruh_model.dart';
import '../../models/statistics_model.dart';
import '../../providers/catalog_provider.dart';
import '../../services/statistics_service.dart';

enum StatScope { lyceum, stage, group, subject }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statsService = StatisticsService();

  StatScope _selectedScope = StatScope.lyceum;
  bool _isLoading = false;

  // Catalog Selections
  CatalogResponse? _selectedStage;
  GuruhModel? _selectedGroup;
  FanModel? _selectedSubject;

  // Active Loaded Data
  ScopeStatisticsModel? _scopeData;
  GroupStatisticsModel? _groupData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProv = context.read<CatalogProvider>();
      catProv.fetchAllCatalogs();
      _loadLyceumStats();
    });
  }

  Future<void> _loadLyceumStats() async {
    setState(() => _isLoading = true);
    final data = await _statsService.getLyceumStatistics();
    if (mounted) {
      setState(() {
        _scopeData = data;
        _groupData = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStageStats(String stageId) async {
    setState(() => _isLoading = true);
    final data = await _statsService.getStageStatistics(stageId);
    if (mounted) {
      setState(() {
        _scopeData = data;
        _groupData = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGroupStats(String guruhId) async {
    setState(() => _isLoading = true);
    final data = await _statsService.getGroupStatistics(guruhId);
    if (mounted) {
      setState(() {
        _groupData = data;
        _scopeData = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubjectStats(String subjectId) async {
    setState(() => _isLoading = true);
    final data = await _statsService.getSubjectStatistics(subjectId);
    if (mounted) {
      setState(() {
        _scopeData = data;
        _groupData = null;
        _isLoading = false;
      });
    }
  }

  void _onScopeChanged(StatScope newScope) {
    setState(() {
      _selectedScope = newScope;
    });

    final catProv = context.read<CatalogProvider>();

    if (newScope == StatScope.lyceum) {
      _loadLyceumStats();
    } else if (newScope == StatScope.stage) {
      if (_selectedStage == null && catProv.bosqichlar.isNotEmpty) {
        _selectedStage = catProv.bosqichlar.first;
      }
      if (_selectedStage?.id != null) {
        _loadStageStats(_selectedStage!.id!);
      }
    } else if (newScope == StatScope.group) {
      if (_selectedGroup == null && catProv.guruhlar.isNotEmpty) {
        _selectedGroup = catProv.guruhlar.first;
      }
      if (_selectedGroup?.id != null) {
        _loadGroupStats(_selectedGroup!.id!);
      }
    } else if (newScope == StatScope.subject) {
      if (_selectedSubject == null && catProv.fanlar.isNotEmpty) {
        _selectedSubject = catProv.fanlar.first;
      }
      if (_selectedSubject?.id != null) {
        _loadSubjectStats(_selectedSubject!.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: TacticalBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildScopeSelector(),
              _buildSubCategoryDropdown(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.goldPrimary),
                            SizedBox(height: 16),
                            Text(
                              'Statistika yuklanmoqda...',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildDashboardContent(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // APP BAR HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.goldPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIZIM STATISTIKASI DACHBORDI',
                  style: AppTextStyles.titleHeader.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Samarqand akademik litseyi bo\'yicha tahliliy hisobot va analitika',
                  style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.goldPrimary),
            onPressed: () => _onScopeChanged(_selectedScope),
            tooltip: 'Yangilash',
          ),
        ],
      ),
    );
  }

  // SCOPE SELECTOR ROW (LITSEY / BOSQICH / GURUH / FAN)
  Widget _buildScopeSelector() {
    return Container(
      color: AppColors.backgroundSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildScopeBtn(
              scope: StatScope.lyceum,
              label: '🏛️ LITSEY',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildScopeBtn(
              scope: StatScope.stage,
              label: '🎓 BOSQICH',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildScopeBtn(
              scope: StatScope.group,
              label: '👥 GURUH',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildScopeBtn(
              scope: StatScope.subject,
              label: '📚 FAN',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeBtn({
    required StatScope scope,
    required String label,
  }) {
    final isSelected = _selectedScope == scope;
    return InkWell(
      onTap: () => _onScopeChanged(scope),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary : AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // INLINE DROPDOWN SELECTOR FOR BOSQICH / GURUH / FAN
  Widget _buildSubCategoryDropdown() {
    if (_selectedScope == StatScope.lyceum) {
      return const SizedBox.shrink();
    }

    return Consumer<CatalogProvider>(
      builder: (context, catProv, child) {
        if (_selectedScope == StatScope.stage) {
          final list = catProv.bosqichlar;
          if (list.isEmpty) return const SizedBox.shrink();
          return Container(
            color: AppColors.cardDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('BOSQICHNI TANLANG: ', style: TextStyle(color: AppColors.goldPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppColors.cardDark,
                        value: _selectedStage?.id ?? (list.isNotEmpty ? list.first.id : null),
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        items: list.map((b) {
                          return DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(b.name ?? 'Bosqich'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final selected = list.firstWhere((e) => e.id == val);
                            setState(() => _selectedStage = selected);
                            _loadStageStats(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (_selectedScope == StatScope.group) {
          final list = catProv.guruhlar;
          if (list.isEmpty) return const SizedBox.shrink();
          return Container(
            color: AppColors.cardDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('GURUHNI TANLANG: ', style: TextStyle(color: AppColors.emeraldAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.emeraldAccent.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppColors.cardDark,
                        value: _selectedGroup?.id ?? (list.isNotEmpty ? list.first.id : null),
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        items: list.map((g) {
                          return DropdownMenuItem<String>(
                            value: g.id,
                            child: Text('${g.name ?? "Guruh"} (${g.bosqich?.name ?? ""})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final selected = list.firstWhere((e) => e.id == val);
                            setState(() => _selectedGroup = selected);
                            _loadGroupStats(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (_selectedScope == StatScope.subject) {
          final list = catProv.fanlar;
          if (list.isEmpty) return const SizedBox.shrink();
          return Container(
            color: AppColors.cardDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('FANNI TANLANG: ', style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppColors.cardDark,
                        value: _selectedSubject?.id ?? (list.isNotEmpty ? list.first.id : null),
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        items: list.map((f) {
                          return DropdownMenuItem<String>(
                            value: f.id,
                            child: Text(f.name ?? 'Fan'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final selected = list.firstWhere((e) => e.id == val);
                            setState(() => _selectedSubject = selected);
                            _loadSubjectStats(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // DASHBOARD CONTENT VIEW
  Widget _buildDashboardContent() {
    if (_selectedScope == StatScope.group && _groupData != null) {
      return _buildGroupDashboard(_groupData!);
    }

    final data = _scopeData;
    if (data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Statistika ma\'lumotlari topilmadi', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final double avgPct = (data.overallAveragePercentage ?? 0.0).toDouble();
    final num totalExams = data.totalExamsTaken ?? 0;
    final num totalStudents = data.totalStudentsParticipated ?? 0;
    final num mastered = data.masteredCount ?? 0;
    final num satisfactory = data.satisfactoryCount ?? 0;
    final num failed = data.failedCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scope Title Banner
        _buildScopeBanner(),

        const SizedBox(height: 16),

        // Primary Metrics Row
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'O\'RTACHA FOIZ',
                value: '${avgPct.toStringAsFixed(2)}%',
                icon: Icons.pie_chart_rounded,
                color: avgPct >= 60 ? AppColors.emeraldAccent : AppColors.error,
                progress: (avgPct / 100).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'JAMI IMTIHONLAR',
                value: '$totalExams ta',
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.goldPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'QATNASHGAN KURSANTLAR',
                value: '$totalStudents ta',
                icon: Icons.groups_outlined,
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Mastery Breakdown Cards Row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O\'ZLASHTIRISH TAQSOTI',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusBadge(
                      label: 'O\'ZLASHTIRGAN',
                      count: '$mastered ta',
                      color: AppColors.emeraldAccent,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusBadge(
                      label: 'QONIQARLI',
                      count: '$satisfactory ta',
                      color: AppColors.goldPrimary,
                      icon: Icons.verified_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusBadge(
                      label: 'O\'ZLASHTIRMAGAN',
                      count: '$failed ta',
                      color: AppColors.error,
                      icon: Icons.highlight_off_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Subject Performance Breakdown
        _buildSubjectPerformancesSection(data.subjectPerformances ?? []),

        const SizedBox(height: 20),

        // Time Dynamics Section
        _buildTimeDynamicsSection(data.timeDynamics ?? []),
      ],
    );
  }

  // GROUP SPECIFIC DASHBOARD
  Widget _buildGroupDashboard(GroupStatisticsModel gData) {
    final double avgPct = (gData.overallAverage ?? 0.0).toDouble();
    final num totalStudents = gData.totalStudents ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScopeBanner(),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'UMUMIY O\'RTACHA FOIZ',
                value: '${avgPct.toStringAsFixed(2)}%',
                icon: Icons.score_rounded,
                color: avgPct >= 60 ? AppColors.emeraldAccent : AppColors.error,
                progress: (avgPct / 100).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'JAMI O\'QUVCHILAR SONI',
                value: '$totalStudents ta',
                icon: Icons.groups_3_outlined,
                color: AppColors.goldPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Subject Stats for Group
        _buildSubjectPerformancesSection(gData.subjectStats ?? []),
      ],
    );
  }

  // SCOPE BANNER
  Widget _buildScopeBanner() {
    String title = 'LITSEY UMUMIY STATISTIKASI';
    String subtitle = 'Barcha bosqich va guruhlar bo\'yicha jamlangan ko\'rsatkichlar';
    IconData icon = Icons.account_balance_outlined;

    if (_selectedScope == StatScope.stage) {
      title = _selectedStage?.name?.toUpperCase() ?? 'BOSQICH STATISTIKASI';
      subtitle = 'Tanlangan bosqich bo\'yicha o\'zlashtirish ko\'rsatkichlari';
      icon = Icons.stairs_outlined;
    } else if (_selectedScope == StatScope.group) {
      title = _selectedGroup?.name?.toUpperCase() ?? 'GURUH STATISTIKASI';
      subtitle = 'Guruh o\'quvchilarining fanlar bo\'yicha umumiy o\'rtacha natijalari';
      icon = Icons.groups_3_outlined;
    } else if (_selectedScope == StatScope.subject) {
      title = _selectedSubject?.name?.toUpperCase() ?? 'FAN STATISTIKASI';
      subtitle = 'Ushbu fan bo\'yicha topshirilgan diagnostika testlari natijalari';
      icon = Icons.menu_book_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.goldPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleHeader.copyWith(fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleHeader.copyWith(fontSize: 20, color: color, fontWeight: FontWeight.bold),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.backgroundDark,
                color: color,
                minHeight: 5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                Text(count, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SUBJECT PERFORMANCES LIST
  Widget _buildSubjectPerformancesSection(List<SubjectPerformanceModel> performances) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.goldPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'FANLAR BO\'YICHA O\'ZLASHTIRISH TAQSOTI',
                style: TextStyle(color: AppColors.goldPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (performances.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Fanlar bo\'yicha ma\'lumot kelmadi', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...performances.map((sp) {
              final double avg = (sp.averagePercentage ?? 0.0).toDouble();
              Color bColor = AppColors.error;
              if (avg >= 80) bColor = AppColors.goldPrimary;
              if (avg >= 50) bColor = AppColors.emeraldAccent;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.book_rounded, color: AppColors.goldPrimary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sp.subjectName ?? 'Fan',
                            style: AppTextStyles.titleSubHeader.copyWith(fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          '${avg.toStringAsFixed(2)}%',
                          style: TextStyle(color: bColor, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (avg / 100).clamp(0.0, 1.0),
                        backgroundColor: AppColors.backgroundDark,
                        color: bColor,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('O\'zlashtirgan: ${sp.masteredCount ?? 0} ta  •  ', style: const TextStyle(color: AppColors.emeraldAccent, fontSize: 11)),
                        Text('Qoniqarli: ${sp.satisfactoryCount ?? 0} ta  •  ', style: const TextStyle(color: AppColors.goldPrimary, fontSize: 11)),
                        Text('Yiqilgan: ${sp.failedCount ?? 0} ta', style: const TextStyle(color: AppColors.error, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // TIME DYNAMICS SECTION
  Widget _buildTimeDynamicsSection(List<TimeDynamicModel> dynamics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: Color(0xFF14B8A6), size: 20),
              SizedBox(width: 8),
              Text(
                'VAQT DINAMIKASI (TIME DYNAMICS)',
                style: TextStyle(color: Color(0xFF14B8A6), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (dynamics.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Vaqt dinamikasi ma\'lumoti kelmadi', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...dynamics.map((td) {
              final double avg = (td.averagePercentage ?? 0.0).toDouble();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'O\'quv yili/oyi: ${td.year ?? td.month ?? "Noma'lum"}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Imtihonlar soni: ${td.examCount ?? 0} ta',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      '${avg.toStringAsFixed(2)}%',
                      style: TextStyle(color: avg >= 60 ? AppColors.emeraldAccent : AppColors.error, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
