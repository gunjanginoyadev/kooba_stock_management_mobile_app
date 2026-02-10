import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  int quantity = 12;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        title: const Text(
          'Add Stock',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Future barcode scanner.
            },
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Select Item',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          _DropdownLikeField(
            icon: Icons.search,
            hint: 'Search by name or SKU...',
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Variant / Sub-category *',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Required',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DropdownLikeField(
            icon: Icons.unfold_more_rounded,
            hint: 'Select variant...',
          ),
          const SizedBox(height: 32),
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
                  onTap: () {
                    setState(() {
                      quantity = (quantity - 1).clamp(0, 999999);
                    });
                  },
                ),
                const Spacer(),
                Text(
                  '$quantity',
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
                  onTap: () {
                    setState(() {
                      quantity++;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickQuantityChip(label: '+10', onTap: () => _increment(10)),
              const SizedBox(width: 8),
              _QuickQuantityChip(label: '+50', onTap: () => _increment(50)),
              const SizedBox(width: 8),
              _QuickQuantityChip(label: '+100', onTap: () => _increment(100)),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Notes (Optional)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
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
              style: const TextStyle(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Save Stock',
            icon: Icons.download_rounded,
            onPressed: () {
              // Simulate local success flow only.
              context.push(AppConstants.stockSuccessRoute);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _increment(int by) {
    setState(() {
      quantity += by;
    });
  }
}

class _DropdownLikeField extends StatelessWidget {
  final IconData icon;
  final String hint;

  const _DropdownLikeField({
    required this.icon,
    required this.hint,
  });

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
          const Icon(
            Icons.unfold_more_rounded,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

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
    final bgColor = isPrimary ? AppTheme.primaryBlue : AppTheme.borderColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 64,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _QuickQuantityChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickQuantityChip({
    required this.label,
    required this.onTap,
  });

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
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}


