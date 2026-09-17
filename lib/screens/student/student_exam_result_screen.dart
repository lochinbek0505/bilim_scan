import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/authenticated_image.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/login_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_exam_provider.dart';

class StudentExamResultScreen extends StatelessWidget {
  const StudentExamResultScreen({super.key});

  String _getOverallStatus(double percentage, String rawLevel) {
    final level = rawLevel.toUpperCase();
    if (level == 'HIGH_MASTERY' || percentage >= 80.0) {
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

  Widget _buildProfileAvatar(User? user, {double radius = 26}) {
    final name = '${user?.firstName ?? ""} ${user?.lastName ?? ""}'.trim();
    return AuthenticatedImage(
      imageUrl: user?.profileImageUrl?.toString(),
      name: name.isEmpty ? user?.username : name,
      width: radius * 2,
      height: radius * 2,
      borderColor: AppColors.goldPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentExamProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUserModel?.user;

    final result = provider.lastResult;

    final studentName = user != null
        ? '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim()
        : 'Kursant';
    final groupName = user?.guruh?['name'].toString() ?? '10-25-guruh';
    final studentId = user?.bosqich['name'] ?? '1 - bosqich';

    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Natijalar topilmadi.', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('QAYTISH'),
              ),
            ],
          ),
        ),
      );
    }

    final overallStatus = _getOverallStatus(result.percentage, result.masteryLevel);
    final statusColor = _getStatusColor(overallStatus);
    final statusIcon = _getStatusIcon(overallStatus);

    return TacticalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary.withValues(alpha: 0.95),
          elevation: 4,
          automaticallyImplyLeading: false,
          title: Text(
            'IMTIHON NATIJASI VA TAHLILI',
            style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: AppColors.goldPrimary),
              tooltip: 'Bosh sahifaga qaytish',
              onPressed: () {
                provider.resetCurrentExam();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // KURSANT PROFILE CARD
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
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
                          _buildProfileAvatar(user, radius: 26),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      studentName.isEmpty ? "Ismsiz" : studentName,
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
                                      child: Text(
                                        'KURSANT',
                                        style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: AppColors.emeraldAccent),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bosqich: $studentId • Guruh: $groupName ',
                                  style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // OVERALL SCORE CARD
                    Container(
                      padding: const EdgeInsets.all(24),
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            overallStatus,
                            style: AppTextStyles.titleHeader.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UMUMIY NATIJA BAHOSI',
                            style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.textMuted),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildResultMetric(
                                label: 'FOIZ',
                                value: '${result.percentage.toStringAsFixed(1)}%',
                                color: statusColor,
                              ),
                              _buildResultMetric(
                                label: 'TO\'G\'RI JAVOBLAR',
                                value: '${result.correctAnswers} / ${result.totalQuestions}',
                                color: AppColors.goldPrimary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TOPIC MASTERY BREAKDOWN CARD
                    if (result.topicMastery.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                  style: AppTextStyles.badgeText.copyWith(fontSize: 12, color: AppColors.goldPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            ...result.topicMastery.entries.map((entry) {
                              final topicId = entry.key;
                              final isMastered = entry.value;

                              String topicName = topicId;
                              for (var q in result.questions) {
                                if (q.mavzu?.id == topicId && q.mavzu?.name != null) {
                                  topicName = q.mavzu!.name;
                                  break;
                                }
                              }

                              final topicStatusText = isMastered ? "O'ZLASHTIRGAN" : "O'ZLASHTIRMAGAN";
                              final topicStatusColor = isMastered ? AppColors.emeraldAccent : AppColors.error;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
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

                    const SizedBox(height: 24),

                    // RETURN TO DASHBOARD BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('BOSH SAHIFAGA QAYTISH'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldPrimary,
                          foregroundColor: AppColors.backgroundDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          provider.resetCurrentExam();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
}
