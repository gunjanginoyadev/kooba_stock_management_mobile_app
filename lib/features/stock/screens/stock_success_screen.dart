import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';

/// Supports both stock-in and stock-out success.
/// [extra] can be: { 'type': 'in'|'out', 'itemName': String?, 'quantity': int? }
class StockSuccessScreen extends StatelessWidget {
  const StockSuccessScreen({super.key, this.extra});

  final Map<String, dynamic>? extra;

  static const String _keyType = 'type';
  static const String _keyItemName = 'itemName';
  static const String _keyQuantity = 'quantity';

  bool get _isStockIn {
    final type = extra?[_keyType];
    if (type == null) return true;
    return type == 'in';
  }

  String? get _itemName {
    final v = extra?[_keyItemName];
    return v is String ? v : null;
  }

  int? get _quantity {
    final v = extra?[_keyQuantity];
    return v is int ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final isIn = _isStockIn;
    final accentColor = isIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final title = isIn ? 'Stock in recorded' : 'Stock out recorded';
    final subtitle = isIn
        ? 'Incoming stock has been added to inventory.'
        : 'Usage has been recorded.';
    final actionLabel = isIn ? 'ADDED' : 'USED';
    final addAnotherRoute =
        isIn ? AppConstants.addStockRoute : AppConstants.stockUsageRoute;

    return AppScaffold(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Icon(
                isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (_itemName != null || _quantity != null) ...[
              Container(
                width: double.infinity,
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
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: accentColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _itemName ?? 'Item',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_quantity != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${isIn ? "+" : "-"}$_quantity units',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ] else
              const SizedBox(height: 12),
            const Spacer(),
            AppPrimaryButton(
              label: isIn ? 'Add another stock in' : 'Add another stock out',
              onPressed: () {
                context.pop(); // pop success
                context.pop(); // pop add-stock / stock-usage
                context.push(addAnotherRoute);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => context.go(AppConstants.stockHubRoute),
                child: const Text(
                  'Back to Stock',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppConstants.homeRoute),
              child: const Text(
                'Go to Home',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
