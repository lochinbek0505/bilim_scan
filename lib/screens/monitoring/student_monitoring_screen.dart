import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/authenticated_image.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/catalog_response.dart';
import '../../models/exam_model.dart';
import '../../models/fan_model.dart';
import '../../models/guruh_model.dart';
import '../../models/student_monitoring_model.dart';
import '../../models/student_exam_model.dart';
import '../../models/user_response_dto.dart';
import '../../models/student_export_model.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_config.dart';
import '../../services/monitoring_service.dart';
import '../../services/pdf_export_service.dart';

enum MonitoringStep { bosqich, guruh, user, natija }

class StudentMonitoringScreen extends StatefulWidget {
  final String? initialStudentId;

  const StudentMonitoringScreen({
    super.key,
    this.initialStudentId,
  });

  @override
  State<StudentMonitoringScreen> createState() => _StudentMonitoringScreenState();
}

class _StudentMonitoringScreenState extends State<StudentMonitoringScreen> {
  final MonitoringService _monitoringService = MonitoringService();
  final TextEditingController _idSearchController = TextEditingController();

  MonitoringStep _currentStep = MonitoringStep.bosqich;

  CatalogResponse? _selectedBosqich;
  GuruhModel? _selectedGuruh;
  UserResponseDto? _selectedUser;

  StudentMonitoringModel? _monitoringData;
  bool _isLoadingData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().fetchAllCatalogs();
      context.read<UserProvider>().fetchUsers();

      if (widget.initialStudentId != null && widget.initialStudentId!.isNotEmpty) {
        _fetchStudentMonitoring(widget.initialStudentId!);
      }
    });
  }

  @override
  void dispose() {
    _idSearchController.dispose();
    super.dispose();
  }

  Future<String?> _fetchImageBase64(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final fullUrl = ApiConfig.getFileUrl(url);
      final response = await Dio().get(
        fullUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        return base64Encode(response.data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Image fetch error ($url): $e");
    }
    return null;
  }

  Future<void> _exportSingleStudent() async {
    if (_selectedUser == null || _monitoringData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ma'lumotlar to'liq emas!")));
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary)),
    );

    String? base64Img = await _fetchImageBase64(_selectedUser!.profileImageUrl);
    
    final exportData = StudentExportData(
      student: _selectedUser!,
      base64Image: base64Img,
      monitoringData: _monitoringData!,
    );
    
    String fileName = "${_selectedUser?.firstName ?? 'Kursant'}_${_selectedUser?.lastName ?? ''}_Natija".trim();
    
    if (mounted) Navigator.pop(context);
    await PdfExportService.exportResultsToPdf([exportData], fileName);
  }

  Future<void> _exportGroup(GuruhModel guruh) async {
    final userProv = context.read<UserProvider>();
    final usersInGroup = userProv.users.where((u) => u.guruh?.id == guruh.id).toList();
    
    if (usersInGroup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ushbu guruhda kursantlar mavjud emas!")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text("Guruh ma'lumotlari yuklanmoqda... (Kuting)", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: AppColors.goldPrimary)]),
      ),
    );

    List<StudentExportData> groupExportData = [];
    
    for (var user in usersInGroup) {
       final mData = await _monitoringService.getStudentMonitoring(user.id ?? '');
       if (mData != null) {
         String? base64Img = await _fetchImageBase64(user.profileImageUrl);
         groupExportData.add(StudentExportData(student: user, base64Image: base64Img, monitoringData: mData));
       }
    }

    String fileName = "${guruh.name ?? 'Guruh'}_Natijalari".trim();

    if (mounted) Navigator.pop(context);

    if (groupExportData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export qilish uchun ma'lumot topilmadi!")));
      }
      return;
    }

    await PdfExportService.exportGroupToZip(
      groupName: guruh.name ?? 'Guruh',
      students: groupExportData,
      zipFileName: fileName,
    );
  }

  Future<void> _exportBosqich(CatalogResponse bosqich) async {
    final catalogProv = context.read<CatalogProvider>();
    final groupsInBosqich = catalogProv.guruhlar.where((g) => g.bosqich?.id == bosqich.id).toList();
    
    final userProv = context.read<UserProvider>();

    Map<String, List<UserResponseDto>> groupUsersMap = {};

    for (var g in groupsInBosqich) {
      final usersInGuruh = userProv.users.where((u) => u.guruh?.id == g.id).toList();
      if (usersInGuruh.isNotEmpty) {
        groupUsersMap[g.name ?? 'Guruh'] = usersInGuruh;
      }
    }

    final usersInBosqichAll = userProv.users.where((u) => u.bosqich?.id == bosqich.id).toList();
    for (var u in usersInBosqichAll) {
      bool alreadyAdded = false;
      for (var list in groupUsersMap.values) {
        if (list.any((existing) => existing.id == u.id)) {
          alreadyAdded = true;
          break;
        }
      }
      if (!alreadyAdded) {
        final gName = u.guruh?.name ?? "Guruhsiz";
        groupUsersMap.putIfAbsent(gName, () => []).add(u);
      }
    }

    if (groupUsersMap.isEmpty || groupUsersMap.values.every((l) => l.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ushbu bosqichda kursantlar mavjud emas!")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text("Bosqich ma'lumotlari yuklanmoqda... (Kuting)", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: AppColors.goldPrimary)]),
      ),
    );

    Map<String, List<StudentExportData>> groupExportDataMap = {};
    
    for (var entry in groupUsersMap.entries) {
      final gName = entry.key;
      final users = entry.value;
      List<StudentExportData> list = [];
      for (var user in users) {
        final mData = await _monitoringService.getStudentMonitoring(user.id ?? '');
        if (mData != null) {
          String? base64Img = await _fetchImageBase64(user.profileImageUrl);
          list.add(StudentExportData(student: user, base64Image: base64Img, monitoringData: mData));
        }
      }
      if (list.isNotEmpty) {
        groupExportDataMap[gName] = list;
      }
    }

    String fileName = "${bosqich.name ?? 'Bosqich'}_Natijalari".trim();

    if (mounted) Navigator.pop(context);

    if (groupExportDataMap.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export qilish uchun ma'lumot topilmadi!")));
      }
      return;
    }

    await PdfExportService.exportBosqichToZip(
      bosqichName: bosqich.name ?? 'Bosqich',
      groupStudentsMap: groupExportDataMap,
      zipFileName: fileName,
    );
  }

  Future<void> _fetchStudentMonitoring(String studentId, [UserResponseDto? user]) async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
      _currentStep = MonitoringStep.natija;
      if (user != null) {
        _selectedUser = user;
      }
    });

    final data = await _monitoringService.getStudentMonitoring(studentId);

    if (mounted) {
      setState(() {
        _isLoadingData = false;
        if (data != null) {
          _monitoringData = data;
        } else {
          _errorMessage = "Foydalanuvchi ma'lumotlarini yuklashda xatolik yuz berdi.";
        }
      });
    }
  }

  // Dialogs for ID button clicks
  Future<void> _showStudentDetailsModal(String studentId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.person_pin_rounded, color: AppColors.goldPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'TALABA MA\'LUMOTLARI',
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: FutureBuilder<UserResponseDto?>(
          future: _monitoringService.getUserDetails(studentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.goldPrimary),
                ),
              );
            }
            final user = snapshot.data ?? _selectedUser;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: AuthenticatedImage(
                      imageUrl: user?.profileImageUrl,
                      name: user?.fullName ?? 'Talaba',
                      width: 72,
                      height: 72,
                      borderColor: AppColors.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('F.I.SH', user?.fullName ?? 'Noma\'lum'),
                  _buildDetailRow('Foydalanuvchi nomi', '@${user?.username ?? 'noma\'lum'}'),
                  _buildDetailRow('ID', studentId, isId: true),
                  _buildDetailRow('Roli', user?.role ?? 'O\'QUVCHI'),
                  _buildDetailRow('Guruh', user?.guruh?.name ?? _selectedGuruh?.name ?? 'Biriktirilmagan'),
                  _buildDetailRow('Bosqich', user?.bosqich?.name ?? _selectedBosqich?.name ?? 'Biriktirilmagan'),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('YOPISH', style: TextStyle(color: AppColors.goldPrimary)),
          ),
        ],
      ),
    );
  }

  String _getOverallStatus(double percentage, String rawLevel) {
    final level = rawLevel.toUpperCase();
    if (level == 'HIGH_MASTERY' || level == 'EXCELLENT' || percentage >= 80.0) {
      return "O'ZLASHTIRGAN";
    } else if (level == 'PASSED' || (percentage >= 60.0 && percentage < 80.0)) {
      return "QONIQARLI";
    } else {
      return "O'ZLASHTIRMAGAN";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "O'ZLASHTIRGAN":
        return AppColors.emeraldAccent;
      case "QONIQARLI":
        return AppColors.goldPrimary;
      case "O'ZLASHTIRMAGAN":
      default:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "O'ZLASHTIRGAN":
        return Icons.emoji_events_outlined;
      case "QONIQARLI":
        return Icons.verified_outlined;
      case "O'ZLASHTIRMAGAN":
      default:
        return Icons.highlight_off_outlined;
    }
  }

  Widget _buildResultMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.titleHeader.copyWith(fontSize: 22, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _showExamSessionDetailsModal(String examSessionId, [Exam? examObj]) async {
    final studentId = _monitoringData?.studentId ?? _selectedUser?.id ?? '6aa4fb2bf9d8048e1cd2c11e';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.analytics_rounded, color: AppColors.goldPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'IMTIHON NATIJASI VA TAHLILI',
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _monitoringService.getExamScore(examSessionId, studentId),
            _monitoringService.getExamSessionDetails(examSessionId),
            _monitoringService.getUserDetails(studentId),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.goldPrimary),
                      SizedBox(height: 12),
                      Text(
                        'Imtihon score so\'rovi yuborilmoqda...',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            final ExamResultResponse? scoreResult = snapshot.data?[0] as ExamResultResponse?;
            final ExamModel? sessionDetails = snapshot.data?[1] as ExamModel?;
            final UserResponseDto? userDetails = snapshot.data?[2] as UserResponseDto? ?? _selectedUser;

            final double pct = scoreResult?.percentage ?? examObj?.percentage?.toDouble() ?? 0.0;
            final String rawMastery = scoreResult?.masteryLevel ?? examObj?.masteryLevel ?? 'FAILED';

            final overallStatus = _getOverallStatus(pct, rawMastery);
            final statusColor = _getStatusColor(overallStatus);
            final statusIcon = _getStatusIcon(overallStatus);

            final studentName = userDetails?.fullName ?? 'Kursant';
            final groupName = userDetails?.guruh?.name ?? _selectedGuruh?.name ?? '10-25-guruh';
            final bosqichName = userDetails?.bosqich?.name ?? _selectedBosqich?.name ?? '1-Kurs';

            return SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [


                    // KURSANT PROFILE CARD (Exact match to StudentExamResultScreen)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AuthenticatedImage(
                            imageUrl: userDetails?.profileImageUrl,
                            name: studentName,
                            width: 52,
                            height: 52,
                            borderColor: AppColors.goldPrimary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        studentName,
                                        style: AppTextStyles.titleHeader.copyWith(fontSize: 15, color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.emeraldPrimary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.emeraldAccent),
                                      ),
                                      child: Text(
                                        'KURSANT',
                                        style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: AppColors.emeraldAccent),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bosqich: $bosqichName • Guruh: $groupName',
                                  style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // OVERALL SCORE CARD (Exact match to StudentExamResultScreen)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Text(
                            overallStatus,
                            style: AppTextStyles.titleHeader.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UMUMIY NATIJA BAHOSI',
                            style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.textMuted),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildResultMetric(
                                label: 'FOIZ',
                                value: '${pct.toStringAsFixed(1)}%',
                                color: statusColor,
                              ),
                              _buildResultMetric(
                                label: 'TO\'G\'RI JAVOBLAR',
                                value: scoreResult != null
                                    ? '${scoreResult.correctAnswers} / ${scoreResult.totalQuestions}'
                                    : '—',
                                color: AppColors.goldPrimary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TOPIC MASTERY BREAKDOWN CARD (Exact match to StudentExamResultScreen)
                    if (scoreResult != null && scoreResult.topicMastery.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics_outlined, color: AppColors.goldPrimary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'MAVZULAR BO\'YICHA O\'ZLASHTIRISH DARAJASI',
                                  style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.goldPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            ...scoreResult.topicMastery.entries.map((entry) {
                              final topicId = entry.key;
                              final isMastered = entry.value;

                              String topicName = topicId;
                              for (var q in scoreResult.questions) {
                                if (q.mavzu?.id == topicId && q.mavzu?.name != null) {
                                  topicName = q.mavzu!.name;
                                  break;
                                }
                              }

                              final topicStatusText = isMastered ? "O'ZLASHTIRGAN" : "O'ZLASHTIRMAGAN";
                              final topicStatusColor = isMastered ? AppColors.emeraldAccent : AppColors.error;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMastered
                                      ? AppColors.emeraldPrimary.withValues(alpha: 0.15)
                                      : AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: topicStatusColor.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isMastered ? Icons.check_circle_outline : Icons.highlight_off_outlined,
                                      color: topicStatusColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        topicName,
                                        style: AppTextStyles.bodyText.copyWith(
                                          fontSize: 12,
                                          color: isMastered ? AppColors.emeraldAccent : AppColors.textPrimary,
                                          fontWeight: isMastered ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      topicStatusText,
                                      style: AppTextStyles.badgeText.copyWith(
                                        fontSize: 10,
                                        color: topicStatusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // EXTRA SESSION DETAILS
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'SESSIYA VA TEST DETALLARI',
                                style: TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Imtihon nomi', examObj?.examName ?? sessionDetails?.name ?? 'Imtihon'),
                          _buildDetailRow('Sessiya kodi', examSessionId, isId: true),
                          _buildDetailRow('Kursant kodi', studentId, isId: true),
                          if (scoreResult?.startedAt != null && scoreResult!.startedAt.isNotEmpty)
                            _buildDetailRow('Boshlangan vaqt', scoreResult.startedAt),
                          if (scoreResult?.finishedAt != null && scoreResult!.finishedAt.isNotEmpty)
                            _buildDetailRow('Tugallangan vaqt', scoreResult.finishedAt),
                          if (sessionDetails != null) ...[
                            _buildDetailRow('Test kodi', sessionDetails.testId, isId: true),
                            _buildDetailRow('Ajratilgan vaqt', '${sessionDetails.durationMinutes} daqiqa'),
                            _buildDetailRow('Savollar soni', '${sessionDetails.questionCount} ta'),
                            _buildDetailRow('Holati', sessionDetails.status),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('YOPISH', style: TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubjectDetailsModal(String subjectId, String subjectName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.emeraldAccent, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.book_rounded, color: AppColors.emeraldAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'FAN DETALLARI',
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.emeraldAccent),
              ),
            ),
          ],
        ),
        content: FutureBuilder<FanModel?>(
          future: _monitoringService.getSubjectDetails(subjectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.emeraldAccent),
                ),
              );
            }
            final fan = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Fan nomi', fan?.name ?? subjectName),
                _buildDetailRow('Fan ID', subjectId.isEmpty ? 'Kiritilmagan' : subjectId, isId: true),
                _buildDetailRow('Kafedra', fan?.kafedra?.name ?? 'Informatika va AT kafedrasi'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('YOPISH', style: TextStyle(color: AppColors.emeraldAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isId = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isId ? AppColors.goldLight : AppColors.textPrimary,
                fontSize: 13,
                fontFamily: isId ? 'monospace' : null,
                fontWeight: isId ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: TacticalBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildStepBreadcrumb(),
              Expanded(
                child: _buildCurrentStepContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // APP BAR
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.goldPrimary),
                onPressed: () {
                  if (_currentStep == MonitoringStep.bosqich) {
                    Navigator.of(context).pop();
                  } else if (_currentStep == MonitoringStep.guruh) {
                    setState(() => _currentStep = MonitoringStep.bosqich);
                  } else if (_currentStep == MonitoringStep.user) {
                    setState(() => _currentStep = MonitoringStep.guruh);
                  } else {
                    setState(() => _currentStep = MonitoringStep.user);
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O\'QUVCHILAR MONITORINGI',
                      style: AppTextStyles.titleHeader.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bosqichlar -> Guruhlar -> O\'quvchilar -> Natijalar',
                      style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.goldPrimary),
                onPressed: () {
                  context.read<CatalogProvider>().fetchAllCatalogs();
                  context.read<UserProvider>().fetchUsers();
                  if (_selectedUser != null) {
                    _fetchStudentMonitoring(_selectedUser!.id ?? '');
                  }
                },
                tooltip: 'Yangilash',
              ),
            ],
          ),

          const SizedBox(height: 8),
          // Direct ID Search bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _idSearchController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Student ID orqali to\'g\'ridan-to\'g\'ri qidirish...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.goldPrimary, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.goldPrimary, size: 20),
                  onPressed: () {
                    final query = _idSearchController.text.trim();
                    if (query.isNotEmpty) {
                      _fetchStudentMonitoring(query);
                    }
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _fetchStudentMonitoring(val.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // BREADCRUMB STEPPER
  Widget _buildStepBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildBreadcrumbChip(
              label: _selectedBosqich != null ? _selectedBosqich!.name ?? 'Bosqich' : '1. Bosqichlar',
              isActive: _currentStep == MonitoringStep.bosqich,
              isCompleted: _currentStep.index > MonitoringStep.bosqich.index,
              onTap: () {
                setState(() => _currentStep = MonitoringStep.bosqich);
              },
            ),
            _buildBreadcrumbDivider(),
            _buildBreadcrumbChip(
              label: _selectedGuruh != null ? _selectedGuruh!.name ?? 'Guruh' : '2. Guruhlar',
              isActive: _currentStep == MonitoringStep.guruh,
              isCompleted: _currentStep.index > MonitoringStep.guruh.index,
              onTap: _selectedBosqich != null || _currentStep.index >= MonitoringStep.guruh.index
                  ? () => setState(() => _currentStep = MonitoringStep.guruh)
                  : null,
            ),
            _buildBreadcrumbDivider(),
            _buildBreadcrumbChip(
              label: _selectedUser != null ? _selectedUser!.fullName : '3. O\'quvchilar',
              isActive: _currentStep == MonitoringStep.user,
              isCompleted: _currentStep.index > MonitoringStep.user.index,
              onTap: _selectedGuruh != null || _currentStep.index >= MonitoringStep.user.index
                  ? () => setState(() => _currentStep = MonitoringStep.user)
                  : null,
            ),
            _buildBreadcrumbDivider(),
            _buildBreadcrumbChip(
              label: '4. Natijalar',
              isActive: _currentStep == MonitoringStep.natija,
              isCompleted: false,
              onTap: _monitoringData != null
                  ? () => setState(() => _currentStep = MonitoringStep.natija)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbChip({
    required String label,
    required bool isActive,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    Color bg = AppColors.cardDark;
    Color border = AppColors.cardBorder;
    Color textColor = AppColors.textMuted;

    if (isActive) {
      bg = AppColors.goldPrimary.withValues(alpha: 0.15);
      border = AppColors.goldPrimary;
      textColor = AppColors.goldPrimary;
    } else if (isCompleted) {
      bg = AppColors.emeraldAccent.withValues(alpha: 0.1);
      border = AppColors.emeraldAccent.withValues(alpha: 0.5);
      textColor = AppColors.emeraldAccent;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: isActive ? 1.5 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check_circle_rounded, color: AppColors.emeraldAccent, size: 14),
              ),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
    );
  }

  // CURRENT STEP CONTENT
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case MonitoringStep.bosqich:
        return _buildBosqichlarStep();
      case MonitoringStep.guruh:
        return _buildGuruhlarStep();
      case MonitoringStep.user:
        return _buildUserlarStep();
      case MonitoringStep.natija:
        return _buildNatijalarStep();
    }
  }

  // STEP 1: BOSQICHLAR VIEW
  Widget _buildBosqichlarStep() {
    return Consumer2<CatalogProvider, UserProvider>(
      builder: (context, catalogProv, userProv, child) {
        if (catalogProv.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.goldPrimary),
          );
        }

        final bosqichlar = catalogProv.bosqichlar;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, color: AppColors.goldPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'KURS BOSQICHINI TANLANG',
                    style: AppTextStyles.titleSubHeader,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Option for "Barcha bosqichlar"
                  _buildBosqichCard(
                    title: 'BARCHA BOSQICHLAR',
                    subtitle: 'Barcha bosqich va guruhlar bo\'yicha monitoring',
                    icon: Icons.apps_rounded,
                    countLabel: '${catalogProv.guruhlar.length} ta guruh',
                    isSelected: _selectedBosqich == null,
                    onTap: () {
                      setState(() {
                        _selectedBosqich = null;
                        _currentStep = MonitoringStep.guruh;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  ...bosqichlar.map((b) {
                    final guruhCount = catalogProv.guruhlar
                        .where((g) => g.bosqich?.id == b.id)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildBosqichCard(
                        title: b.name ?? 'Bosqich',
                        subtitle: 'O\'quv kursi bosqichi',
                        icon: Icons.layers_rounded,
                        countLabel: '$guruhCount ta guruh',
                        isSelected: _selectedBosqich?.id == b.id,
                        onTap: () {
                          setState(() {
                            _selectedBosqich = b;
                            _selectedGuruh = null;
                            _currentStep = MonitoringStep.guruh;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBosqichCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String countLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.1) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
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
                    style: AppTextStyles.titleSubHeader.copyWith(fontSize: 15, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                countLabel,
                style: const TextStyle(color: AppColors.goldPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  // STEP 2: GURUHLAR VIEW
  Widget _buildGuruhlarStep() {
    return Consumer2<CatalogProvider, UserProvider>(
      builder: (context, catalogProv, userProv, child) {
        final allGuruhlar = catalogProv.guruhlar;
        final filteredGuruhlar = _selectedBosqich == null
            ? allGuruhlar
            : allGuruhlar.where((g) => g.bosqich?.id == _selectedBosqich!.id).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.groups_outlined, color: AppColors.emeraldAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedBosqich != null
                          ? '${_selectedBosqich!.name?.toUpperCase()} GURUHLARI'
                          : 'BARCHA GURUHLAR',
                      style: AppTextStyles.titleSubHeader,
                    ),
                  ),
                  if (_selectedBosqich != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.emeraldAccent),
                      tooltip: 'Bosqichni PDF formatida yuklash',
                      onPressed: () => _exportBosqich(_selectedBosqich!),
                    ),
                  ],
                ],
              ),
            ),

            if (filteredGuruhlar.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Ushbu bosqichda hali guruhlar yo\'q',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredGuruhlar.length,
                  itemBuilder: (context, index) {
                    final g = filteredGuruhlar[index];
                    final studentCount = userProv.users
                        .where((u) => u.guruh?.id == g.id)
                        .length;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedGuruh = g;
                            _currentStep = MonitoringStep.user;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedGuruh?.id == g.id
                                ? AppColors.emeraldAccent.withValues(alpha: 0.1)
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedGuruh?.id == g.id
                                  ? AppColors.emeraldAccent
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.group_work_rounded, color: AppColors.emeraldAccent, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.name ?? 'Guruh',
                                      style: AppTextStyles.titleSubHeader.copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      g.bosqich?.name ?? 'Bosqich biriktirilmagan',
                                      style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$studentCount ta o\'quvchi',
                                  style: const TextStyle(
                                    color: AppColors.emeraldAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // STEP 3: USERLAR VIEW
  Widget _buildUserlarStep() {
    return Consumer<UserProvider>(
      builder: (context, userProv, child) {
        final allUsers = userProv.users;
        final filteredUsers = _selectedGuruh == null
            ? allUsers
            : allUsers.where((u) => u.guruh?.id == _selectedGuruh!.id).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.person_search_rounded, color: AppColors.goldPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedGuruh != null
                          ? '${_selectedGuruh!.name?.toUpperCase()} O\'QUVCHILARI'
                          : 'BARCHA O\'QUVCHILAR',
                      style: AppTextStyles.titleSubHeader,
                    ),
                  ),
                  Text(
                    '${filteredUsers.length} ta',
                    style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedGuruh != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.goldPrimary),
                      tooltip: 'Guruhni PDF formatida yuklash',
                      onPressed: () => _exportGroup(_selectedGuruh!),
                    ),
                  ],
                ],
              ),
            ),

            if (filteredUsers.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Ushbu guruhda foydalanuvchilar topilmadi',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final u = filteredUsers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () {
                          if (u.id != null && u.id!.isNotEmpty) {
                            _fetchStudentMonitoring(u.id!, u);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              AuthenticatedImage(
                                imageUrl: u.profileImageUrl,
                                name: u.fullName,
                                width: 48,
                                height: 48,
                                borderColor: AppColors.goldPrimary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.fullName,
                                      style: AppTextStyles.titleSubHeader.copyWith(fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${u.username ?? 'noma\'lum'}  •  ${u.guruh?.name ?? 'Guruhsiz'}',
                                      style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () {
                                        if (u.id != null) _showStudentDetailsModal(u.id!);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.goldPrimary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ID: ${u.id ?? 'noma\'lum'}',
                                          style: const TextStyle(
                                            color: AppColors.goldLight,
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (u.id != null && u.id!.isNotEmpty) {
                                    _fetchStudentMonitoring(u.id!, u);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.goldPrimary,
                                  foregroundColor: AppColors.backgroundDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text(
                                  'NATIJA',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // STEP 4: NATIJALAR VIEW
  Widget _buildNatijalarStep() {
    if (_isLoadingData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.goldPrimary),
            SizedBox(height: 16),
            Text(
              'Imtihon natijalari va monitoring yuklanmoqda...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_monitoringData?.studentId != null) {
                  _fetchStudentMonitoring(_monitoringData!.studentId!);
                }
              },
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      );
    }

    final data = _monitoringData;
    if (data == null) {
      return const Center(
        child: Text(
          'Monitoring ma\'lumotlari topilmadi',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Header & ID Button
          _buildStudentHeaderCard(data),

          const SizedBox(height: 16),

          // Overall Stats Widgets
          _buildOverallSummaryCards(data),

          const SizedBox(height: 20),

          // Academic Years & Months Tree
          Text(
            'AKADEMIK YILLAR VA FANLAR BO\'YICHA MONITORING',
            style: AppTextStyles.titleSubHeader.copyWith(fontSize: 13, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),

          if (data.academicYears.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Ushbu talaba uchun imtihon tarixi topilmadi',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...data.academicYears.map((ay) => _buildAcademicYearCard(ay)),
        ],
      ),
    );
  }

  // Student Header Card
  Widget _buildStudentHeaderCard(StudentMonitoringModel data) {
    final studentId = data.studentId ?? '6aa4fb2bf9d8048e1cd2c11e';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          AuthenticatedImage(
            imageUrl: _selectedUser?.profileImageUrl,
            name: _selectedUser?.fullName ?? 'Talaba',
            width: 56,
            height: 56,
            borderColor: AppColors.goldPrimary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedUser?.fullName ?? 'O\'quvchi',
                  style: AppTextStyles.titleHeader.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _selectedUser?.guruh?.name ?? _selectedGuruh?.name ?? '10-25-guruh',
                      style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.emeraldAccent),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedUser?.bosqich?.name ?? _selectedBosqich?.name ?? '1-Kurs',
                      style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Clickable studentId button
                InkWell(
                  onTap: () => _showStudentDetailsModal(studentId),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldPrimary, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, color: AppColors.goldPrimary, size: 14),
                        const SizedBox(width: 6),
                        const Text(
                          'Talaba profili',
                          style: TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new_rounded, color: AppColors.goldPrimary, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.goldPrimary),
            tooltip: 'Natijalarni PDF formatida yuklash',
            onPressed: _exportSingleStudent,
          ),
        ],
      ),
    );
  }

  // Overall Summary Cards (Percentage & Mastery)
  Widget _buildOverallSummaryCards(StudentMonitoringModel data) {
    final pct = data.overallPercentage ?? 0.0;
    final mastery = data.overallMastery ?? 'FAILED';

    Color masteryColor = AppColors.error;
    IconData masteryIcon = Icons.cancel_outlined;
    String masteryText = 'O\'ZLASHTIRILMAGAN (FAILED)';

    if (mastery == 'PASSED') {
      masteryColor = AppColors.emeraldAccent;
      masteryIcon = Icons.check_circle_outline_rounded;
      masteryText = 'O\'ZLASHTIRILGAN (PASSED)';
    } else if (mastery == 'EXCELLENT') {
      masteryColor = AppColors.goldPrimary;
      masteryIcon = Icons.stars_rounded;
      masteryText = 'A\'LO O\'ZLASHTIRILGAN';
    }

    return Row(
      children: [
        // Overall Percentage Gauge Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UMUMIY O\'ZLASHTIRISH',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${pct.toStringAsFixed(2)}%',
                      style: AppTextStyles.titleHeader.copyWith(
                        fontSize: 24,
                        color: pct >= 60 ? AppColors.emeraldAccent : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100.0).clamp(0.0, 1.0),
                    backgroundColor: AppColors.backgroundDark,
                    color: pct >= 60 ? AppColors.emeraldAccent : AppColors.error,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Overall Mastery Level Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: masteryColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UMUMIY HOLAT (MASTERY)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(masteryIcon, color: masteryColor, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        masteryText,
                        style: TextStyle(
                          color: masteryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Academic Year Card
  Widget _buildAcademicYearCard(AcademicYear ay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: AppColors.goldPrimary,
        collapsedIconColor: AppColors.textMuted,
        title: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.goldPrimary, size: 18),
            const SizedBox(width: 10),
            Text(
              'O\'quv yili: ${ay.year ?? 'Noma\'lum'}',
              style: AppTextStyles.titleSubHeader.copyWith(fontSize: 15),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: ay.months.map((m) => _buildMonthSection(m)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Month Section
  Widget _buildMonthSection(Month month) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded, color: AppColors.emeraldAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'Davr: ${month.month ?? 'Noma\'lum'}',
                style: const TextStyle(color: AppColors.emeraldAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...month.subjects.map((sub) => _buildSubjectCard(sub)),
        ],
      ),
    );
  }

  // Subject Card & Exams list
  Widget _buildSubjectCard(Subject sub) {
    final subjectId = sub.subjectId?.toString() ?? '';
    final subPct = sub.averagePercentage ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.goldPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sub.subjectName ?? 'Ingliz tili',
                  style: AppTextStyles.titleSubHeader.copyWith(fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'O\'rtacha: ${subPct.toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.goldPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Clickable subjectId button if present
          Row(
            children: [
              if (subjectId.isNotEmpty && subjectId != 'null')
                InkWell(
                  onTap: () => _showSubjectDetailsModal(subjectId, sub.subjectName ?? 'Fan'),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.emeraldAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.emeraldAccent, size: 12),
                        const SizedBox(width: 4),
                        const Text(
                          'Fan ma\'lumotlari',
                          style: TextStyle(
                            color: AppColors.emeraldAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new_rounded, color: AppColors.emeraldAccent, size: 10),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                'Holat: ${sub.subjectMastery ?? 'FAILED'}',
                style: TextStyle(
                  color: sub.subjectMastery == 'PASSED' ? AppColors.emeraldAccent : AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Divider(color: AppColors.cardBorder, height: 16),

          // Exams list
          const Text(
            'Imtihonlar ro\'yxati:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          if (sub.exams.isEmpty)
            const Text('Hali imtihonlar mavjud emas', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else
            ...sub.exams.map((ex) => _buildExamRow(ex)),
        ],
      ),
    );
  }

  // Exam Item Row with clickable examSessionId button
  Widget _buildExamRow(Exam exam) {
    final examSessionId = exam.examSessionId ?? '';
    final pct = exam.percentage ?? 0.0;
    final mastery = exam.masteryLevel ?? 'FAILED';

    Color mColor = AppColors.error;
    if (mastery == 'PASSED') mColor = AppColors.emeraldAccent;
    if (mastery == 'EXCELLENT') mColor = AppColors.goldPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: AppColors.info, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  exam.examName ?? 'Imtihon',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(color: mColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: mColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  mastery,
                  style: TextStyle(color: mColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
              const SizedBox(width: 4),
              Text(
                exam.formattedDate,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const Spacer(),

              // Clickable examSessionId button
              if (examSessionId.isNotEmpty)
                InkWell(
                  onTap: () => _showExamSessionDetailsModal(examSessionId, exam),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.analytics_outlined, color: AppColors.info, size: 12),
                        const SizedBox(width: 4),
                        const Text(
                          'Natijalar va tahlil',
                          style: TextStyle(
                            color: AppColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.open_in_new_rounded, color: AppColors.info, size: 10),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
