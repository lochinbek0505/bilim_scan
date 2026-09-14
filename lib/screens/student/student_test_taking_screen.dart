import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/authenticated_image.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/login_model.dart';
import '../../models/student_exam_start_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_exam_provider.dart';
import 'student_exam_result_screen.dart';

class StudentTestTakingScreen extends StatefulWidget {
  const StudentTestTakingScreen({super.key});

  @override
  State<StudentTestTakingScreen> createState() => _StudentTestTakingScreenState();
}

class _StudentTestTakingScreenState extends State<StudentTestTakingScreen> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StudentExamProvider>();
    final exam = provider.currentStartedExam;

    if (exam != null) {
      final num dMins = exam.durationMinutes ?? 20;
      final int validMins = dMins > 0 ? dMins.toInt() : 20;
      _secondsRemaining = validMins * 60;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer?.cancel();
        _handleAutoSubmit();
      }
    });
  }

  Future<void> _handleAutoSubmit() async {
    if (!mounted || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vaqt tugadi! Imtihon javoblari avtomatik yuborilmoqda...'),
        backgroundColor: AppColors.warning,
      ),
    );

    final provider = context.read<StudentExamProvider>();
    final success = await provider.submitExam();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentExamResultScreen()),
      );
    } else {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Javoblarni yuborishda xatolik yuz berdi!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleSubmitExam() async {
    if (_isSubmitting) return;

    _timer?.cancel();
    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<StudentExamProvider>();
    final success = await provider.submitExam();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentExamResultScreen()),
      );
    } else {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Javoblarni yuborishda xatolik yuz berdi!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  Widget _buildProfileAvatar(User? user, {double radius = 16}) {
    final name = '${user?.firstName ?? ""} ${user?.lastName ?? ""}'.trim();
    return AuthenticatedImage(
      imageUrl: user?.profileImageUrl?.toString(),
      name: name.isEmpty ? user?.username : name,
      width: radius * 2,
      height: radius * 2,
      borderColor: AppColors.goldPrimary,
    );
  }

  void _confirmSubmitDialog(BuildContext context) {
    final provider = context.read<StudentExamProvider>();
    final answeredCount = provider.userAnswers.keys.length;
    final totalCount = provider.currentStartedExam?.questionsList?.length ?? 0;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: AppColors.goldPrimary),
            const SizedBox(width: 8),
            Text('IMTIHONNI YAKUNLASH', style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Siz $totalCount ta savoldan $answeredCount tasiga javob berdingiz.\n\nImtihonni yakunlab, javoblarni topshirishni tasdiqlaysizmi?',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('BEKOR QILISH', style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldAccent,
              foregroundColor: AppColors.backgroundDark,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _handleSubmitExam();
            },
            child: const Text('TOPSHIRISH'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentExamProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUserModel?.user;

    final exam = provider.currentStartedExam;

    final studentName = user != null
        ? '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim()
        : 'Kursant';
    final username = user?.username ?? 'student';
    final groupName = user?.guruh?.toString() ?? '10-25-guruh';

    if (exam == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Faol imtihon seansi topilmadi.', style: TextStyle(color: AppColors.textMuted)),
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

    final questions = exam.questionsList ?? [];
    final isLoadingOrSubmitting = provider.isLoading || _isSubmitting;

    return TacticalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary.withValues(alpha: 0.95),
          elevation: 4,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              _buildProfileAvatar(user, radius: 16),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    studentName.isEmpty ? username : studentName,
                    style: AppTextStyles.titleHeader.copyWith(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Guruh: $groupName',
                    style: AppTextStyles.bodyText.copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(height: 20, width: 1, color: AppColors.cardBorder),
              const SizedBox(width: 16),
              const Icon(Icons.timer_outlined, color: AppColors.goldPrimary, size: 20),
              const SizedBox(width: 6),
              Text(
                _formatTimer(_secondsRemaining),
                style: AppTextStyles.titleHeader.copyWith(
                  fontSize: 15,
                  color: _secondsRemaining < 180 ? AppColors.error : AppColors.goldPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('IMTIHONNI YAKUNLASH'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldAccent,
                  foregroundColor: AppColors.backgroundDark,
                ),
                onPressed: isLoadingOrSubmitting ? null : () => _confirmSubmitDialog(context),
              ),
            ),
          ],
        ),
        body: isLoadingOrSubmitting
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.goldPrimary),
                    SizedBox(height: 14),
                    Text('Javoblar yuborilmoqda va baholanmoqda...', style: TextStyle(color: AppColors.goldPrimary)),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView.separated(
                  itemCount: questions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return _buildQuestionCard(context, q, index + 1, provider);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    Question question,
    int number,
    StudentExamProvider provider,
  ) {
    final questionId = question.id ?? 'q_$number';
    final selectedAnswers = provider.userAnswers[questionId] ?? [];
    final options = question.optionsList ?? [];
    final qType = (question.type ?? 'SINGLE_CHOICE').toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedAnswers.isNotEmpty ? AppColors.emeraldAccent : AppColors.cardBorder,
          width: selectedAnswers.isNotEmpty ? 1.5 : 1.0,
        ),
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
          // Savol tartib raqami (Ortiqcha mavzu va turi olib tashlandi)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('SAVOL #$number', style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.goldPrimary)),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            question.title ?? '',
            style: AppTextStyles.bodyText.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          // Render options or text input based on question type
          if (qType == 'WRITTEN' || qType == 'OPEN' || options.isEmpty)
            _WrittenAnswerInput(
              key: ValueKey(questionId),
              initialText: selectedAnswers.isNotEmpty ? selectedAnswers.first : '',
              onChanged: (val) => provider.setWrittenAnswer(questionId, val),
            )
          else if (qType == 'MULTIPLE_CHOICE')
            _buildMultipleChoiceOptions(questionId, options, provider, selectedAnswers)
          else
            _buildSingleChoiceOptions(questionId, options, provider, selectedAnswers),
        ],
      ),
    );
  }

  Widget _buildSingleChoiceOptions(
    String questionId,
    List<Option> options,
    StudentExamProvider provider,
    List<String> selectedAnswers,
  ) {
    return Column(
      children: options.map((option) {
        final optionText = option.text ?? '';
        final isSelected = selectedAnswers.contains(optionText);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () => provider.selectSingleAnswer(questionId, optionText),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.emeraldPrimary.withValues(alpha: 0.2) : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.emeraldAccent : AppColors.cardBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.emeraldAccent : AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      optionText,
                      style: AppTextStyles.bodyText.copyWith(
                        color: isSelected ? AppColors.emeraldAccent : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceOptions(
    String questionId,
    List<Option> options,
    StudentExamProvider provider,
    List<String> selectedAnswers,
  ) {
    return Column(
      children: options.map((option) {
        final optionText = option.text ?? '';
        final isSelected = selectedAnswers.contains(optionText);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () => provider.toggleMultipleAnswer(questionId, optionText),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.emeraldPrimary.withValues(alpha: 0.2) : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.emeraldAccent : AppColors.cardBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected ? AppColors.emeraldAccent : AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      optionText,
                      style: AppTextStyles.bodyText.copyWith(
                        color: isSelected ? AppColors.emeraldAccent : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WrittenAnswerInput extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;

  const _WrittenAnswerInput({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  @override
  State<_WrittenAnswerInput> createState() => _WrittenAnswerInputState();
}

class _WrittenAnswerInputState extends State<_WrittenAnswerInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLines: 3,
      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Javobingizni bu yerga kiriting...',
        hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.emeraldAccent),
        ),
      ),
    );
  }
}
