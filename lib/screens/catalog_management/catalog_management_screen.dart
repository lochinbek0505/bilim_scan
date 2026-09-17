import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/tactical_background.dart';
import '../../models/catalog_response.dart';
import '../../models/fan_model.dart';
import '../../models/guruh_model.dart';
import '../../providers/catalog_provider.dart';

class CatalogManagementScreen extends StatefulWidget {
  final int initialTabIndex;

  const CatalogManagementScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CatalogManagementScreen> createState() =>
      _CatalogManagementScreenState();
}

class _CatalogManagementScreenState extends State<CatalogManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogProvider = Provider.of<CatalogProvider>(context);

    return TacticalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary.withValues(
            alpha: 0.95,
          ),
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.goldPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KATALOGLAR BOSHQARUVI (CRUD)',
                style: AppTextStyles.titleHeader.copyWith(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Bosqichlar, fanlar, guruhlar hamda kafedralar ma\'lumotnomalari',
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.goldPrimary),
              tooltip: 'Ma\'lumotlarni yangilash',
              onPressed: () {
                catalogProvider.fetchAllCatalogs();
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.goldPrimary,
            labelColor: AppColors.goldPrimary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: AppTextStyles.badgeText.copyWith(fontSize: 12),
            tabs: const [
              Tab(
                icon: Icon(Icons.stairs_outlined, size: 18),
                text: 'KURS BOSQICHI',
              ),
              Tab(
                icon: Icon(Icons.menu_book_outlined, size: 18),
                text: 'FANLAR',
              ),
              Tab(
                icon: Icon(Icons.groups_3_outlined, size: 18),
                text: 'GURUHLAR',
              ),
              Tab(
                icon: Icon(Icons.account_balance_outlined, size: 18),
                text: 'KAFEDRALAR',
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Search & Add Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => catalogProvider.setSearchQuery(val),
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nomi bo\'yicha qidirish...',
                          hintStyle: AppTextStyles.bodyText.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.goldPrimary,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: AppColors.backgroundDark,
                      ),
                      label: Text(
                        'YANGI QO\'SHISH',
                        style: AppTextStyles.buttonText.copyWith(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        final currentType =
                            CatalogType.values[_tabController.index];
                        _showCreateOrEditDialog(context, currentType, null);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // TabBar View for Catalogs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCatalogResponseList(
                      context,
                      catalogProvider.bosqichlar,
                      CatalogType.bosqich,
                      catalogProvider,
                    ),
                    _buildFanList(
                      context,
                      catalogProvider.fanlar,
                      catalogProvider,
                    ),
                    _buildGuruhList(
                      context,
                      catalogProvider.guruhlar,
                      catalogProvider,
                    ),
                    _buildCatalogResponseList(
                      context,
                      catalogProvider.kafedralar,
                      CatalogType.kafedra,
                      catalogProvider,
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

  // Generic List for Bosqichlar & Kafedralar
  Widget _buildCatalogResponseList(
    BuildContext context,
    List<CatalogResponse> items,
    CatalogType type,
    CatalogProvider provider,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(type.title);
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCardItem(
          title: item.name ?? 'Nomsiz',
          subtitle: 'ID: ${item.id ?? '---'}',
          icon: _getIconForType(type),
          onEdit: () => _showCreateOrEditDialog(context, type, item),
          onDelete: () =>
              _confirmDeleteDialog(context, type, item.id ?? '', provider),
        );
      },
    );
  }

  // Fanlar List View (FanModel with Kafedra)
  Widget _buildFanList(
    BuildContext context,
    List<FanModel> items,
    CatalogProvider provider,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState('FANLAR');
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCardItem(
          title: item.name ?? 'Nomsiz',
          subtitle:
              'Kafedra: ${item.kafedra?.name ?? 'Biriktirilmagan'} • ID: ${item.id ?? '---'}',
          icon: Icons.menu_book_outlined,
          onEdit: () => _showCreateOrEditDialog(context, CatalogType.fan, item),
          onDelete: () => _confirmDeleteDialog(
            context,
            CatalogType.fan,
            item.id ?? '',
            provider,
          ),
        );
      },
    );
  }

  // Guruhlar List View (GuruhModel with Bosqich)
  Widget _buildGuruhList(
    BuildContext context,
    List<GuruhModel> items,
    CatalogProvider provider,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState('GURUHLAR');
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCardItem(
          title: item.name ?? 'Nomsiz',
          subtitle:
              'Bosqich: ${item.bosqich?.name ?? 'Biriktirilmagan'} • ID: ${item.id ?? '---'}',
          icon: Icons.groups_3_outlined,
          onEdit: () =>
              _showCreateOrEditDialog(context, CatalogType.guruh, item),
          onDelete: () => _confirmDeleteDialog(
            context,
            CatalogType.guruh,
            item.id ?? '',
            provider,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 54,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '$title bo\'yicha ma\'lumot topilmadi',
            style: AppTextStyles.titleHeader.copyWith(
              fontSize: 16,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Yangi element qo\'shish uchun "+ YANGI QO\'SHISH" tugmasini bosing',
            style: AppTextStyles.bodyText.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.goldPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleHeader.copyWith(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyText.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.goldPrimary,
                  size: 20,
                ),
                tooltip: 'Tahrirlash',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                tooltip: 'O\'chirish',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(CatalogType type) {
    switch (type) {
      case CatalogType.bosqich:
        return Icons.stairs_outlined;
      case CatalogType.fan:
        return Icons.menu_book_outlined;
      case CatalogType.guruh:
        return Icons.groups_3_outlined;
      case CatalogType.kafedra:
        return Icons.account_balance_outlined;
    }
  }

  // CREATE OR EDIT DIALOG (HANDLES BOSQICH DROPDOWN FOR GURUH & KAFEDRA DROPDOWN FOR FAN)
  void _showCreateOrEditDialog(
    BuildContext context,
    CatalogType type,
    dynamic itemToEdit,
  ) {
    final provider = Provider.of<CatalogProvider>(context, listen: false);

    String initialName = '';
    if (itemToEdit is CatalogResponse) initialName = itemToEdit.name ?? '';
    if (itemToEdit is FanModel) initialName = itemToEdit.name ?? '';
    if (itemToEdit is GuruhModel) initialName = itemToEdit.name ?? '';

    final nameController = TextEditingController(text: initialName);

    // Selected foreign IDs
    String? selectedBosqichId;
    if (type == CatalogType.guruh) {
      if (itemToEdit is GuruhModel && itemToEdit.bosqich?.id != null) {
        selectedBosqichId = itemToEdit.bosqich!.id;
      } else if (provider.bosqichlar.isNotEmpty) {
        selectedBosqichId = provider.bosqichlar.first.id;
      }
    }

    String? selectedKafedraId;
    if (type == CatalogType.fan) {
      if (itemToEdit is FanModel && itemToEdit.kafedra?.id != null) {
        selectedKafedraId = itemToEdit.kafedra!.id;
      } else if (provider.kafedralar.isNotEmpty) {
        selectedKafedraId = provider.kafedralar.first.id;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
            ),
            title: Row(
              children: [
                Icon(
                  itemToEdit == null
                      ? Icons.add_circle_outline
                      : Icons.edit_note,
                  color: AppColors.goldPrimary,
                ),
                const SizedBox(width: 10),
                Text(
                  itemToEdit == null
                      ? '${type.title}: YANGI QO\'SHISH'
                      : '${type.title}: TAHRIRLASH',
                  style: AppTextStyles.titleHeader.copyWith(fontSize: 15),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ELEMENT NOMI (NAME)',
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nomi (masalan: 10-25-guruh / Informatika)',
                      hintStyle: AppTextStyles.bodyText.copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                  ),

                  // DROPDOWN FOR GURUH -> BOSQICH TANLASH
                  if (type == CatalogType.guruh) ...[
                    const SizedBox(height: 14),
                    Text(
                      'KURS BOSQICHINI TANLANG (bosqichId)',
                      style: AppTextStyles.badgeText.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBosqichId,
                          dropdownColor: AppColors.cardDark,
                          isExpanded: true,
                          hint: const Text(
                            'Bosqichni tanlang',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          items: provider.bosqichlar.map((b) {
                            return DropdownMenuItem<String>(
                              value: b.id,
                              child: Text(
                                b.name ?? 'Bosqich',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setModalState(() => selectedBosqichId = val);
                          },
                        ),
                      ),
                    ),
                  ],

                  // DROPDOWN FOR FAN -> KAFEDRA TANLASH
                  if (type == CatalogType.fan) ...[
                    const SizedBox(height: 14),
                    Text(
                      'KAFEDRANI TANLANG (kafedraId)',
                      style: AppTextStyles.badgeText.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedKafedraId,
                          dropdownColor: AppColors.cardDark,
                          isExpanded: true,
                          hint: const Text(
                            'Kafedrani tanlang',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          items: provider.kafedralar.map((k) {
                            return DropdownMenuItem<String>(
                              value: k.id,
                              child: Text(
                                k.name ?? 'Kafedra',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setModalState(() => selectedKafedraId = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'BEKOR QILISH',
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: AppColors.backgroundDark,
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  if (itemToEdit == null) {
                    switch (type) {
                      case CatalogType.bosqich:
                        await provider.createBosqich(name);
                        break;
                      case CatalogType.fan:
                        if (selectedKafedraId != null) {
                          await provider.createFan(name, selectedKafedraId!);
                        }
                        break;
                      case CatalogType.guruh:
                        if (selectedBosqichId != null) {
                          await provider.createGuruh(name, selectedBosqichId!);
                        }
                        break;
                      case CatalogType.kafedra:
                        await provider.createKafedra(name);
                        break;
                    }
                  } else {
                    final id = (itemToEdit is CatalogResponse)
                        ? (itemToEdit.id ?? '')
                        : (itemToEdit is FanModel)
                        ? (itemToEdit.id ?? '')
                        : (itemToEdit is GuruhModel)
                        ? (itemToEdit.id ?? '')
                        : '';

                    switch (type) {
                      case CatalogType.bosqich:
                        await provider.updateBosqich(id, name);
                        break;
                      case CatalogType.fan:
                        if (selectedKafedraId != null) {
                          await provider.updateFan(
                            id,
                            name,
                            selectedKafedraId!,
                          );
                        }
                        break;
                      case CatalogType.guruh:
                        if (selectedBosqichId != null) {
                          await provider.updateGuruh(
                            id,
                            name,
                            selectedBosqichId!,
                          );
                        }
                        break;
                      case CatalogType.kafedra:
                        await provider.updateKafedra(id, name);
                        break;
                    }
                  }

                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(itemToEdit == null ? 'QO\'SHISH' : 'SAQLASH'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteDialog(
    BuildContext context,
    CatalogType type,
    String id,
    CatalogProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'O\'CHIRISH TASHDIQLASH',
          style: AppTextStyles.titleHeader.copyWith(color: AppColors.error),
        ),
        content: Text(
          'Haqiqatan ham ushbu elementni o\'chirib tashlamoqchimisiz?',
          style: AppTextStyles.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('BEKOR QILISH'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              switch (type) {
                case CatalogType.bosqich:
                  await provider.deleteBosqich(id);
                  break;
                case CatalogType.fan:
                  await provider.deleteFan(id);
                  break;
                case CatalogType.guruh:
                  await provider.deleteGuruh(id);
                  break;
                case CatalogType.kafedra:
                  await provider.deleteKafedra(id);
                  break;
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('O\'CHIRISH'),
          ),
        ],
      ),
    );
  }
}
