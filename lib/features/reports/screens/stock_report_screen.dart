import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/config/supabase_config.dart';

class _ReportRow {
  final String itemName;
  final DateTime when;
  final int qty10ft;
  final int qty12ft;
  final bool isIn;

  const _ReportRow({
    required this.itemName,
    required this.when,
    required this.qty10ft,
    required this.qty12ft,
    required this.isIn,
  });
}

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key, this.reportType});

  /// 'in' or 'out' – which report to show
  final String? reportType;

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  String _dateRange = 'Today'; // Today, This week, This month
  bool _loading = true;
  List<_ReportRow> _rows = const [];

  bool get _isStockIn {
    final t = widget.reportType ?? 'in';
    return t == 'in';
  }

  String get _title => _isStockIn ? 'Stock in report' : 'Stock out report';

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _cutoffForRange() {
    final now = DateTime.now();
    if (_dateRange == 'Today') return DateTime(now.year, now.month, now.day);
    if (_dateRange == 'This week') return now.subtract(const Duration(days: 7));
    return now.subtract(const Duration(days: 30));
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _rows = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not signed in');
      final cutoff = _cutoffForRange();
      final res = await client
          .from('stock_entries_v2')
          .select(
            'created_at, entry_type, delta_10ft, delta_12ft, items_v2(code, finish, item_types(name))',
          )
          .eq('entry_type', _isStockIn ? 'in' : 'out')
          .gte('created_at', cutoff.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(500);

      final rows = (res as List).map((row) {
        final map = row as Map<String, dynamic>;
        final item = map['items_v2'] as Map<String, dynamic>?;
        final type = item?['item_types'] as Map<String, dynamic>?;
        final typeName = (type?['name'] as String?) ?? '';
        final code = (item?['code'] as String?) ?? '';
        final finish = (item?['finish'] as String?) ?? '';
        return _ReportRow(
          itemName: [typeName, code, finish].where((e) => e.trim().isNotEmpty).join(' · '),
          when: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
          qty10ft: (map['delta_10ft'] as num?)?.toInt() ?? 0,
          qty12ft: (map['delta_12ft'] as num?)?.toInt() ?? 0,
          isIn: map['entry_type'] == 'in',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _loading = false;
      });
    }
  }

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
                onTap: () {
                  setState(() => _dateRange = 'Today');
                  _load();
                },
              ),
              const SizedBox(width: 8),
              _DateChip(
                label: 'This week',
                isSelected: _dateRange == 'This week',
                onTap: () {
                  setState(() => _dateRange = 'This week');
                  _load();
                },
              ),
              const SizedBox(width: 8),
              _DateChip(
                label: 'This month',
                isSelected: _dateRange == 'This month',
                onTap: () {
                  setState(() => _dateRange = 'This month');
                  _load();
                },
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
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  )
                : _rows.isEmpty
                    ? const Center(
                        child: Text(
                          'No entries',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          final qtyText = [
                            if (row.qty10ft != 0) '${row.isIn ? "+" : "-"}${row.qty10ft} (10ft)',
                            if (row.qty12ft != 0) '${row.isIn ? "+" : "-"}${row.qty12ft} (12ft)',
                          ].join('\n');
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
                                      row.isIn
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
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
                                          row.when.toLocal().toString(),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    qtyText,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 12,
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
            onPressed: () => context.push(
              AppConstants.pdfPreviewRoute,
              extra: <String, dynamic>{
                'reportType': _isStockIn ? 'in' : 'out',
                'dateRange': _dateRange,
              },
            ),
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
