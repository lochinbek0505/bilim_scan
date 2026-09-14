import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/authenticated_image.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/student_exam_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_exam_provider.dart';
import 'student_test_taking_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  String? _startingExamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentExamProvider>().fetchExams();
    });
  }

  Future<void> _handleStartExam(ExamSessionModel exam, String studentId) async {
    setState(() {
      _startingExamId = exam.id;
    });

    final examProvider = context.read<StudentExamProvider>();
    final success = await examProvider.startExam(exam.id, studentId);

    if (!mounted) return;

    setState(() {
      _startingExamId = null;
    });

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const StudentTestTakingScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imtihonni boshlashda xatolik yuz berdi!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studentExamProvider = context.watch<StudentExamProvider>();
    final user = authProvider.currentUserModel?.user;

    final studentId = user?.id ?? '6aa046d379b786309791f3a7';
    final studentName = user != null
        ? '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim()
        : 'O\'quvchi';

    final username = user?.username ?? 'student';
    final groupName = user?.guruh?['name'].toString() ?? '10-25-guruh';

    return TacticalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary.withValues(alpha: 0.95),
          elevation: 4,
          title: Row(
            children: [
              const Icon(Icons.school_outlined, color: AppColors.goldPrimary, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O\'QUVCHI PORTALI — BILIMSCAN',
                    style: AppTextStyles.titleHeader.copyWith(fontSize: 15, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Onlayn test va imtihonlarni topshirish tizimi',
                    style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.goldPrimary),
              tooltip: 'Imtihonlarni yangilash',
              onPressed: () => context.read<StudentExamProvider>().fetchExams(),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.error),
              tooltip: 'Chiqish',
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // STUDENT PROFILE CARD
              _buildStudentProfileCard(
                studentName: studentName.isEmpty ? username : studentName,
                username: username,
                studentId: studentId,
                groupName: groupName,
                bosqich: user?.bosqich?['name'].toString() ?? '1 - bosqich',
                profileImageUrl: user?.profileImageUrl?.toString(),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MAVJUD IMTIHON SEANSLARI',
                    style: AppTextStyles.badgeText.copyWith(fontSize: 12, color: AppColors.goldPrimary, letterSpacing: 1.2),
                  ),
                  Text(
                    'Jami: ${studentExamProvider.exams.length} ta imtihon',
                    style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // EXAMS LIST
              Expanded(
                child: studentExamProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
                    : studentExamProvider.exams.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            itemCount: studentExamProvider.exams.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final exam = studentExamProvider.exams[index];
                              return _buildExamCard(context, exam, studentId);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentProfileCard({
    required String studentName,
    required String username,
    required String studentId,
    required String groupName,
    required String bosqich,
    String? profileImageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
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
            imageUrl: profileImageUrl,
            name: studentName,
            width: 52,
            height: 52,
            borderColor: AppColors.goldPrimary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      studentName,
                      style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.emeraldAccent),
                      ),
                      child: Text('O\'QUVCHI', style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: AppColors.emeraldAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Bosqichi: $bosqich •  Guruh: $groupName',
                  style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('Hozircha faol imtihonlar yo\'q', style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Yangi imtihonlar tayinlanganda bu yerda paydo bo\'ladi', style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context,
    ExamSessionModel exam,
    String studentId,
  ) {
    final examName = exam.name ?? 'Imtihon';
    final guruhName = exam.guruh?.name ?? 'Guruh';
    final bosqichName = exam.guruh?.bosqich?.name ?? '';
    final isStartingThisExam = _startingExamId == exam.id;
    final isAnyExamStarting = _startingExamId != null;

    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.quiz, color: AppColors.emeraldAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            examName,
                            style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Guruh: $guruhName ${bosqichName.isNotEmpty ? "($bosqichName)" : ""}',
                            style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: isStartingThisExam
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.backgroundDark),
                      )
                    : const Icon(Icons.play_arrow, size: 18),
                label: Text(
                  isStartingThisExam ? 'YUKLANMOQDA...' : 'TESTNI BOSHLASH',
                  style: AppTextStyles.buttonText.copyWith(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldAccent,
                  foregroundColor: AppColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: isAnyExamStarting ? null : () => _handleStartExam(exam, studentId),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            children: [
              _buildBadge(Icons.timer_outlined, 'Vaqt: ${exam.durationMinutes} daqiqa', AppColors.goldPrimary),
              _buildBadge(Icons.help_outline, 'Savollar: ${exam.questionCount} ta', AppColors.emeraldAccent),
              _buildBadge(Icons.replay, 'Urinishlar: ${exam.maxAttempts} ta', const Color(0xFF0EA5E9)),
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
}
