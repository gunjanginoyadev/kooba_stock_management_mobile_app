import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../items/models/item_models.dart';
import '../../items/repository/items_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ItemsRepository();
  bool _loading = true;
  List<StockSheetItem> _items = const [];
  List<StockEntryV2> _recentEntries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _totalQty(StockSheetItem i) => i.qty10ft + i.qty12ft;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.getStockSheetItems();
      final entries = await _repo.getStockEntries(limit: 1);
      if (!mounted) return;
      setState(() {
        _items = items;
        _recentEntries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _recentEntries = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _items.length;
    final lowStock = _items.where((i) {
      final total = _totalQty(i);
      return total > 0 && total < AppConstants.lowStockThreshold;
    }).toList();
    final outOfStock = _items.where((i) => _totalQty(i) == 0).toList();
    final normalStock = _items
        .where((i) => _totalQty(i) >= AppConstants.lowStockThreshold)
        .take(8)
        .toList();

    return AppScaffold(
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
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: SizedBox(),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(label: 'Total Items', value: '$totalItems'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  label: 'Low Stock',
                  value: '${lowStock.length}',
                  color: const Color(0xFFFFC107),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  label: 'Out of Stock',
                  value: '${outOfStock.length}',
                  color: const Color(0xFFFF5252),
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
                  const _SectionHeader(title: 'Out of Stock', color: Color(0xFFFF5252)),
                  if (_loading)
                    const _LoadingBlock()
                  else if (outOfStock.isEmpty)
                    const _EmptyBlock(text: 'No out of stock items')
                  else
                    ...outOfStock.take(5).map(
                      (i) => _StockTile(
                        name: '${i.code} · ${i.finish}',
                        statusLabel: 'Out of Stock',
                        statusColor: const Color(0xFFFF5252),
                        quantityLabel: '10ft:${i.qty10ft} · 12ft:${i.qty12ft}',
                      ),
                    ),
                  const SizedBox(height: 16),
                  const _SectionHeader(title: 'Low Stock (Below 10)', color: Color(0xFFFFC107)),
                  if (_loading)
                    const _LoadingBlock()
                  else if (lowStock.isEmpty)
                    const _EmptyBlock(text: 'No low stock items')
                  else
                    ...lowStock.take(5).map(
                      (i) => _StockTile(
                        name: '${i.code} · ${i.finish}',
                        statusLabel: 'Low Stock',
                        statusColor: const Color(0xFFFFC107),
                        quantityLabel: '10ft:${i.qty10ft} · 12ft:${i.qty12ft}',
                      ),
                    ),
                  const SizedBox(height: 16),
                  const _SectionHeader(title: 'Normal Stock', color: Color(0xFF3DDC84)),
                  if (_loading)
                    const _LoadingBlock()
                  else if (normalStock.isEmpty)
                    const _EmptyBlock(text: 'No items yet')
                  else
                    ...normalStock.map(
                      (i) => _StockTile(
                        name: '${i.code} · ${i.finish}',
                        statusLabel: 'In Stock',
                        statusColor: const Color(0xFF3DDC84),
                        quantityLabel: '10ft:${i.qty10ft} · 12ft:${i.qty12ft}',
                      ),
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
                  if (_loading)
                    const _LoadingBlock()
                  else if (_recentEntries.isEmpty)
                    const _EmptyBlock(text: 'No recent entries yet')
                  else
                    _RecentEntryCard(entry: _recentEntries.first),
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

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String text;
  const _EmptyBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _RecentEntryCard extends StatelessWidget {
  final StockEntryV2 entry;
  const _RecentEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isIn;
    final color = isIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final icon = isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final qtyText = [
      if (entry.delta10ft != 0) '${isIn ? "+" : "-"}${entry.delta10ft} (10ft)',
      if (entry.delta12ft != 0) '${isIn ? "+" : "-"}${entry.delta12ft} (12ft)',
    ].join(' · ');

    return Container(
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
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIn ? 'Stock In' : 'Stock Out',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.itemLabel} • ${entry.createdAt.toLocal()}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            qtyText,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
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
                        color: statusColor.withValues(alpha: 0.18),
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
