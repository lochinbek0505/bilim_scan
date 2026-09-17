import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/authenticated_image.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/catalog_response.dart';
import '../../models/guruh_model.dart';
import '../../models/user_create_dto.dart';
import '../../models/user_response_dto.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/file_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Active Role Tab (Default to O'QUVCHILAR 'USER')
  String _activeRole = 'USER'; // 'USER', 'TEACHER', 'ADMIN'

  // Hierarchical Drill-Down State for O'quvchilar (USER)
  CatalogResponse? _selectedBosqich;
  GuruhModel? _selectedGuruh;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final catalogProvider = Provider.of<CatalogProvider>(context);

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
                'FOYDALANUVCHILARNI BOSHQARISH (USERS CRUD)',
                style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textPrimary),
              ),
              Text(
                'O\'quvchilar (Bosqich va Guruhlar bo\'yicha), O\'qituvchilar hamda Administratorlar',
                style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.goldPrimary),
              tooltip: 'Ma\'lumotlarni yangilash',
              onPressed: () {
                userProvider.fetchUsers();
                catalogProvider.fetchAllCatalogs();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18, color: AppColors.backgroundDark),
                label: Text('YANGI USER YARATISH', style: AppTextStyles.buttonText.copyWith(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => _showUserFormDialog(context, null, catalogProvider, userProvider),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Role Filter Tabs (USER, TEACHER, ADMIN)
              _buildRoleHeaderTabs(userProvider),

              const SizedBox(height: 16),

              // Main Body Content (Hierarchical for USER, Direct for TEACHER/ADMIN)
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.goldPrimary,
                  backgroundColor: AppColors.cardDark,
                  onRefresh: () async {
                    await userProvider.fetchUsers();
                    await catalogProvider.fetchAllCatalogs();
                  },
                  child: _activeRole == 'USER'
                      ? _buildOquvchilarHierarchicalView(userProvider, catalogProvider)
                      : _buildDirectUserList(userProvider, catalogProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ROLE HEADER TABS (NO "BARCHASI")
  Widget _buildRoleHeaderTabs(UserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.setSearchQuery(val),
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'F.I.SH. yoki Username bo\'yicha qidirish...',
                    hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.goldPrimary, size: 20),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.goldPrimary)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildRoleSegmentChip('🎓 O\'QUVCHILAR (KURSANTLAR)', 'USER', provider),
              const SizedBox(width: 10),
              _buildRoleSegmentChip('👨‍🏫 O\'QITUVCHILAR (TEACHER)', 'TEACHER', provider),
              const SizedBox(width: 10),
              _buildRoleSegmentChip('🛡️ ADMINLAR (ADMIN)', 'ADMIN', provider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSegmentChip(String label, String roleCode, UserProvider provider) {
    final isSelected = _activeRole == roleCode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeRole = roleCode;
            _selectedBosqich = null;
            _selectedGuruh = null;
          });
          provider.setRoleFilter(roleCode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.goldPrimary : AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.badgeText.copyWith(
              fontSize: 12,
              color: isSelected ? AppColors.backgroundDark : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // HIERARCHICAL DRILL-DOWN VIEW FOR O'QUVCHILAR (USER)
  // Step 1: Bosqichlar -> Step 2: Guruhlar -> Step 3: Kursantlar
  Widget _buildOquvchilarHierarchicalView(UserProvider userProvider, CatalogProvider catalogProvider) {
    // STEP 1: Select Bosqich
    if (_selectedBosqich == null) {
      return _buildBosqichlarListStep(userProvider, catalogProvider);
    }

    // STEP 2: Select Guruh
    if (_selectedGuruh == null) {
      return _buildGuruhlarListStep(userProvider, catalogProvider);
    }

    // STEP 3: List Kursantlar for Selected Guruh
    return _buildKursantlarListStep(userProvider, catalogProvider);
  }

  // STEP 1: BOSQICHLAR RO'YXATI (COMPACT ELEGANT CARDS)
  Widget _buildBosqichlarListStep(UserProvider userProvider, CatalogProvider catalogProvider) {
    final bosqichlar = catalogProvider.bosqichlar;

    if (bosqichlar.isEmpty) {
      return _buildEmptyState('KURS BOSQICHI TOPILMADI', 'Kataloglar menyusida bosqich yaratilganiga ishonch hosil qiling');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.stairs_outlined, color: AppColors.goldPrimary, size: 18),
              const SizedBox(width: 10),
              Text(
                '1-BOSQICH: KURS BOSQICHINI TANLANG',
                style: AppTextStyles.badgeText.copyWith(color: AppColors.goldPrimary, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 3.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: bosqichlar.length,
            itemBuilder: (context, index) {
              final b = bosqichlar[index];

              final guruhCount = catalogProvider.guruhlar.where((g) => g.bosqich?.id == b.id).length;
              final studentCount = userProvider.users.where((u) => u.role == 'USER' && u.bosqich?.id == b.id).length;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedBosqich = b;
                        _selectedGuruh = null;
                      });
                    },
                    hoverColor: AppColors.goldPrimary.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.goldPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.stairs_outlined, color: AppColors.goldPrimary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(b.name ?? 'Bosqich', style: AppTextStyles.titleHeader.copyWith(fontSize: 14, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildBadge(Icons.groups_3_outlined, '$guruhCount guruh', AppColors.info),
                                    const SizedBox(width: 6),
                                    _buildBadge(Icons.school_outlined, '$studentCount o\'quvchi', AppColors.emeraldAccent),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: AppColors.goldPrimary, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // STEP 2: GURUHLAR RO'YXATI (COMPACT ELEGANT CARDS)
  Widget _buildGuruhlarListStep(UserProvider userProvider, CatalogProvider catalogProvider) {
    final filteredGuruhlar = catalogProvider.guruhlar.where((g) {
      if (_selectedBosqich == null) return true;
      return g.bosqich?.id == _selectedBosqich!.id;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BREADCRUMB BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back, size: 13, color: AppColors.goldPrimary),
                label: const Text('BOSQICHLARGA QAYTISH', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.goldPrimary),
                  foregroundColor: AppColors.goldPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () {
                  setState(() {
                    _selectedBosqich = null;
                    _selectedGuruh = null;
                  });
                },
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_selectedBosqich?.name ?? ''}  👉  2-BOSQICH: GURUHNIBI TANLANG',
                style: AppTextStyles.badgeText.copyWith(color: AppColors.emeraldAccent, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filteredGuruhlar.isEmpty)
          Expanded(child: _buildEmptyState('GURUHLAR TOPILMADI', '${_selectedBosqich?.name} bo\'yicha biror guruh biriktirilmagan'))
        else
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 3.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredGuruhlar.length,
              itemBuilder: (context, index) {
                final g = filteredGuruhlar[index];
                final studentCount = userProvider.users.where((u) => u.role == 'USER' && u.guruh?.id == g.id).length;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedGuruh = g;
                        });
                      },
                      hoverColor: AppColors.emeraldAccent.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.groups_3_outlined, color: AppColors.emeraldAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(g.name ?? 'Guruh', style: AppTextStyles.titleHeader.copyWith(fontSize: 14, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  _buildBadge(Icons.school_outlined, '$studentCount o\'quvchi', AppColors.emeraldAccent),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: AppColors.emeraldAccent, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // STEP 3: KURSANTLAR RO'YXATI
  Widget _buildKursantlarListStep(UserProvider userProvider, CatalogProvider catalogProvider) {
    final filteredStudents = userProvider.users.where((u) {
      if (u.role != 'USER') return false;
      return u.guruh?.id == _selectedGuruh!.id;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BREADCRUMB BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.emeraldAccent.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back, size: 13, color: AppColors.emeraldAccent),
                label: const Text('GURUHLARGA QAYTISH', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.emeraldAccent),
                  foregroundColor: AppColors.emeraldAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () {
                  setState(() {
                    _selectedGuruh = null;
                  });
                },
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_selectedBosqich?.name ?? ''}  👉  ${_selectedGuruh?.name ?? ''}  👉  3-BOSQICH: KURSANTLAR (${filteredStudents.length} TA)',
                style: AppTextStyles.badgeText.copyWith(color: AppColors.goldPrimary, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filteredStudents.isEmpty)
          Expanded(child: _buildEmptyState('KURSANTLAR TOPILMADI', '${_selectedGuruh?.name} guruhida hozircha o\'quvchi yaratilmagan'))
        else
          Expanded(
            child: ListView.separated(
              itemCount: filteredStudents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = filteredStudents[index];
                return _buildUserCard(context, user, userProvider, catalogProvider);
              },
            ),
          ),
      ],
    );
  }

  // DIRECT USER LIST VIEW FOR TEACHER OR ADMIN
  Widget _buildDirectUserList(UserProvider userProvider, CatalogProvider catalogProvider) {
    final directUsers = userProvider.users.where((u) => u.role == _activeRole).toList();

    if (directUsers.isEmpty) {
      final roleTitle = _activeRole == 'TEACHER' ? 'O\'QITUVCHILAR' : 'ADMINISTRATORLAR';
      return _buildEmptyState('$roleTitle TOPILMADI', 'Yangi foydalanuvchi yaratish uchun "+ YANGI USER YARATISH" tugmasini bosing');
    }

    return ListView.separated(
      itemCount: directUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = directUsers[index];
        return _buildUserCard(context, user, userProvider, catalogProvider);
      },
    );
  }

  Widget _buildEmptyState([String title = 'HECH QANDAY USER TOPILMADI', String subtitle = 'Yangi user yaratish uchun "+ YANGI USER YARATISH" tugmasini bosing']) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.titleHeader.copyWith(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // USER CARD WITH Sleek CIRCULAR PROFILE AVATAR
  Widget _buildUserCard(
    BuildContext context,
    UserResponseDto user,
    UserProvider provider,
    CatalogProvider catalogProvider,
  ) {
    final roleColor = _getRoleColor(user.role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Profile Avatar with Role Ring & Initials Fallback
          AuthenticatedImage(
            imageUrl: user.profileImageUrl,
            name: user.fullName,
            width: 50,
            height: 50,
            borderColor: roleColor,
          ),

          const SizedBox(width: 14),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.fullName,
                      style: AppTextStyles.titleHeader.copyWith(fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: roleColor),
                      ),
                      child: Text(
                        user.role ?? 'USER',
                        style: AppTextStyles.badgeText.copyWith(fontSize: 9, color: roleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('@${user.username ?? '---'}', style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.goldPrimary)),
                const SizedBox(height: 6),

                // ROLE-SPECIFIC BADGES
                if (user.role == 'USER') ...[
                  Row(
                    children: [
                      _buildBadge(Icons.stairs_outlined, 'Bosqich: ${user.bosqich?.name ?? 'Biriktirilmagan'}', AppColors.info),
                      const SizedBox(width: 6),
                      _buildBadge(Icons.groups_3_outlined, 'Guruh: ${user.guruh?.name ?? 'Biriktirilmagan'}', AppColors.emeraldAccent),
                    ],
                  ),
                ] else if (user.role == 'TEACHER') ...[
                  Row(
                    children: [
                      _buildBadge(Icons.account_balance_outlined, 'Kafedra: ${user.kafedra?.name ?? 'Biriktirilmagan'}', const Color(0xFFA855F7)),
                      const SizedBox(width: 6),
                      _buildBadge(Icons.menu_book_outlined, 'Fan: ${user.fan?.name ?? 'Biriktirilmagan'}', AppColors.goldPrimary),
                    ],
                  ),
                ] else ...[
                  _buildBadge(Icons.shield_outlined, 'Tizim Administratori', AppColors.warning),
                ],
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.goldPrimary, size: 18),
                tooltip: 'Tahrirlash',
                onPressed: () => _showUserFormDialog(context, user, catalogProvider, provider),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                tooltip: 'O\'chirish',
                onPressed: () => _confirmDeleteDialog(context, user.id ?? '', provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.badgeText.copyWith(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    if (role == 'ADMIN') return AppColors.warning;
    if (role == 'TEACHER') return const Color(0xFFA855F7);
    return AppColors.emeraldAccent; // USER
  }

  // CASCADING & CONDITIONAL USER FORM DIALOG WITH MANDATORY NATIVE FILE PICKER
  void _showUserFormDialog(
    BuildContext context,
    UserResponseDto? userToEdit,
    CatalogProvider catalogProvider,
    UserProvider userProvider,
  ) {
    final usernameController = TextEditingController(text: userToEdit?.username ?? '');
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController(text: userToEdit?.firstName ?? '');
    final lastNameController = TextEditingController(text: userToEdit?.lastName ?? '');
    final patronymicController = TextEditingController(text: userToEdit?.patronymic ?? '');

    String selectedRole = userToEdit?.role ?? 'USER';
    String? currentProfileImageUrl = userToEdit?.profileImageUrl;
    bool isUploadingImage = false;
    String? imageUploadError;

    // Cascading selection IDs
    String? selectedBosqichId = userToEdit?.bosqich?.id ?? (_selectedBosqich?.id ?? (catalogProvider.bosqichlar.isNotEmpty ? catalogProvider.bosqichlar.first.id : null));
    String? selectedGuruhId = userToEdit?.guruh?.id ?? (_selectedGuruh?.id ?? (catalogProvider.guruhlar.isNotEmpty ? catalogProvider.guruhlar.first.id : null));

    String? selectedKafedraId = userToEdit?.kafedra?.id ?? (catalogProvider.kafedralar.isNotEmpty ? catalogProvider.kafedralar.first.id : null);
    String? selectedFanId = userToEdit?.fan?.id ?? (catalogProvider.fanlar.isNotEmpty ? catalogProvider.fanlar.first.id : null);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredGuruhlar = catalogProvider.guruhlar.where((g) {
            if (selectedBosqichId == null) return true;
            return g.bosqich?.id == null || g.bosqich?.id == selectedBosqichId;
          }).toList();

          final filteredFanlar = catalogProvider.fanlar.where((f) {
            if (selectedKafedraId == null) return true;
            return f.kafedra?.id == null || f.kafedra?.id == selectedKafedraId;
          }).toList();

          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
            ),
            title: Row(
              children: [
                Icon(userToEdit == null ? Icons.person_add_alt_1_outlined : Icons.manage_accounts_outlined, color: AppColors.goldPrimary),
                const SizedBox(width: 10),
                Text(
                  userToEdit == null ? 'YANGI USER YARATISH' : 'USER MA\'LUMOTLARINI TAHRIRLASH',
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
                    // MANDATORY PROFILE IMAGE UPLOAD SECTION (FILE PICKER)
                    _buildFormLabel('PROFIL RASMI (MAJBURIY *)'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (currentProfileImageUrl == null || currentProfileImageUrl!.isEmpty)
                              ? AppColors.error
                              : AppColors.emeraldAccent,
                        ),
                      ),
                      child: Row(
                        children: [
                          AuthenticatedImage(
                            imageUrl: currentProfileImageUrl,
                            name: '${firstNameController.text} ${lastNameController.text}',
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: isUploadingImage
                                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                          : const Icon(Icons.folder_open_outlined, size: 16),
                                      label: Text(isUploadingImage ? 'YUKLANMOQDA...' : 'KOMPYUTERDAN TANLASH'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.backgroundDark),
                                      onPressed: isUploadingImage
                                          ? null
                                          : () async {
                                              try {
                                                setModalState(() {
                                                  isUploadingImage = true;
                                                  imageUploadError = null;
                                                });

                                                // Native macOS / Desktop File Picker
                                                final PlatformFile? file = await FilePicker.pickFile(
                                                  type: FileType.custom,
                                                  allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
                                                );

                                                if (file != null) {
                                                  String? uploadedUrl;

                                                  if (file.path != null && file.path!.isNotEmpty) {
                                                    uploadedUrl = await FileService().uploadProfileImageFile(file.path!);
                                                  } else {
                                                    final bytes = await file.readAsBytes();
                                                    uploadedUrl = await FileService().uploadProfileImageBytes(bytes, file.name);
                                                  }

                                                  setModalState(() {
                                                    isUploadingImage = false;
                                                    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                                                      currentProfileImageUrl = uploadedUrl;
                                                    } else {
                                                      // Fallback for local demo if server endpoint is offline
                                                      currentProfileImageUrl = '/uploads/profiles/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                                                    }
                                                  });
                                                } else {
                                                  setModalState(() {
                                                    isUploadingImage = false;
                                                  });
                                                }
                                              } catch (e) {
                                                setModalState(() {
                                                  isUploadingImage = false;
                                                  imageUploadError = 'Faylni tanlashda xatolik: $e';
                                                });
                                              }
                                            },
                                    ),
                                    const SizedBox(width: 8),
                                    if (currentProfileImageUrl != null && currentProfileImageUrl!.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                        onPressed: () => setModalState(() => currentProfileImageUrl = null),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentProfileImageUrl != null && currentProfileImageUrl!.isNotEmpty
                                      ? 'Yuklangan fayl: $currentProfileImageUrl'
                                      : 'Kompyuterdan rasm faylini (.png, .jpg) tanlang',
                                  style: AppTextStyles.bodyText.copyWith(
                                    fontSize: 11,
                                    color: currentProfileImageUrl != null && currentProfileImageUrl!.isNotEmpty ? AppColors.emeraldAccent : AppColors.textMuted,
                                  ),
                                ),
                                if (imageUploadError != null) ...[
                                  const SizedBox(height: 4),
                                  Text(imageUploadError!, style: AppTextStyles.bodyText.copyWith(fontSize: 11, color: AppColors.error)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ROLE SELECTION DROPDOWN
                    _buildFormLabel('FOYDALANUVCHI ROLI (ROLE)'),
                    const SizedBox(height: 4),
                    _buildDropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: AppColors.cardDark,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'USER', child: Text('O\'quvchi / Kursant (USER)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                            DropdownMenuItem(value: 'TEACHER', child: Text('O\'qituvchi / Nazoratchi (TEACHER)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                            DropdownMenuItem(value: 'ADMIN', child: Text('Administrator (ADMIN)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedRole = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // FULL NAME FIELDS
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('FAMILIYASI (LAST NAME)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: lastNameController,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('Narzullaev'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('ISMI (FIRST NAME)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: firstNameController,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('Daler'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildFormLabel('OTASINING ISMI (PATRONYMIC)'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: patronymicController,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Baxrullaevich'),
                    ),

                    const SizedBox(height: 14),

                    // AUTO-GENERATOR & COPY TOOLBAR
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('⚡ F.I.O DAN GENERATSIYA QILISH'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldPrimary,
                                foregroundColor: AppColors.backgroundDark,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              onPressed: () {
                                String clean(String str) {
                                  return str.trim().toLowerCase()
                                      .replaceAll('ʻ', '')
                                      .replaceAll("'", '')
                                      .replaceAll('`', '')
                                      .replaceAll(' ', '_');
                                }

                                final fn = clean(firstNameController.text);
                                final ln = clean(lastNameController.text);

                                if (fn.isEmpty && ln.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('⚠️ Iltimos, oldin Ismi va Familiyasini kiriting!'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  return;
                                }

                                String genUsername = '';
                                if (fn.isNotEmpty && ln.isNotEmpty) {
                                  genUsername = '${fn}_$ln';
                                } else if (ln.isNotEmpty) {
                                  genUsername = ln;
                                } else {
                                  genUsername = fn;
                                }

                                final randomPin = (100000 + DateTime.now().microsecondsSinceEpoch % 900000);
                                final fnCap = fn.isNotEmpty ? fn[0].toUpperCase() + fn.substring(1) : 'User';
                                final genPassword = '$fnCap@$randomPin';

                                setModalState(() {
                                  usernameController.text = genUsername;
                                  passwordController.text = genPassword;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('⚡ Generatsiya qilindi: $genUsername / $genPassword'),
                                    backgroundColor: AppColors.emeraldAccent,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('📋 NUSXALASH'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.emeraldAccent,
                              side: const BorderSide(color: AppColors.emeraldAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onPressed: () {
                              final u = usernameController.text.trim();
                              final p = passwordController.text.trim();
                              if (u.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('⚠️ Username hali kiritilmagan!'), backgroundColor: AppColors.warning),
                                );
                                return;
                              }
                              final textToCopy = 'Login: $u\nParol: $p';
                              Clipboard.setData(ClipboardData(text: textToCopy));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✔ Nusxalandi:\n$textToCopy'),
                                  backgroundColor: AppColors.emeraldAccent,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // LOGIN & PASSWORD ROW WITH COPY SUFFIX ICONS
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('LOGIN (USERNAME)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: usernameController,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration(
                                  'Masalan: daler_narzullaev',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: AppColors.goldPrimary),
                                    tooltip: 'Username\'ni nusxalash',
                                    onPressed: () {
                                      if (usernameController.text.isNotEmpty) {
                                        Clipboard.setData(ClipboardData(text: usernameController.text));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✔ Username nusxalandi!'), backgroundColor: AppColors.goldPrimary),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('PAROL (PASSWORD)'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: passwordController,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration(
                                  userToEdit == null ? '••••••••' : 'O\'zgarmaydi (ixtiyoriy)',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: AppColors.goldPrimary),
                                    tooltip: 'Parolni nusxalash',
                                    onPressed: () {
                                      if (passwordController.text.isNotEmpty) {
                                        Clipboard.setData(ClipboardData(text: passwordController.text));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✔ Parol nusxalandi!'), backgroundColor: AppColors.goldPrimary),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // CASCADING DROPDOWNS FOR USER (O'QUVCHI -> BOSQICH & GURUH)
                    if (selectedRole == 'USER') ...[
                      const SizedBox(height: 18),
                      const Divider(color: AppColors.cardBorder),
                      const SizedBox(height: 10),

                      Text('O\'QUVCHI MA\'LUMOTLARI (BOSQICH VA GURUH KETMA-KETLIGI):', style: AppTextStyles.badgeText.copyWith(color: AppColors.emeraldAccent, fontSize: 11)),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Step 1: Bosqich
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('1. KURS BOSQICHI (bosqichId)'),
                                const SizedBox(height: 4),
                                _buildDropdownContainer(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: selectedBosqichId,
                                      dropdownColor: AppColors.cardDark,
                                      isExpanded: true,
                                      hint: const Text('Bosqichni tanlang', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                      items: catalogProvider.bosqichlar.map((b) {
                                        return DropdownMenuItem<String?>(value: b.id, child: Text(b.name ?? 'Bosqich', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                      }).toList(),
                                      onChanged: (val) {
                                        setModalState(() {
                                          selectedBosqichId = val;
                                          selectedGuruhId = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Step 2: Guruh (Cascading)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('2. O\'QUV GURUHI (guruhId)'),
                                const SizedBox(height: 4),
                                _buildDropdownContainer(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: filteredGuruhlar.any((g) => g.id == selectedGuruhId) ? selectedGuruhId : null,
                                      dropdownColor: AppColors.cardDark,
                                      isExpanded: true,
                                      hint: const Text('Guruhni tanlang', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                      items: filteredGuruhlar.map((g) {
                                        return DropdownMenuItem<String?>(value: g.id, child: Text(g.name ?? 'Guruh', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                      }).toList(),
                                      onChanged: (val) {
                                        setModalState(() => selectedGuruhId = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // CASCADING DROPDOWNS FOR TEACHER (O'QITUVCHI -> KAFEDRA & FAN)
                    if (selectedRole == 'TEACHER') ...[
                      const SizedBox(height: 18),
                      const Divider(color: AppColors.cardBorder),
                      const SizedBox(height: 10),

                      Text('O\'QITUVCHI MA\'LUMOTLARI (KAFEDRA VA FAN KETMA-KETLIGI):', style: AppTextStyles.badgeText.copyWith(color: const Color(0xFFA855F7), fontSize: 11)),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Step 1: Kafedra
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('1. KAFEDRA (kafedraId)'),
                                const SizedBox(height: 4),
                                _buildDropdownContainer(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: selectedKafedraId,
                                      dropdownColor: AppColors.cardDark,
                                      isExpanded: true,
                                      hint: const Text('Kafedrani tanlang', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                      items: catalogProvider.kafedralar.map((k) {
                                        return DropdownMenuItem<String?>(value: k.id, child: Text(k.name ?? 'Kafedra', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                      }).toList(),
                                      onChanged: (val) {
                                        setModalState(() {
                                          selectedKafedraId = val;
                                          selectedFanId = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Step 2: Fan (Cascading)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('2. O\'QUV FANI (fanId)'),
                                const SizedBox(height: 4),
                                _buildDropdownContainer(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: filteredFanlar.any((f) => f.id == selectedFanId) ? selectedFanId : null,
                                      dropdownColor: AppColors.cardDark,
                                      isExpanded: true,
                                      hint: const Text('Fanni tanlang', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                      items: filteredFanlar.map((f) {
                                        return DropdownMenuItem<String?>(value: f.id, child: Text(f.name ?? 'Fan', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)));
                                      }).toList(),
                                      onChanged: (val) {
                                        setModalState(() => selectedFanId = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.backgroundDark),
                onPressed: () async {
                  final username = usernameController.text.trim();
                  if (username.isEmpty) return;

                  // MANDATORY PROFILE IMAGE VALIDATION
                  if (currentProfileImageUrl == null || currentProfileImageUrl!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Profil rasmi yuklanishi majburiy! Kompyuterizdan rasm faylini tanlang.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  final dto = UserCreateDto(
                    username: username,
                    password: passwordController.text.trim(),
                    role: selectedRole,
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    patronymic: patronymicController.text.trim(),
                    profileImageUrl: currentProfileImageUrl,
                    bosqichId: selectedRole == 'USER' ? selectedBosqichId : null,
                    guruhId: selectedRole == 'USER' ? selectedGuruhId : null,
                    kafedraId: selectedRole == 'TEACHER' ? selectedKafedraId : null,
                    fanId: selectedRole == 'TEACHER' ? selectedFanId : null,
                  );

                  if (userToEdit == null) {
                    await userProvider.createUser(dto);
                  } else {
                    await userProvider.updateUser(userToEdit.id ?? '', dto);
                  }

                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: Text(userToEdit == null ? 'YARATISH' : 'SAQLASH'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteDialog(BuildContext context, String id, UserProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('USERNI O\'CHIRISH', style: AppTextStyles.titleHeader.copyWith(color: AppColors.error)),
        content: Text('Haqiqatan ham ushbu foydalanuvchini o\'chirib tashlamoqchimisiz?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('BEKOR QILISH')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await provider.deleteUser(id);
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

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.inputBackground,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.goldPrimary)),
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
