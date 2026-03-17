import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';

// Demo entries for report
class _ReportRow {
  final String itemName;
  final String when;
  final int qty;
  final bool isIn;

  const _ReportRow({
    required this.itemName,
    required this.when,
    required this.qty,
    required this.isIn,
  });
}

const List<_ReportRow> _stockInRows = [
  _ReportRow(itemName: 'Buff Board 12mm', when: 'Today, 10:30 AM', qty: 50, isIn: true),
  _ReportRow(itemName: 'Hammer Blade Pro', when: 'Today, 8:00 AM', qty: 12, isIn: true),
  _ReportRow(itemName: 'Ply 4x8', when: 'Yesterday, 11:20 AM', qty: 20, isIn: true),
  _ReportRow(itemName: 'Adhesive 5L', when: 'Mon, 2:00 PM', qty: 10, isIn: true),
];

const List<_ReportRow> _stockOutRows = [
  _ReportRow(itemName: 'Leather – Thin', when: 'Today, 9:15 AM', qty: 24, isIn: false),
  _ReportRow(itemName: 'Premium Foam XL', when: 'Yesterday, 4:45 PM', qty: 8, isIn: false),
  _ReportRow(itemName: 'Drill Bit 10mm', when: 'Mon, 10:00 AM', qty: 5, isIn: false),
];

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key, this.reportType});

  /// 'in' or 'out' – which report to show
  final String? reportType;

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  String _dateRange = 'Today'; // Today, This week, This month

  bool get _isStockIn {
    final t = widget.reportType ?? 'in';
    return t == 'in';
  }

  List<_ReportRow> get _rows => _isStockIn ? _stockInRows : _stockOutRows;

  String get _title => _isStockIn ? 'Stock in report' : 'Stock out report';

  @override
  Widget build(BuildContext context) {
    final accentColor = _isStockIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

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
        title: Text(
          _title,
          style: const TextStyle(
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
            'Pick a date range, then export if needed.',
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
          const SizedBox(height: 20),
          Text(
            'ENTRIES (${_rows.length})',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final row = _rows[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            row.isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.itemName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                row.when,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${row.isIn ? "+" : "-"}${row.qty}',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
