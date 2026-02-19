import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';

// ════════════════════════════════════════════════════════════════════════════
// Enums / data
// ════════════════════════════════════════════════════════════════════════════

enum _EntryType { all, stockIn, stockOut }

enum _DateMode { custom, thisMonth, lastMonth, noFilter }

// ════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════

class ReportFiltersScreen extends StatefulWidget {
  const ReportFiltersScreen({super.key});

  @override
  State<ReportFiltersScreen> createState() => _ReportFiltersScreenState();
}

class _ReportFiltersScreenState extends State<ReportFiltersScreen> {
  // ── Filter state ────────────────────────────────────────────────────────
  _EntryType _entryType = _EntryType.all;
  _DateMode _dateMode = _DateMode.thisMonth;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  String? _selectedStock; // null = all stocks
  String? _selectedSpecialStock; // null = all items of that type

  static const String _specialStockKey = 'SPECIAL_STOCK';

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _fmtDay(DateTime d) => d.day.toString().padLeft(2, '0');

  String _fmtMonthYear(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month]} ${d.year}';
  }

  void _applyDateMode(_DateMode mode) {
    final now = DateTime.now();
    setState(() {
      _dateMode = mode;
      switch (mode) {
        case _DateMode.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case _DateMode.lastMonth:
          final first = DateTime(now.year, now.month - 1, 1);
          final last = DateTime(now.year, now.month, 0);
          _startDate = first;
          _endDate = last;
          break;
        case _DateMode.noFilter:
          _startDate = DateTime(2020, 1, 1);
          _endDate = now;
          break;
        case _DateMode.custom:
          break;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    setState(() => _dateMode = _DateMode.custom);
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primaryBlue,
            surface: AppTheme.cardBackground,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _entryType = _EntryType.all;
      _dateMode = _DateMode.thisMonth;
      _selectedStock = null;
      _selectedSpecialStock = null;
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed app bar ──────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppTheme.textPrimary,
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Report Filters',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppTheme.primaryBlue, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ══ 1. Entry Type ════════════════════════════════════════
                  _SectionLabel('ENTRY TYPE'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SelectPill(
                          label: 'All Entries',
                          icon: Icons.swap_vert_rounded,
                          isSelected: _entryType == _EntryType.all,
                          onTap: () =>
                              setState(() => _entryType = _EntryType.all),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SelectPill(
                          label: 'Stock In',
                          icon: Icons.arrow_downward_rounded,
                          isSelected: _entryType == _EntryType.stockIn,
                          selectedColor: const Color(0xFF3DDC84),
                          selectedBg: const Color(0xFF0D3320),
                          onTap: () =>
                              setState(() => _entryType = _EntryType.stockIn),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SelectPill(
                          label: 'Stock Out',
                          icon: Icons.arrow_upward_rounded,
                          isSelected: _entryType == _EntryType.stockOut,
                          selectedColor: const Color(0xFFFF5252),
                          selectedBg: const Color(0xFF3D1212),
                          onTap: () =>
                              setState(() => _entryType = _EntryType.stockOut),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ══ 2. Date Range ════════════════════════════════════════
                  _SectionLabel('DATE RANGE'),
                  const SizedBox(height: 10),

                  // Quick preset chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickChip(
                        label: 'This Month',
                        isSelected: _dateMode == _DateMode.thisMonth,
                        onTap: () => _applyDateMode(_DateMode.thisMonth),
                      ),
                      _QuickChip(
                        label: 'Last Month',
                        isSelected: _dateMode == _DateMode.lastMonth,
                        onTap: () => _applyDateMode(_DateMode.lastMonth),
                      ),
                      _QuickChip(
                        label: 'No Date Filter',
                        isSelected: _dateMode == _DateMode.noFilter,
                        onTap: () => _applyDateMode(_DateMode.noFilter),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Custom date pickers
                  Row(
                    children: [
                      Expanded(
                        child: _DateCard(
                          label: 'Start Date',
                          day: _fmtDay(_startDate),
                          monthYear: _fmtMonthYear(_startDate),
                          isActive: _dateMode == _DateMode.custom,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateCard(
                          label: 'End Date',
                          day: _fmtDay(_endDate),
                          monthYear: _fmtMonthYear(_endDate),
                          isActive: _dateMode == _DateMode.custom,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ══ 3. Particular Stock ══════════════════════════════════
                  _SectionLabel('STOCK ITEM'),
                  const SizedBox(height: 10),
                  _StockSelector(
                    selected: _selectedStock,
                    specialStockKey: _specialStockKey,
                    onChanged: (v) {
                      setState(() {
                        _selectedStock = v;
                        if (v != _specialStockKey) {
                          _selectedSpecialStock = null;
                        }
                      });
                    },
                  ),
                  if (_selectedStock == _specialStockKey) ...[
                    const SizedBox(height: 10),
                    _SpecialStockSelector(
                      selected: _selectedSpecialStock,
                      onChanged: (v) =>
                          setState(() => _selectedSpecialStock = v),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ══ 4. Other criteria ════════════════════════════════════
                  _SectionLabel('OTHER CRITERIA'),
                  const SizedBox(height: 10),
                  _FilterRow(
                    icon: Icons.people_alt_outlined,
                    iconBg: const Color(0xFF4A148C),
                    title: 'All Users',
                    subtitle: 'Warehouse Staff, Managers',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _FilterRow(
                    icon: Icons.home_work_outlined,
                    iconBg: const Color(0xFF4E342E),
                    title: 'Main Depot',
                    subtitle: 'Zone A, B & C',
                    onTap: () {},
                  ),
                  const SizedBox(height: 28),

                  // ══ Generate button ══════════════════════════════════════
                  AppPrimaryButton(
                    label: 'Generate Report',
                    icon: Icons.bar_chart_rounded,
                    onPressed: () =>
                        context.push(AppConstants.stockReportRoute),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Reusable widgets
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
        letterSpacing: 1.6,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Entry type pill ──────────────────────────────────────────────────────────

class _SelectPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  const _SelectPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.selectedColor = AppTheme.primaryBlue,
    this.selectedBg = const Color(0xFF0D1A3A),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedColor : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick preset chip ────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Date card ────────────────────────────────────────────────────────────────

class _DateCard extends StatelessWidget {
  final String label;
  final String day;
  final String monthYear;
  final bool isActive;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.day,
    required this.monthYear,
    required this.isActive,
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
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : AppTheme.borderColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: isActive
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.primaryBlue
                        : AppTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              day,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthYear,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stock selector ────────────────────────────────────────────────────────────

class _StockSelector extends StatelessWidget {
  final String? selected;
  final String specialStockKey;
  final ValueChanged<String?> onChanged;

  // Sample stock options
  static const List<String?> _options = [
    null, // All stocks
    'M12 Bolt Steel',
    'Copper Wire 2m',
    'Safety Gloves L',
    'SPECIAL_STOCK', // This maps to our special key
  ];

  const _StockSelector({
    required this.selected,
    required this.specialStockKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppTheme.cardBackground,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppTheme.textSecondary,
          ),
          items: _options.map((opt) {
            final isSpecial = opt == specialStockKey;
            return DropdownMenuItem<String?>(
              value: opt,
              child: Row(
                children: [
                  Icon(
                    opt == null
                        ? Icons.inventory_2_rounded
                        : isSpecial
                        ? Icons.star_rounded
                        : Icons.circle,
                    color: isSpecial ? Colors.amber : AppTheme.textSecondary,
                    size: opt == null || isSpecial ? 18 : 8,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    opt == null
                        ? 'All Stocks'
                        : isSpecial
                        ? 'Special Stock'
                        : opt,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Special Stock selector ───────────────────────────────────────────────────

class _SpecialStockSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  // Sample special stock items
  static const List<String?> _options = [
    null, // All Special items
    'Buff Board 12mm',
    'Leather – Thin',
    'Hammer Blade Pro',
    'Premium Foam XL',
  ];

  const _SpecialStockSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppTheme.cardBackground,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppTheme.primaryBlue,
          ),
          items: _options.map((opt) {
            return DropdownMenuItem<String?>(
              value: opt,
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primaryBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    opt ?? 'All Special Items',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Filter row (users / location) ─────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FilterRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
