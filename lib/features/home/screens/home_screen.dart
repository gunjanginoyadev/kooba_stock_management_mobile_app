import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.go(AppConstants.stockHubRoute);
              break;
            case 2:
              context.go(AppConstants.reportsHomeRoute);
              break;
            case 3:
              context.go(AppConstants.profileRoute);
              break;
          }
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Stock Overview',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kooba Warehouse A',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
              decoration: InputDecoration(
                hintText: 'Search items…',
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
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          const SizedBox(height: 16),
          Row(
              children: const [
                Expanded(
                  child: _SummaryChip(
                    label: 'Total Items',
                    value: '142',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Low Stock',
                    value: '18',
                    color: Color(0xFFFFC107),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Out of Stock',
                    value: '5',
                    color: Color(0xFFFF5252),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Everything below this point scrolls, header stays fixed.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const _SectionHeader(
              title: 'Out of Stock',
              color: Color(0xFFFF5252),
            ),
                  const _StockTile(
              name: 'Leather – Thin',
              statusLabel: 'Out of Stock',
              statusColor: Color(0xFFFF5252),
              quantityLabel: '0 units',
            ),
                  const _StockTile(
              name: 'Fevicol 5kg',
              statusLabel: 'Out of Stock',
              statusColor: Color(0xFFFF5252),
              quantityLabel: '0 units',
            ),
                  const SizedBox(height: 16),
                  const _SectionHeader(
              title: 'Low Stock (Below 10)',
              color: Color(0xFFFFC107),
            ),
                  const _StockTile(
              name: 'M12 Steel Bolt',
              statusLabel: 'Low Stock',
              statusColor: Color(0xFFFFC107),
              quantityLabel: '8 units',
            ),
                  const _StockTile(
              name: 'Hex Nut 10mm',
              statusLabel: 'Low Stock',
              statusColor: Color(0xFFFFC107),
              quantityLabel: '6 units',
            ),
                  const SizedBox(height: 16),
                  const _SectionHeader(
              title: 'Normal Stock',
              color: Color(0xFF3DDC84),
            ),
                  const _StockTile(
              name: 'Hammer Blade',
              statusLabel: 'In Stock',
              statusColor: Color(0xFF3DDC84),
              quantityLabel: '120 units',
            ),
                  const _StockTile(
              name: 'Buff Board',
              statusLabel: 'In Stock',
              statusColor: Color(0xFF3DDC84),
              quantityLabel: '75 units',
            ),
                  const SizedBox(height: 24),
                  Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Log Entry',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.push(AppConstants.stockHistoryRoute);
                  },
                  child: const Text(
                    'View History',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
                  const SizedBox(height: 8),
                  Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF104F2D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Color(0xFF3DDC84),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock In - Warehouse A',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Added 50 units of M12 Steel Bolt • Today, 10:00 AM',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '+50',
                    style: TextStyle(
                      color: Color(0xFF3DDC84),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    this.color = AppTheme.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final String name;
  final String statusLabel;
  final Color statusColor;
  final String quantityLabel;

  const _StockTile({
    required this.name,
    required this.statusLabel,
    required this.statusColor,
    required this.quantityLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(14),
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
                    fontSize: 14,
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
                        color: statusColor.withOpacity(0.18),
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
                    const SizedBox(width: 8),
                    Text(
                      quantityLabel,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


