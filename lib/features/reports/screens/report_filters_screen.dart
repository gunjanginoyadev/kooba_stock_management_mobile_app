import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../items/models/item_models.dart';
import '../../items/repository/items_repository.dart';

/// Simple Inventory summary – current stock levels at a glance.
class ReportFiltersScreen extends StatefulWidget {
  const ReportFiltersScreen({super.key});

  @override
  State<ReportFiltersScreen> createState() => _ReportFiltersScreenState();
}

class _ReportFiltersScreenState extends State<ReportFiltersScreen> {
  String _dateRange = 'Today';
  final _repo = ItemsRepository();
  bool _loading = true;
  List<StockSheetItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.getStockSheetItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  int _totalQty(StockSheetItem i) => i.qty10ft + i.qty12ft;

  @override
  Widget build(BuildContext context) {
    final totalItems = _items.length;
    final outOfStock = _items.where((i) => _totalQty(i) == 0).toList();
    final lowStock = _items.where((i) {
      final total = _totalQty(i);
      return total > 0 && total < AppConstants.lowStockThreshold;
    }).toList();
    final inStock = _items.where((i) => _totalQty(i) >= AppConstants.lowStockThreshold).toList();

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
          'Inventory summary',
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
            'Current stock levels. (Snapshot-by-date is coming soon.)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DateChip(
                label: 'Today',
                isSelected: _dateRange == 'Today',
                onTap: () => setState(() => _dateRange = 'Today'),
              ),
              const SizedBox(width: 8),
              _DateChip(
                label: 'This week',
                isSelected: _dateRange == 'This week',
                onTap: () => setState(() => _dateRange = 'This week'),
              ),
              const SizedBox(width: 8),
              _DateChip(
                label: 'This month',
                isSelected: _dateRange == 'This month',
                onTap: () => setState(() => _dateRange = 'This month'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'SUMMARY',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Total items',
                  value: _loading ? '—' : '$totalItems',
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Low stock',
                  value: _loading ? '—' : '${lowStock.length}',
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Out of stock',
                  value: _loading ? '—' : '${outOfStock.length}',
                  color: const Color(0xFFFF5252),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'In stock',
                  value: _loading ? '—' : '${inStock.length}',
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'LOW STOCK ITEMS',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primaryBlue,
                    child: lowStock.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'No low stock items',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            children: [
                              for (final i in lowStock.take(30))
                                _SummaryRow(
                                  name: '${i.typeName} · ${i.code} · ${i.finish}',
                                  qty: _totalQty(i),
                                ),
                            ],
                          ),
                  ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Export PDF',
            icon: Icons.file_download_rounded,
            onPressed: () => context.push(AppConstants.pdfPreviewRoute),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
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

class _SummaryRow extends StatelessWidget {
  final String name;
  final int qty;

  const _SummaryRow({required this.name, required this.qty});

  @override
  Widget build(BuildContext context) {
    final isOut = qty == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$qty units',
              style: TextStyle(
                color: isOut ? const Color(0xFFFF5252) : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
