import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

class ManageItemsScreen extends StatelessWidget {
  const ManageItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Manage Items',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            color: AppTheme.textSecondary,
            onPressed: () {},
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _SearchField(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SegmentChip(
                  label: 'Normal Items',
                  isSelected: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegmentChip(
                  label: 'Category-Based',
                  isSelected: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'INVENTORY LIST (142)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              label: const Text(
                'Sort by Stock',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              children: const [
                _InventoryItemTile(
                  name: 'M12 Steel Bolt',
                  subtitle: 'High Stock',
                  subtitleColor: Color(0xFF1B5E20),
                  stockLabel: '4,500 units',
                  iconColor: AppTheme.primaryBlue,
                ),
                _InventoryItemTile(
                  name: 'Hex Nut 10mm',
                  subtitle: 'Low Stock',
                  subtitleColor: Color(0xFF8D3C10),
                  stockLabel: '24 units',
                  iconColor: Color(0xFFEF6C39),
                ),
                _InventoryItemTile(
                  name: 'Washer - 5/8"',
                  subtitle: 'Stock',
                  subtitleColor: AppTheme.textSecondary,
                  stockLabel: '1,200 units',
                  iconColor: AppTheme.borderColor,
                ),
                _InventoryItemTile(
                  name: 'Safety Gloves (L)',
                  subtitle: 'Stock',
                  subtitleColor: AppTheme.textSecondary,
                  stockLabel: '85 pairs',
                  iconColor: AppTheme.borderColor,
                ),
                _InventoryItemTile(
                  name: 'Copper Wire Spool',
                  subtitle: 'Stock',
                  subtitleColor: AppTheme.textSecondary,
                  stockLabel: '12 units',
                  iconColor: AppTheme.borderColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              backgroundColor: AppTheme.primaryBlue,
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppConstants.addItemCategoryRoute,
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by name or ID...',
        prefixIcon: const Icon(
          Icons.search,
          color: AppTheme.textSecondary,
        ),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
      ),
      style: const TextStyle(
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _SegmentChip({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color subtitleColor;
  final String stockLabel;
  final Color iconColor;

  const _InventoryItemTile({
    required this.name,
    required this.subtitle,
    required this.subtitleColor,
    required this.stockLabel,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: subtitleColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stockLabel,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}


