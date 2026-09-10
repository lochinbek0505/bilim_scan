import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../providers/auth_provider.dart';
import '../login/login_screen.dart';
import '../test_management/test_management_screen.dart';
import '../edu_plan_management/edu_plan_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isMaximized = MediaQuery.of(context).size.width > 1100;

    return TacticalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary.withValues(alpha: 0.95),
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
                        '® — Administrator Portali',
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
            // Security Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 16,
                    color: AppColors.goldPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ADMINISTRATOR',
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 11,
                      color: AppColors.goldPrimary,
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
              // Admin Header Banner
              _buildAdminWelcomeBanner(authProvider),

              const SizedBox(height: 20),

              // Statistics Quick Overview Bar
              _buildQuickStatsOverviewRow(),

              const SizedBox(height: 24),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ADMINISTRATOR TIZIM BOSHQARUVI MODULLARI',
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Samarqand — 2026',
                    style: AppTextStyles.bodyText.copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Administrator Modules Grid (10 Modules)
              Expanded(
                child: SingleChildScrollView(
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMaximized ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.55,
                    children: [
                      // 1. Test Yaratish
                      _buildAdminModuleCard(
                        title: '1. TESTLARNI BOSHQARISH (CRUD)',
                        subtitle: 'Elektron va skanerlanadigan diagnostika testlar bankini shakllantirish hamda JSON fayldan savollarni yuklash',
                        badgeText: 'Test Banki',
                        icon: Icons.assignment_add,
                        accentColor: AppColors.goldPrimary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const TestManagementScreen()),
                          );
                        },
                      ),

                      // 2. Test Natijalari
                      _buildAdminModuleCard(
                        title: '2. TEST NATIJALARI',
                        subtitle: 'Skanerlangan test va elektron diagnostika javoblarini ko\'rish',
                        badgeText: 'Natijalar',
                        icon: Icons.fact_check_outlined,
                        accentColor: AppColors.emeraldAccent,
                        onTap: () => _showTestResultsDialog(context),
                      ),

                      // 3. User Yaratish
                      _buildAdminModuleCard(
                        title: '3. USER YARATISH',
                        subtitle: 'O\'quvchilar, o\'qituvchilar va administratorlar hisoblarini boshqarish',
                        badgeText: 'Foydalanuvchilar',
                        icon: Icons.person_add_alt_1_outlined,
                        accentColor: AppColors.warning,
                        onTap: () => _showCreateUserDialog(context),
                      ),

                      // 4. O'quv Reja
                      _buildAdminModuleCard(
                        title: '4. O\'QUV REJALARI (EDU PLAN CRUD)',
                        subtitle: 'Yillik va semestrlik o\'quv rejalari, soatlar taqsimoti, mavzular va JSON fayl importi',
                        badgeText: 'O\'quv reja',
                        icon: Icons.calendar_month_outlined,
                        accentColor: const Color(0xFF14B8A6),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const EduPlanManagementScreen()),
                          );
                        },
                      ),

                      // 5. Kurs Bosqichi
                      _buildAdminModuleCard(
                        title: '5. KURS BOSQICHI',
                        subtitle: '1-kurs va 2-kurs bosqichlari hamda o\'quv yillarini shakllantirish',
                        badgeText: 'O\'quv yili',
                        icon: Icons.stairs_outlined,
                        accentColor: const Color(0xFF0EA5E9),
                        onTap: () => _showCourseLevelDialog(context),
                      ),

                      // 6. Guruhlar
                      _buildAdminModuleCard(
                        title: '6. GURUHLAR BOSHQARUVI',
                        subtitle: 'Akademik litsey o\'quv guruhlari ro\'yxati va biriktiruvlarini yaratish',
                        badgeText: 'Guruhlar',
                        icon: Icons.groups_3_outlined,
                        accentColor: const Color(0xFFA855F7),
                        onTap: () => _showGroupManagementDialog(context),
                      ),

                      // 7. Kafedra
                      _buildAdminModuleCard(
                        title: '7. KAFEDRALAR',
                        subtitle: 'Informatika va AT, Tillar hamda Aniqlik fanlar kafedralari',
                        badgeText: 'Kafedralar',
                        icon: Icons.account_balance_outlined,
                        accentColor: AppColors.emeraldAccent,
                        onTap: () => _showDepartmentDialog(context),
                      ),

                      // 8. Fanlar
                      _buildAdminModuleCard(
                        title: '8. FANLAR VA MAVZULAR',
                        subtitle: 'O\'quv fanlari, bo\'limlar va diagnostika mavzulari katalogi',
                        badgeText: 'Fanlar',
                        icon: Icons.menu_book_outlined,
                        accentColor: AppColors.goldPrimary,
                        onTap: () => _showSubjectDialog(context),
                      ),

                      // 9. Tahlil
                      _buildAdminModuleCard(
                        title: '9. BILIMDAGI BO\'SHLIQLAR TAHLILI',
                        subtitle: 'O\'quvchilarning bilim bo\'shliqlarini avtomatik diagnostika qilish',
                        badgeText: 'AI Tahlil',
                        icon: Icons.psychology_outlined,
                        accentColor: const Color(0xFFEC4899),
                        onTap: () => _showAnalysisDialog(context),
                      ),

                      // 10. Statistika
                      _buildAdminModuleCard(
                        title: '10. STATISTIKA VA MONITORING',
                        subtitle: 'Guruhlar, fanlar va o\'zlashtirish dinamikasi bo\'yicha tahliliy hisobot',
                        badgeText: 'Analitika',
                        icon: Icons.bar_chart_rounded,
                        accentColor: const Color(0xFF3B82F6),
                        onTap: () => _showStatisticsDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Welcome Banner
  Widget _buildAdminWelcomeBanner(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.inputBackground,
            ),
            child: ClipOval(
              child: Image.asset(AppAssets.litseyLogo, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TIZIM ADMINISTRATORI: ${authProvider.loginController.text.toUpperCase()}',
                      style: AppTextStyles.titleHeader.copyWith(
                        fontSize: 16,
                        color: AppColors.goldPrimary,
                      ),
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
                        'FAOL SEANS',
                        style: AppTextStyles.badgeText.copyWith(
                          fontSize: 10,
                          color: AppColors.emeraldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Samarqand akademik litseyi o\'quvchilarining bilim darajasini tahlil qilish va boshqarish markazi.',
                  style: AppTextStyles.bodyText.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Overview Metric Chips
  Widget _buildQuickStatsOverviewRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            label: 'O\'QUVCHILAR',
            value: '250+ o\'quvchi',
            icon: Icons.school_outlined,
            color: AppColors.goldPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            label: 'GURUHLAR',
            value: '12 ta guruh',
            icon: Icons.groups_outlined,
            color: AppColors.emeraldAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            label: 'KAFEDRALAR',
            value: '6 ta kafedra',
            icon: Icons.account_balance_outlined,
            color: const Color(0xFF0EA5E9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            label: 'TEST TOPSHIRISHLAR',
            value: '1,420 ta test',
            icon: Icons.assignment_turned_in_outlined,
            color: const Color(0xFFA855F7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.badgeText.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Module Card Builder
  Widget _buildAdminModuleCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          hoverColor: accentColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTextStyles.badgeText.copyWith(
                          fontSize: 11,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleHeader.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DIALOG MODALS FOR ADMINISTRATOR ACTIONS ---

  // 2. TEST NATIJALARI DIALOG
  void _showTestResultsDialog(BuildContext context) {
    _showAdminModal(
      context: context,
      title: 'TEST NATIJALARI VA SKANNERLASH',
      icon: Icons.fact_check_outlined,
      accentColor: AppColors.emeraldAccent,
      child: Column(
        children: [
          _buildResultRow('10-25-guruh', 'Informatika diagnostikasi', '88% O\'zlashtirish', '25 ta test'),
          const SizedBox(height: 8),
          _buildResultRow('1-O\'quv guruhi', 'Matematika nazorati', '76% O\'zlashtirish', '22 ta test'),
          const SizedBox(height: 8),
          _buildResultRow('2-O\'quv guruhi', 'Fizika va texnika', '82% O\'zlashtirish', '24 ta test'),
        ],
      ),
    );
  }

  // 3. USER YARATISH DIALOG
  void _showCreateUserDialog(BuildContext context) {
    _showAdminModal(
      context: context,
      title: 'YANGI FOYDALANUVCHI (USER) YARATISH',
      icon: Icons.person_add_alt_1_outlined,
      accentColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModalTextField(label: 'F.I.SH. (TO\'LIQ ISM)', hint: 'Masalan: Narzullaev Daler Baxrullaevich'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildModalTextField(label: 'LOGIN', hint: 'student_1025')),
              const SizedBox(width: 12),
              Expanded(child: _buildModalTextField(label: 'PAROL', hint: '••••••••')),
            ],
          ),
          const SizedBox(height: 12),
          _buildModalTextField(label: 'ROLI', hint: 'O\'quvchi / O\'qituvchi / Admin'),
        ],
      ),
    );
  }

  // 5. KURS BOSQICHI DIALOG
  void _showCourseLevelDialog(BuildContext context) {
    _showAdminModal(
      context: context,
      title: 'KURS BOSQICHLARI',
      icon: Icons.stairs_outlined,
      accentColor: const Color(0xFF0EA5E9),
      child: Column(
        children: [
          _buildSimpleListItem('1-Kurs bosqichi', '120 ta o\'quvchi • 6 ta guruh'),
          const SizedBox(height: 8),
          _buildSimpleListItem('2-Kurs bosqichi', '130 ta o\'quvchi • 6 ta guruh'),
        ],
      ),
    );
  }

  // 6. GURUHLAR BOSHQARUVI DIALOG
  void _showGroupManagementDialog(BuildContext context) {
    _showAdminModal(
      context: context,
      title: 'GURUHLAR BOSHQARUVI',
      icon: Icons.groups_3_outlined,
      accentColor: const Color(0xFFA855F7),
      child: Column(
        children: [
          _buildSimpleListItem('10-25-guruh o\'quvchilari', 'Informatika va AT yo\'nalishi'),
          const SizedBox(height: 8),
          _buildSimpleListItem('1-O\'quv guruhi', 'Aniqlik va tabiiy fanlar'),
          const SizedBox(height: 8),
          _buildSimpleListItem('2-O\'quv guruhi', 'Ijtimoiy-gumanitar yo\'nalish'),
        ],
      ),
    );
  }

  // 7. KAFEDRALAR DIALOG
  void _showDepartmentDialog(BuildContext context) {
    _showAdminModal(
      context: context,
      title: 'LITSEY KAFEDRALARI',
      icon: Icons.account_balance_outlined,
      accentColor: AppColors.emeraldAccent,
      child: Column(
        children: [
          _buildSimpleListItem('Informatika va axborot texnologiyalari kafedrasi', 'Mamasarulov Sharof'),
          const SizedBox(height: 8),
          _buildSimpleListItem('Aniqlik va tabiiy fanlar kafedrasi', 'Matematika, Fizika'),
          const SizedBox(height: 8),
          _buildSimpleListItem('Tillar va ijtimoiy fanlar kafedrasi', 'O\'zbek tili, Rus tili, Ingliz tili'),
        ],
      ),
    );
  }

  // 8. FANLAR VA MAVZULAR DIALOG
  void _showSubjectDialog(BuildContext context) {
    _showAdminModal(
      context: context,
      title: 'O\'QUV FANLARI KATALOGI',
      icon: Icons.menu_book_outlined,
      accentColor: AppColors.goldPrimary,
      child: Column(
        children: [
          _buildSimpleListItem('Informatika va AT', '25 ta mavzuli diagnostika testi'),
          const SizedBox(height: 8),
          _buildSimpleListItem('Matematika (Algebra/Geometriya)', '30 ta mavzuli test'),
          const SizedBox(height: 8),
          _buildSimpleListItem('Fizika', '20 ta diagnostika testi'),
        ],
      ),
    );
  }

  // 9. TAHLIL DIALOG
  void _showAnalysisDialog(BuildContext context) {
    _showAdminModal(
      context: context,
      title: 'BILIMDAGI BO\'SHLIQLAR TAHLILI',
      icon: Icons.psychology_outlined,
      accentColor: const Color(0xFFEC4899),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Algebra: 90% | Geometriya: 75% | Trigonometriya: 40%', style: AppTextStyles.bodyText),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tavsiya etiladi: Trigonometriya va funksiyalar bo\'yicha individual o\'quv materiallari berilsin.',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.goldPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 10. STATISTIKA DIALOG
  void _showStatisticsDialog(BuildContext context) {
    _showAdminModal(
      context: context,
      title: 'STATISTIKA VA MONITORING',
      icon: Icons.bar_chart_rounded,
      accentColor: const Color(0xFF3B82F6),
      child: Column(
        children: [
          _buildSimpleListItem('Umumiy o\'zlashtirish ko\'rsatkichi', '84.2% (Yuqori dinamika)'),
          const SizedBox(height: 8),
          _buildSimpleListItem('Eng yuqori ko\'rsatkichli guruh', '10-25-guruh (92% natija)'),
        ],
      ),
    );
  }

  // Helper Modal Window
  void _showAdminModal({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: child,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('BEKOR QILISH', style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: AppColors.backgroundDark,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('SAQLASH / SAQLANDI'),
          ),
        ],
      ),
    );
  }

  Widget _buildModalTextField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.badgeText.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.goldPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String group, String subject, String score, String count) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(subject, style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score, style: AppTextStyles.badgeText.copyWith(color: AppColors.emeraldAccent)),
              Text(count, style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleListItem(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(subtitle, style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.goldPrimary),
        ],
      ),
    );
  }
}
