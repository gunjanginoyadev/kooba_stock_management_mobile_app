import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

// ── Demo inventory (aligned with Stock out categories) ────────────────────────
class _InventoryItem {
  final String name;
  final String sku;
  final int quantity;

  const _InventoryItem({
    required this.name,
    required this.sku,
    required this.quantity,
  });

  String get statusLabel {
    if (quantity == 0) return 'Out of stock';
    if (quantity < AppConstants.lowStockThreshold) return 'Low stock';
    return 'In stock';
  }

  Color get statusColor {
    if (quantity == 0) return const Color(0xFFFF5252);
    if (quantity < AppConstants.lowStockThreshold) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }
}

class _InventoryCategory {
  final String name;
  final List<_InventoryItem> items;

  const _InventoryCategory({required this.name, required this.items});
}

// Normal (flat) items
const List<_InventoryItem> _normalItems = [
  _InventoryItem(name: 'M12 Steel Bolt', sku: 'SKU-M12-B', quantity: 450),
  _InventoryItem(name: 'Hex Nut 10mm', sku: 'SKU-HN-10', quantity: 24),
  _InventoryItem(name: 'Washer 5/8"', sku: 'SKU-W-58', quantity: 1200),
  _InventoryItem(name: 'Safety Gloves (L)', sku: 'SKU-SG-L', quantity: 85),
  _InventoryItem(name: 'Copper Wire Spool', sku: 'SKU-CW-S', quantity: 12),
  _InventoryItem(name: 'Sandpaper 120 grit', sku: 'SKU-SP-120', quantity: 30),
  _InventoryItem(name: 'Wood Screw 3"', sku: 'SKU-WS-3', quantity: 200),
  _InventoryItem(name: 'Tape Roll', sku: 'SKU-TR', quantity: 45),
];

const List<_InventoryCategory> _inventoryCategories = [
  _InventoryCategory(
    name: 'Boards',
    items: [
      _InventoryItem(name: 'Buff Board 12mm', sku: 'SKU-BB-12', quantity: 34),
      _InventoryItem(name: 'Ply 4x8', sku: 'SKU-PLY-48', quantity: 18),
      _InventoryItem(name: 'MDF 18mm', sku: 'SKU-MDF-18', quantity: 8),
    ],
  ),
  _InventoryCategory(
    name: 'Materials',
    items: [
      _InventoryItem(name: 'Leather – Thin', sku: 'SKU-LT-01', quantity: 0),
      _InventoryItem(name: 'Leather – Thick', sku: 'SKU-LT-02', quantity: 12),
      _InventoryItem(name: 'Adhesive 5L', sku: 'SKU-ADH-5', quantity: 6),
    ],
  ),
  _InventoryCategory(
    name: 'Tools',
    items: [
      _InventoryItem(name: 'Hammer Blade Pro', sku: 'SKU-HB-P', quantity: 12),
      _InventoryItem(name: 'Cutter Set', sku: 'SKU-CUT-S', quantity: 24),
      _InventoryItem(name: 'Drill Bit 10mm', sku: 'SKU-DB-10', quantity: 15),
    ],
  ),
  _InventoryCategory(
    name: 'Packaging',
    items: [
      _InventoryItem(name: 'Premium Foam XL', sku: 'SKU-PF-XL', quantity: 5),
      _InventoryItem(name: 'Box Large', sku: 'SKU-BOX-L', quantity: 42),
      _InventoryItem(name: 'Bubble Wrap Roll', sku: 'SKU-BW-R', quantity: 20),
    ],
  ),
];

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  int _selectedTabIndex = 0; // 0 = Normal items, 1 = Special items

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
          // Tab bar: Normal items | Special items
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
            child: _selectedTabIndex == 0
                ? _NormalItemsList()
                : _SpecialItemsList(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(AppConstants.addItemCategoryRoute),
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
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _normalItems.length,
      padding: const EdgeInsets.only(bottom: 8),
      itemBuilder: (context, index) {
        final item = _normalItems[index];
        return _InventoryTile(
          name: item.name,
          sku: item.sku,
          quantity: item.quantity,
          statusLabel: item.statusLabel,
          statusColor: item.statusColor,
          onTap: () => context.push(AppConstants.itemDetailsRoute),
        );
      },
    );
  }
}

class _SpecialItemsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final category in _inventoryCategories) ...[
          // Category name header (same UI style as before)
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
                  category.name,
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
          // Sub-items under this category
          ...category.items.map(
            (item) => _InventoryTile(
              name: item.name,
              sku: item.sku,
              quantity: item.quantity,
              statusLabel: item.statusLabel,
              statusColor: item.statusColor,
              categoryName: category.name,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$quantity units',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
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
}
