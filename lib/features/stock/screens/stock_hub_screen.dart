import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_stock_action_card.dart';

class StockHubScreen extends StatelessWidget {
  const StockHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppConstants.homeRoute);
              break;
            case 1:
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'KOoba Stock'.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Stock Hub',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // Primary cards
            StockActionCard(
              title: 'Add Stock',
              description:
                  'Scan barcodes or manually enter incoming goods.',
              icon: Icons.add,
              accentColor: AppTheme.primaryBlue,
              onTap: () => context.push(AppConstants.addStockRoute),
            ),
            const SizedBox(height: 16),
            StockActionCard(
              title: 'Use Stock',
              description: 'Record material usage for production jobs.',
              icon: Icons.exit_to_app_rounded,
              accentColor: const Color(0xFFEF6C39),
              onTap: () => context.push(AppConstants.stockUsageRoute),
            ),
            const SizedBox(height: 16),
            StockActionCard(
              title: 'Manage Items',
              description:
                  'Edit details, adjust counts, or view catalog.',
              icon: Icons.archive_rounded,
              accentColor: const Color(0xFF9C6BFF),
              onTap: () => context.push(AppConstants.manageItemsRoute),
            ),

            const SizedBox(height: 32),

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
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
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Added 500 units of Bolts M12',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '2 mins ago • Warehouse A',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


