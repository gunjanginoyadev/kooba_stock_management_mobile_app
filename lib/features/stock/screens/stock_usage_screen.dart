import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/toast_helper.dart';

// ── Demo data: categories and items for stock out ─────────────────────────────
class _UsageItem {
  final String name;
  final String sku;
  final int currentQty;

  const _UsageItem({
    required this.name,
    required this.sku,
    required this.currentQty,
  });
}

class _UsageCategory {
  final String name;
  final List<_UsageItem> items;

  const _UsageCategory({required this.name, required this.items});
}

// Normal (simple) stock items – pick one item, no category needed
const List<_UsageItem> _normalItems = [
  _UsageItem(name: 'M12 Steel Bolt', sku: 'SKU-M12-B', currentQty: 450),
  _UsageItem(name: 'Hex Nut 10mm', sku: 'SKU-HN-10', currentQty: 24),
  _UsageItem(name: 'Washer 5/8"', sku: 'SKU-W-58', currentQty: 1200),
  _UsageItem(name: 'Safety Gloves (L)', sku: 'SKU-SG-L', currentQty: 85),
  _UsageItem(name: 'Copper Wire Spool', sku: 'SKU-CW-S', currentQty: 12),
  _UsageItem(name: 'Sandpaper 120 grit', sku: 'SKU-SP-120', currentQty: 30),
  _UsageItem(name: 'Wood Screw 3"', sku: 'SKU-WS-3', currentQty: 200),
  _UsageItem(name: 'Tape Roll', sku: 'SKU-TR', currentQty: 45),
];

const List<_UsageCategory> _usageCategories = [
  _UsageCategory(
    name: 'Boards',
    items: [
      _UsageItem(name: 'Buff Board 12mm', sku: 'SKU-BB-12', currentQty: 34),
      _UsageItem(name: 'Ply 4x8', sku: 'SKU-PLY-48', currentQty: 18),
      _UsageItem(name: 'MDF 18mm', sku: 'SKU-MDF-18', currentQty: 8),
    ],
  ),
  _UsageCategory(
    name: 'Materials',
    items: [
      _UsageItem(name: 'Leather – Thin', sku: 'SKU-LT-01', currentQty: 0),
      _UsageItem(name: 'Leather – Thick', sku: 'SKU-LT-02', currentQty: 12),
      _UsageItem(name: 'Adhesive 5L', sku: 'SKU-ADH-5', currentQty: 6),
    ],
  ),
  _UsageCategory(
    name: 'Tools',
    items: [
      _UsageItem(name: 'Hammer Blade Pro', sku: 'SKU-HB-P', currentQty: 12),
      _UsageItem(name: 'Cutter Set', sku: 'SKU-CUT-S', currentQty: 24),
      _UsageItem(name: 'Drill Bit 10mm', sku: 'SKU-DB-10', currentQty: 15),
    ],
  ),
  _UsageCategory(
    name: 'Packaging',
    items: [
      _UsageItem(name: 'Premium Foam XL', sku: 'SKU-PF-XL', currentQty: 5),
      _UsageItem(name: 'Box Large', sku: 'SKU-BOX-L', currentQty: 42),
      _UsageItem(name: 'Bubble Wrap Roll', sku: 'SKU-BW-R', currentQty: 20),
    ],
  ),
];

class StockUsageScreen extends StatefulWidget {
  const StockUsageScreen({super.key});

  @override
  State<StockUsageScreen> createState() => _StockUsageScreenState();
}

class _StockUsageScreenState extends State<StockUsageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  bool _useNormalItem = true; // true = normal (one item), false = by category
  _UsageItem? _selectedNormalItem;
  _UsageCategory? _selectedCategory;
  _UsageItem? _selectedItem;
  int _quantity = 1;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_quantity <= 0) {
      ToastHelper.error(context, 'Enter a quantity greater than 0');
      return;
    }
    String? itemLabel;
    if (_useNormalItem) {
      if (_selectedNormalItem == null) {
        ToastHelper.error(context, 'Please select an item');
        return;
      }
      itemLabel = _selectedNormalItem!.name;
    } else {
      if (_selectedCategory == null) {
        ToastHelper.error(context, 'Please select a category');
        return;
      }
      if (_selectedItem == null) {
        ToastHelper.error(context, 'Please select an item');
        return;
      }
      itemLabel = '${_selectedItem!.name} (${_selectedCategory!.name})';
    }
    context.push(
      AppConstants.stockSuccessRoute,
      extra: <String, dynamic>{
        'type': 'out',
        'itemName': itemLabel,
        'quantity': _quantity,
      },
    );
  }

  void _showNormalItemPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select item (normal stock)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick the item you used. No category needed.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ..._normalItems.map((item) {
                  final isSelected = _selectedNormalItem == item;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? AppTheme.primaryBlue.withOpacity(0.12)
                          : AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedNormalItem = item);
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryBlue.withOpacity(0.2)
                                      : AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textPrimary,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.sku,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.currentQty} in stock',
                                style: TextStyle(
                                  color: item.currentQty == 0
                                      ? const Color(0xFFFF5252)
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 22,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select category',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose the category for this usage entry.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ..._usageCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? AppTheme.primaryBlue.withOpacity(0.12)
                          : AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedItem = null;
                          });
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryBlue.withOpacity(0.2)
                                      : AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.category_rounded,
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showItemPicker() {
    final category = _selectedCategory;
    if (category == null || category.items.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select item · ${category.name}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose the stock item for this usage entry.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ...category.items.map((item) {
                  final isSelected = _selectedItem == item;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? AppTheme.primaryBlue.withOpacity(0.12)
                          : AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedItem = item);
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryBlue.withOpacity(0.2)
                                      : AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textPrimary,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.sku,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.currentQty} in stock',
                                style: TextStyle(
                                  color: item.currentQty == 0
                                      ? const Color(0xFFFF5252)
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 22,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
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
          'Stock out',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Record which stock was used and where.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Entry type: Normal item vs By category
              _SectionLabel('Entry type'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ModeChip(
                      label: 'Normal item',
                      hint: 'Pick one item',
                      isSelected: _useNormalItem,
                      onTap: () {
                        setState(() {
                          _useNormalItem = true;
                          _selectedCategory = null;
                          _selectedItem = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeChip(
                      label: 'By category',
                      hint: 'Category → item',
                      isSelected: !_useNormalItem,
                      onTap: () {
                        setState(() {
                          _useNormalItem = false;
                          _selectedNormalItem = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Normal item: single item picker ──
              if (_useNormalItem) ...[
                _SectionLabel('1. Item'),
                const SizedBox(height: 10),
                _SelectTile(
                  label: _selectedNormalItem?.name ?? 'Select item',
                  hint: 'Tap to choose from normal stock',
                  isSelected: _selectedNormalItem != null,
                  icon: Icons.inventory_2_rounded,
                  onTap: _showNormalItemPicker,
                ),
                if (_selectedNormalItem != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '${_selectedNormalItem!.sku} · ${_selectedNormalItem!.currentQty} in stock',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // ── By category: category then item ──
              if (!_useNormalItem) ...[
                _SectionLabel('1. Category'),
                const SizedBox(height: 10),
                _SelectTile(
                  label: _selectedCategory?.name ?? 'Select category',
                  hint: 'Tap to choose category',
                  isSelected: _selectedCategory != null,
                  icon: Icons.category_rounded,
                  onTap: _showCategoryPicker,
                ),
                const SizedBox(height: 24),
                _SectionLabel('2. Item / stock'),
                const SizedBox(height: 10),
                _SelectTile(
                  label: _selectedItem?.name ?? 'Select item',
                  hint: _selectedCategory != null
                      ? 'Tap to choose item'
                      : 'Select a category first',
                  isSelected: _selectedItem != null,
                  icon: Icons.inventory_2_rounded,
                  onTap: _selectedCategory != null ? _showItemPicker : null,
                ),
                if (_selectedItem != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '${_selectedItem!.sku} · ${_selectedItem!.currentQty} in stock',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // Quantity
              _SectionLabel(_useNormalItem ? '2. Quantity used' : '3. Quantity used'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () {
                        setState(() {
                          _quantity = (_quantity - 1).clamp(0, 999999);
                        });
                      },
                    ),
                    const Spacer(),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _QtyButton(
                      icon: Icons.add,
                      isPrimary: true,
                      onTap: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              _SectionLabel(
                _useNormalItem
                    ? '3. Usage location / notes'
                    : '4. Usage location / notes',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Zone B – Line 1, project reference…',
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter usage location or a note';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Save stock out',
                onPressed: _onSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.12)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  final String label;
  final String hint;
  final bool isSelected;
  final IconData icon;
  final VoidCallback? onTap;

  const _SelectTile({
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? AppTheme.primaryBlue : AppTheme.borderColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
