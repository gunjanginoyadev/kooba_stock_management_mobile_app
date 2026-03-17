import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/toast_helper.dart';

// ── Sample special stock items with variants ───────────────────────────────────
class _SpecialStockItem {
  final String name;
  final String sku;
  final String category;
  final int currentQty;
  final List<String> variants;

  const _SpecialStockItem({
    required this.name,
    required this.sku,
    required this.category,
    required this.currentQty,
    required this.variants,
  });
}

const List<_SpecialStockItem> _specialStocks = [
  _SpecialStockItem(
    name: 'Buff Board 12mm',
    sku: 'SKU-BB-12',
    category: 'Boards',
    currentQty: 34,
    variants: ['4x8 ft', '4x10 ft', '6x8 ft', '6x10 ft'],
  ),
  _SpecialStockItem(
    name: 'Leather – Thin',
    sku: 'SKU-LT-01',
    category: 'Materials',
    currentQty: 0,
    variants: ['Black', 'Brown', 'Tan', 'White'],
  ),
  _SpecialStockItem(
    name: 'Hammer Blade Pro',
    sku: 'SKU-HB-P',
    category: 'Tools',
    currentQty: 12,
    variants: ['Standard', 'Heavy-duty', 'Left-hand'],
  ),
  _SpecialStockItem(
    name: 'Premium Foam XL',
    sku: 'SKU-PF-XL',
    category: 'Packaging',
    currentQty: 5,
    variants: ['1" thick', '2" thick', '3" thick'],
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════

enum _StockType { simple, special }

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  _StockType _stockType = _StockType.simple;
  int _quantity = 1;
  _SpecialStockItem? _selectedSpecial;
  String? _selectedVariant;

  void _increment(int by) => setState(() => _quantity += by);

  bool get _canSave {
    if (_quantity <= 0) return false;
    if (_stockType == _StockType.special) {
      return _selectedSpecial != null && _selectedVariant != null;
    }
    return true; // Simple: no item picker yet, allow save with qty only
  }

  void _onSave() {
    if (!_canSave) {
      if (_quantity <= 0) {
        ToastHelper.error(context, 'Enter a quantity greater than 0');
        return;
      }
      if (_stockType == _StockType.special && _selectedSpecial == null) {
        ToastHelper.error(context, 'Please select an item');
        return;
      }
      if (_stockType == _StockType.special && _selectedVariant == null) {
        ToastHelper.error(context, 'Please select a variant');
        return;
      }
    }
    final itemLabel = _selectedSpecial != null && _selectedVariant != null
        ? '${_selectedSpecial!.name} · $_selectedVariant'
        : _selectedSpecial?.name;
    context.push(
      AppConstants.stockSuccessRoute,
      extra: <String, dynamic>{
        'type': 'in',
        'itemName': itemLabel ?? _selectedSpecial?.name,
        'quantity': _quantity,
      },
    );
  }

  void _showVariantPicker() {
    final item = _selectedSpecial;
    if (item == null || item.variants.isEmpty) return;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select variant',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ...item.variants.map((variant) {
                  final isSelected = _selectedVariant == variant;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? AppTheme.primaryBlue.withOpacity(0.12)
                          : AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedVariant = variant);
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
                              Expanded(
                                child: Text(
                                  variant,
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

  void _showSpecialStockPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Special Stock',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose the special stock item for this entry',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              // List
              ..._specialStocks.map((item) {
                final isSelected = _selectedSpecial == item;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSpecial = item;
                      _selectedVariant = null;
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryBlue.withOpacity(0.12)
                          : AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.borderColor,
                        width: isSelected ? 1.5 : 1,
                      ),
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
                            Icons.star_rounded,
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  _MiniTag(text: item.sku),
                                  const SizedBox(width: 6),
                                  _MiniTag(text: item.category),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.currentQty}',
                              style: TextStyle(
                                color: item.currentQty == 0
                                    ? const Color(0xFFFF5252)
                                    : const Color(0xFF3DDC84),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'units',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
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
          'Stock in',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ══ Stock Type Selector ══════════════════════════════════════
            _SectionLabel('STOCK TYPE'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TypeCard(
                  title: 'Simple Stock',
                  subtitle: 'Standard inventory item',
                  icon: Icons.inventory_2_rounded,
                  iconBg: const Color(0xFF1A237E),
                  isSelected: _stockType == _StockType.simple,
                  onTap: () => setState(() {
                    _stockType = _StockType.simple;
                    _selectedSpecial = null;
                    _selectedVariant = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeCard(
                  title: 'Special Stock',
                  subtitle: 'Tracked / restricted item',
                  icon: Icons.star_rounded,
                  iconBg: const Color(0xFF4A148C),
                  isSelected: _stockType == _StockType.special,
                  onTap: () => setState(() {
                    _stockType = _StockType.special;
                    _selectedVariant = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ══ Special stock picker (conditional) ═══════════════════════
          if (_stockType == _StockType.special) ...[
            _SectionLabel('SELECT SPECIAL STOCK ITEM'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showSpecialStockPicker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedSpecial != null
                        ? AppTheme.primaryBlue
                        : AppTheme.borderColor,
                    width: _selectedSpecial != null ? 1.5 : 1,
                  ),
                ),
                child: _selectedSpecial == null
                    ? Row(
                        children: const [
                          Icon(
                            Icons.star_outline_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tap to choose a special stock item…',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedSpecial!.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    _MiniTag(text: _selectedSpecial!.sku),
                                    const SizedBox(width: 6),
                                    _MiniTag(text: _selectedSpecial!.category),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.edit_rounded,
                            color: AppTheme.primaryBlue,
                            size: 16,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ══ Item search (for simple stock) – no variant ─══════════════
          if (_stockType == _StockType.simple) ...[
            _SectionLabel('SELECT ITEM'),
            const SizedBox(height: 10),
            _DropdownLikeField(
              icon: Icons.search,
              hint: 'Search by name or SKU...',
            ),
            const SizedBox(height: 24),
          ],

          // ══ Variant (for special stock only) ══════════════════════════
          if (_stockType == _StockType.special) ...[
            _SectionLabel('VARIANT / SUB-CATEGORY'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _selectedSpecial != null ? _showVariantPicker : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedVariant != null
                        ? AppTheme.primaryBlue
                        : AppTheme.borderColor,
                    width: _selectedVariant != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.unfold_more_rounded,
                      color: _selectedVariant != null
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedVariant ??
                            (_selectedSpecial != null
                                ? 'Select variant...'
                                : 'Select an item first'),
                        style: TextStyle(
                          color: _selectedVariant != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight:
                              _selectedVariant != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                        ),
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
            ),
            const SizedBox(height: 24),
          ],

          // ══ Quantity ═════════════════════════════════════════════════
          const Center(
            child: Text(
              'QUANTITY RECEIVED',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onTap: () => setState(
                    () => _quantity = (_quantity - 1).clamp(0, 999999),
                  ),
                ),
                const Spacer(),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _QuantityButton(
                  icon: Icons.add,
                  isPrimary: true,
                  onTap: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickQtyChip(label: '+10', onTap: () => _increment(10)),
              const SizedBox(width: 8),
              _QuickQtyChip(label: '+50', onTap: () => _increment(50)),
              const SizedBox(width: 8),
              _QuickQtyChip(label: '+100', onTap: () => _increment(100)),
            ],
          ),
          const SizedBox(height: 24),

          // ══ Notes ════════════════════════════════════════════════════
          const Text(
            'Notes (Optional)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Add details about this batch (e.g., damaged box, supplier note)...',
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 24),

          // ══ Save button ══════════════════════════════════════════════
          AppPrimaryButton(
            label: 'Save stock in',
            icon: Icons.download_rounded,
            onPressed: _onSave,
          ),
          const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets
// ════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Stock type card ──────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.2)
                        : iconBg.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 13,
                    ),
                  )
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
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

// ── Mini tag badge ───────────────────────────────────────────────────────────

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Dropdown-like field ──────────────────────────────────────────────────────

class _DropdownLikeField extends StatelessWidget {
  final IconData icon;
  final String hint;

  const _DropdownLikeField({required this.icon, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.unfold_more_rounded, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

// ── Quantity button ──────────────────────────────────────────────────────────

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 64,
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryBlue : AppTheme.borderColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}

// ── Quick qty chip ───────────────────────────────────────────────────────────

class _QuickQtyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickQtyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        ),
      ),
    );
  }
}
