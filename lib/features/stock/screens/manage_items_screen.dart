import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../items/models/item_models.dart';
import '../../items/repository/items_repository.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  final _repository = ItemsRepository();
  List<StockItem> _normalItems = [];
  List<MapEntry<ItemCategory, List<StockItem>>> _categoriesWithItems = [];
  bool _loading = true;
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _normalItems = [];
        _categoriesWithItems = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final normal = await _repository.getNormalItems();
      final categoriesWithItems = await _repository.getCategoriesWithItems();
      if (mounted) {
        setState(() {
          _normalItems = normal;
          _categoriesWithItems = categoriesWithItems;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _normalItems = [];
          _categoriesWithItems = [];
          _loading = false;
        });
      }
    }
  }

  List<StockItem> get _filteredNormal {
    if (_searchQuery.trim().isEmpty) return _normalItems;
    final q = _searchQuery.trim().toLowerCase();
    return _normalItems
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            (e.sku?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<MapEntry<ItemCategory, List<StockItem>>> get _filteredSpecial {
    if (_searchQuery.trim().isEmpty) return _categoriesWithItems;
    final q = _searchQuery.trim().toLowerCase();
    return _categoriesWithItems
        .map((e) {
          final cat = e.key;
          final items = e.value
              .where((i) =>
                  i.name.toLowerCase().contains(q) ||
                  (i.sku?.toLowerCase().contains(q) ?? false) ||
                  cat.name.toLowerCase().contains(q))
              .toList();
          return MapEntry(cat, items);
        })
        .where((e) => e.value.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 22,
          ),
        ),
        title: const Text(
          'Manage items',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'View and manage your inventory.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search by name or SKU…',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabBarChip(
                    label: 'Normal items',
                    isSelected: _selectedTabIndex == 0,
                    onTap: () => setState(() => _selectedTabIndex = 0),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _TabBarChip(
                    label: 'Special items',
                    isSelected: _selectedTabIndex == 1,
                    onTap: () => setState(() => _selectedTabIndex = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primaryBlue,
                    child: _selectedTabIndex == 0
                        ? _NormalItemsList(
                            items: _filteredNormal,
                            emptyMessage: !SupabaseConfig.isConfigured
                                ? 'Sign in and add items to see them here.'
                                : 'No normal items yet. Tap Add new item.',
                          )
                        : _SpecialItemsList(
                            categoriesWithItems: _filteredSpecial,
                            emptyMessage: !SupabaseConfig.isConfigured
                                ? 'Sign in and add category-based items.'
                                : 'No special items yet. Add item → Category-Based.',
                          ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context
                      .push(AppConstants.addItemCategoryRoute)
                      .then((_) => _load()),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Add new item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

String _statusLabel(int quantity) {
  if (quantity == 0) return 'Out of stock';
  if (quantity < AppConstants.lowStockThreshold) return 'Low stock';
  return 'In stock';
}

Color _statusColor(int quantity) {
  if (quantity == 0) return const Color(0xFFFF5252);
  if (quantity < AppConstants.lowStockThreshold) return const Color(0xFFE65100);
  return const Color(0xFF2E7D32);
}

class _TabBarChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabBarChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _NormalItemsList extends StatelessWidget {
  final List<StockItem> items;
  final String emptyMessage;

  const _NormalItemsList({
    required this.items,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          const SizedBox(height: 32),
          Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.only(bottom: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _InventoryTile(
          name: item.name,
          sku: item.sku ?? '—',
          quantity: item.quantity,
          statusLabel: _statusLabel(item.quantity),
          statusColor: _statusColor(item.quantity),
          onTap: () => context.push(AppConstants.itemDetailsRoute),
        );
      },
    );
  }
}

class _SpecialItemsList extends StatelessWidget {
  final List<MapEntry<ItemCategory, List<StockItem>>> categoriesWithItems;
  final String emptyMessage;

  const _SpecialItemsList({
    required this.categoriesWithItems,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (categoriesWithItems.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          const SizedBox(height: 32),
          Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final entry in categoriesWithItems) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.key.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...entry.value.map(
            (item) => _InventoryTile(
              name: item.name,
              sku: item.sku ?? '—',
              quantity: item.quantity,
              statusLabel: _statusLabel(item.quantity),
              statusColor: _statusColor(item.quantity),
              categoryName: entry.key.name,
              onTap: () => context.push(AppConstants.itemDetailsRoute),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final String name;
  final String sku;
  final int quantity;
  final String statusLabel;
  final Color statusColor;
  final String? categoryName;
  final VoidCallback? onTap;

  const _InventoryTile({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.statusLabel,
    required this.statusColor,
    this.categoryName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: statusColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (categoryName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          categoryName!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            sku,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}