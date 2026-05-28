import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../items/repository/items_repository.dart';

class StockHubScreen extends StatefulWidget {
  const StockHubScreen({super.key});

  @override
  State<StockHubScreen> createState() => _StockHubScreenState();
}

class _StockHubScreenState extends State<StockHubScreen> {
  final _repo = ItemsRepository();
  bool _loading = true;
  List<_RecentActivity> _recent = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await _repo.getStockEntries(limit: 3);
      if (!mounted) return;
      setState(() {
        _recent = entries
            .map(
              (e) => _RecentActivity(
                label: e.itemLabel.isEmpty ? 'Item' : e.itemLabel,
                detail: e.createdAt.toLocal().toString(),
                isIn: e.isIn,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recent = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Stock',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add items, or record stock in & out',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            // ── Primary actions: Add item, Stock in, Stock out ──
            const _SectionLabel(label: 'What do you want to do?'),
            const SizedBox(height: 12),

            _StockActionTile(
              title: 'Add item',
              subtitle: 'Create a new stock item or category',
              icon: Icons.add_box_rounded,
              iconColor: AppTheme.primaryBlue,
              onTap: () => context.push(AppConstants.addItemCategoryRoute),
            ),
            const SizedBox(height: 10),
            _StockActionTile(
              title: 'Stock in',
              subtitle: 'Record incoming stock',
              icon: Icons.arrow_downward_rounded,
              iconColor: const Color(0xFF2E7D32),
              onTap: () => context.push(AppConstants.addStockRoute),
            ),
            const SizedBox(height: 10),
            _StockActionTile(
              title: 'Stock out',
              subtitle: 'Record stock usage',
              icon: Icons.arrow_upward_rounded,
              iconColor: const Color(0xFFE65100),
              onTap: () => context.push(AppConstants.stockUsageRoute),
            ),

            const SizedBox(height: 28),

            // ── Secondary: Manage items & History ──
            const _SectionLabel(label: 'More'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _SecondaryChip(
                    label: 'Manage items',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => context.push(AppConstants.manageItemsRoute),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryChip(
                    label: 'History',
                    icon: Icons.history_rounded,
                    onTap: () => context.push(AppConstants.stockHistoryRoute),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Recent activity ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent activity',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppConstants.stockHistoryRoute),
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              )
            else if (_recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No activity yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ..._recent.expand(
                (e) => [
                  _RecentActivityTile(
                    label: e.isIn ? 'Stock in · ${e.label}' : 'Stock out · ${e.label}',
                    detail: e.detail,
                    type: e.isIn ? _ActivityType.stockIn : _ActivityType.stockOut,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

enum _ActivityType { stockIn, stockOut }

class _RecentActivity {
  final String label;
  final String detail;
  final bool isIn;

  const _RecentActivity({
    required this.label,
    required this.detail,
    required this.isIn,
  });
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

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

class _StockActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _StockActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  final String label;
  final String detail;
  final _ActivityType type;

  const _RecentActivityTile({
    required this.label,
    required this.detail,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = type == _ActivityType.stockIn;
    final color = isIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final icon = isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
