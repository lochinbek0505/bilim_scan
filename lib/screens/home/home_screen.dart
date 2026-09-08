import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../providers/auth_provider.dart';
import '../login/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return TacticalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary.withValues(alpha: 0.9),
          elevation: 4,
          title: Row(
            children: [
              Image.asset(
                AppAssets.ivvLogo,
                width: 36,
                height: 36,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IIV SAMARQAND AKADEMIK LITSEYI',
                    style: AppTextStyles.titleSubHeader.copyWith(
                      fontSize: 11,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'BilimScan',
                        style: AppTextStyles.titleHeader.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '® — Bilimni Tahlil Qilish Tizimi',
                        style: AppTextStyles.bodyText.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emeraldPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.emeraldAccent),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.emeraldAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    authProvider.selectedRole.title,
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 11,
                      color: AppColors.emeraldAccent,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.error),
              tooltip: 'Tizimdan chiqish',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldPrimary.withValues(alpha: 0.1),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.inputBackground,
                      ),
                      child: ClipOval(
                        child: Image.asset(AppAssets.litseyLogo, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'XUSH KELIBSIZ, ${authProvider.loginController.text.toUpperCase()}!',
                            style: AppTextStyles.titleHeader.copyWith(
                              fontSize: 18,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Biriktirilgan o\'quv guruhi: ${authProvider.selectedGroup}',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'HAR BIR O\'QUVCHI UCHUN SHAXSIY TA\'LIM YO\'L XARITASI!',
                            style: AppTextStyles.badgeText.copyWith(
                              fontSize: 12,
                              color: AppColors.emeraldAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'BILIMSCAN TIZIM MODULLARI',
                style: AppTextStyles.badgeText.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildModuleCard(
                      title: '1. TEST TOPSHIRISH',
                      subtitle: 'O\'quvchi kompyuterda elektron test topshiradi',
                      icon: Icons.computer_outlined,
                      accentColor: AppColors.goldPrimary,
                    ),
                    _buildModuleCard(
                      title: '2. AVTOMATIK TAHLIL',
                      subtitle: 'Mavzular kesimida bo\'shliqlarni aniqlash',
                      icon: Icons.analytics_outlined,
                      accentColor: AppColors.emeraldAccent,
                    ),
                    _buildModuleCard(
                      title: '3. INDIVIDUAL TAVSIYA',
                      subtitle: 'Mashqlar va o\'quv materiallari tavsiyalari',
                      icon: Icons.menu_book_outlined,
                      accentColor: AppColors.info,
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

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleHeader.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
