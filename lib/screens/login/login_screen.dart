import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_config.dart';
import '../home/home_screen.dart';
import '../student/student_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 900;

    return TacticalBackground(
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1080),
              decoration: BoxDecoration(
                color: AppColors.cardDark.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.cardBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.goldPrimary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: isCompact
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLeftHeroPanel(context, isCompact: true),
                          Divider(height: 1, color: AppColors.cardBorder),
                          _buildRightLoginForm(context),
                        ],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildLeftHeroPanel(context, isCompact: false),
                            ),
                            Container(
                              width: 1.5,
                              color: AppColors.cardBorder,
                            ),
                            Expanded(
                              flex: 6,
                              child: _buildRightLoginForm(context),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Left Hero Showcase Panel
  Widget _buildLeftHeroPanel(BuildContext context, {required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 28 : 36),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: AppColors.goldPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SAMARQAND AKADEMIK LITSEYI • 2026',
                      style: AppTextStyles.badgeText.copyWith(
                        fontSize: 10,
                        color: AppColors.goldPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dual Emblems
              Row(
                children: [
                  _buildCircleLogo(AppAssets.ivvLogo, AppColors.goldPrimary),
                  const SizedBox(width: 16),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppColors.goldPrimary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 16),
                  _buildCircleLogo(AppAssets.litseyLogo, AppColors.emeraldAccent),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'O\'ZBEKISTON RESPUBLIKASI\nICHKI ISHLAR VAZIRLIGI',
                style: AppTextStyles.titleSubHeader.copyWith(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  color: AppColors.goldPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SAMARQAND AKADEMIK LITSEYI',
                style: AppTextStyles.titleHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'BilimScan',
                    style: AppTextStyles.titleHeader.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  Text(
                    '®',
                    style: AppTextStyles.titleHeader.copyWith(
                      fontSize: 12,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'O\'quvchilarning bilim darajasini tahlil qilish, bilimdagi bo\'shliqlarni aniqlash va bartaraf etish tizimi.',
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (!isCompact) const SizedBox(height: 28),

          // Feature list badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureRow(Icons.check_circle_outline,
                  'Test natijalarini avtomatik tahlil qilish'),
              const SizedBox(height: 10),
              _buildFeatureRow(Icons.analytics_outlined,
                  'Bilimdagi bo\'shliqlarni aniqlash va individual tavsiya'),
              const SizedBox(height: 10),
              _buildFeatureRow(Icons.wifi_off_outlined,
                  'Offlayn va lokal tarmoqda barqaror ishlash imkoniyati'),
            ],
          ),

          // Server Badge (faqat server IP topilganda ko'rinadi)
          if (ApiConfig.discoveredHost != null &&
              ApiConfig.discoveredHost!.isNotEmpty) ...[
            if (!isCompact) const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.emeraldAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldAccent,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'LOKAL SERVER: FAOL (${ApiConfig.discoveredHost})',
                      style: AppTextStyles.badgeText.copyWith(
                        fontSize: 11,
                        color: AppColors.emeraldAccent,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.lan_outlined,
                    size: 18,
                    color: AppColors.goldPrimary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircleLogo(String imagePath, Color glowColor) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardDark,
        border: Border.all(color: glowColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.shield, size: 28, color: glowColor);
          },
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.emeraldPrimary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.emeraldAccent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyText.copyWith(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Right Login Form Panel (Login & Parol)
  Widget _buildRightLoginForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.lock_person_outlined,
                    color: AppColors.goldPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TIZIMGA KIRISH',
                    style: AppTextStyles.titleHeader.copyWith(
                      fontSize: 22,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'BilimScan tizimiga kirish uchun login va parolingizni kiriting',
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),


              const SizedBox(height: 20),

              // LOGIN FIELD
              _buildInputFieldLabel('FOYDALANUVCHI NOMI'),
              const SizedBox(height: 6),
              TextField(
                controller: authProvider.loginController,
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  hintText: 'Loginingizni kiriting (Masalan: student_1025)',
                  prefixIcon: Icons.person_outline_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // PAROL FIELD
              _buildInputFieldLabel('PAROL'),
              const SizedBox(height: 6),
              TextField(
                controller: authProvider.passwordController,
                obscureText: authProvider.obscurePassword,
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  hintText: 'Maxfiy parolingizni kiriting',
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      authProvider.obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => authProvider.togglePasswordVisibility(),
                  ),
                ),
              ),

              const SizedBox(height: 16),


              const SizedBox(height: 14),

              // Remember Me & Reset Password Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: authProvider.rememberMe,
                          activeColor: AppColors.goldPrimary,
                          checkColor: AppColors.backgroundDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) =>
                              authProvider.toggleRememberMe(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Eslab qolish',
                        style: AppTextStyles.bodyText.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      _showSecurityNoticeDialog(context);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Parolni tiklash?',
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 12,
                        color: AppColors.goldPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Error Message Alert
              if (authProvider.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authProvider.errorMessage!,
                          style: AppTextStyles.bodyText.copyWith(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Status Log Animation Text
              if (authProvider.isLoading) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.goldPrimary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        authProvider.statusLog,
                        style: AppTextStyles.bodyText.copyWith(
                          fontSize: 11,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),

              // Main Action Button (TIZIMGA KIRISH)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          final success = await authProvider.login();
                          if (success && context.mounted) {
                            final role = authProvider.currentUserModel?.user?.role ?? authProvider.selectedRole.code;
                            if (role == 'ADMIN' || role == 'TEACHER') {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const StudentDashboardScreen(),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.goldPrimary.withValues(alpha: 0.4),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.backgroundDark),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.login,
                                  size: 20,
                                  color: AppColors.backgroundDark,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'TIZIMGA KIRISH',
                                  style: AppTextStyles.buttonText.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),


              const SizedBox(height: 12),

              // Bottom Footer
              Center(
                child: Text(
                  '"To\'g\'ri tahlil — yuqori natija garovi!" • Samarqand — 2026',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyText.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildInputFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.badgeText.copyWith(
        fontSize: 11,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyText.copyWith(
        color: AppColors.textMuted,
        fontSize: 13,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.goldPrimary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  void _showSecurityNoticeDialog(BuildContext context) {
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
            const Icon(Icons.info_outline, color: AppColors.goldPrimary),
            const SizedBox(width: 10),
            Text(
              'PAROLNI TIKLASH',
              style: AppTextStyles.titleHeader.copyWith(fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Parolni tiklash yoki almashtirish uchun Informatika va axborot texnologiyalari fani o\'qituvchisiga hamda tizim administratoriga murojaat qiling.',
          style: AppTextStyles.bodyText.copyWith(fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              foregroundColor: AppColors.backgroundDark,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('TUSHUNDIM'),
          ),
        ],
      ),
    );
  }
}
