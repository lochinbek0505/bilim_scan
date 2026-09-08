import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  double _loadingProgress = 0.0;
  String _loadingText = "BilimScan tizim modullari yuklanmoqda...";

  @override
  void initState() {
    super.initState();

    // Controllers
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Animations
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _logoFadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Sequence execution
    _startSequence();
  }

  void _startSequence() async {
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Progress simulation
    _progressController.addListener(() {
      setState(() {
        _loadingProgress = _progressController.value;
        if (_loadingProgress < 0.25) {
          _loadingText = "BilimScan tizim modullari yuklanmoqda...";
        } else if (_loadingProgress < 0.55) {
          _loadingText = "Test va bilim diagnostika bazasi faollashtirilmoqda...";
        } else if (_loadingProgress < 0.85) {
          _loadingText = "Samarqand akademik litseyi serveri bilan bog'lanilmoqda...";
        } else {
          _loadingText = "Tizim muvaffaqiyatli tayyorlandi!";
        }
      });
    });

    await _progressController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TacticalBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldPrimary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 16,
                      color: AppColors.goldPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SAMARQAND AKADEMIK LITSEYI • SAMARQAND — 2026',
                      style: AppTextStyles.badgeText.copyWith(
                        color: AppColors.goldPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Dual Emblems (IIV Logo + Samarqand Litsey Logo)
              ScaleTransition(
                scale: _logoScaleAnimation,
                child: FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogoBadge(
                        imagePath: AppAssets.ivvLogo,
                        glowColor: AppColors.goldPrimary,
                        label: 'IIV VAZIRLIGI',
                      ),

                      const SizedBox(width: 32),

                      Column(
                        children: [
                          Container(
                            height: 60,
                            width: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.goldPrimary,
                                  AppColors.emeraldAccent,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Icon(
                              Icons.star,
                              size: 18,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                          Container(
                            height: 60,
                            width: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.emeraldAccent,
                                  AppColors.goldPrimary,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 32),

                      _buildLogoBadge(
                        imagePath: AppAssets.litseyLogo,
                        glowColor: AppColors.emeraldAccent,
                        label: 'SAMARQAND LITSEYI',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 44),

              // Animated Institution Title & BilimScan Header
              SlideTransition(
                position: _textSlideAnimation,
                child: FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'O\'ZBEKISTON RESPUBLIKASI ICHKI ISHLAR VAZIRLIGI',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleSubHeader.copyWith(
                          fontSize: 13,
                          letterSpacing: 2.5,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SAMARQAND AKADEMIK LITSEYI',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleHeader.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'BilimScan',
                            style: AppTextStyles.titleHeader.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: AppColors.goldPrimary,
                              shadows: [
                                BoxShadow(
                                  color: AppColors.goldPrimary.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '®',
                            style: AppTextStyles.titleHeader.copyWith(
                              fontSize: 16,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldPrimary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.emeraldAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'HAR BIR O\'QUVCHI UCHUN SHAXSIY TA\'LIM YO\'L XARITASI!',
                          style: AppTextStyles.badgeText.copyWith(
                            fontSize: 12,
                            color: AppColors.emeraldAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 52),

              // Progress & Status Indicator
              SizedBox(
                width: 480,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.emeraldAccent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _loadingText,
                              style: AppTextStyles.bodyText.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(_loadingProgress * 100).toInt()}%',
                          style: AppTextStyles.badgeText.copyWith(
                            fontSize: 14,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        color: AppColors.inputBackground,
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: _loadingProgress,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.goldPrimary,
                                      AppColors.emeraldAccent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.format_quote,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '"To\'g\'ri tahlil — yuqori natija garovi!" • BilimScan v1.0',
                          style: AppTextStyles.bodyText.copyWith(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoBadge({
    required String imagePath,
    required Color glowColor,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 135,
          height: 135,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardDark,
            border: Border.all(
              color: glowColor.withValues(alpha: 0.6),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.25),
                blurRadius: 25,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.shield,
                  size: 60,
                  color: glowColor,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.badgeText.copyWith(
              fontSize: 11,
              color: glowColor,
            ),
          ),
        ),
      ],
    );
  }
}
