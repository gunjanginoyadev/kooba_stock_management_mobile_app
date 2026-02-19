import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

// ── Sample data model ────────────────────────────────────────────────────────
class _LogEntry {
  final String time;
  final String item;
  final String sku;
  final String category;
  final int qty;
  final String userInitials;
  final String userName;

  const _LogEntry({
    required this.time,
    required this.item,
    required this.sku,
    required this.category,
    required this.qty,
    required this.userInitials,
    required this.userName,
  });

  bool get isStockIn => qty > 0;
}

const List<_LogEntry> _sampleLogs = [
  _LogEntry(
    time: '14:30',
    item: 'M12 Bolt Steel',
    sku: 'SKU-8821-A',
    category: 'Fasteners',
    qty: 500,
    userInitials: 'JD',
    userName: 'Jane Doe',
  ),
  _LogEntry(
    time: '13:45',
    item: 'Copper Wire 2m',
    sku: 'SKU-CW-200',
    category: 'Electrical',
    qty: -120,
    userInitials: 'MS',
    userName: 'M. Smith',
  ),
  _LogEntry(
    time: '11:20',
    item: 'Safety Gloves L',
    sku: 'SKU-SG-L-01',
    category: 'PPE',
    qty: -50,
    userInitials: 'KL',
    userName: 'K. Li',
  ),
  _LogEntry(
    time: '09:05',
    item: 'Buff Board 12mm',
    sku: 'SKU-BB-12',
    category: 'Boards',
    qty: 200,
    userInitials: 'AC',
    userName: 'Alex Chen',
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// Main Screen
// ════════════════════════════════════════════════════════════════════════════

class StockReportScreen extends StatelessWidget {
  const StockReportScreen({super.key});

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Report',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date Range
                const _SheetLabel('DATE RANGE'),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(
                      child: _FilterPill(label: 'Today', isSelected: true),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: _FilterPill(label: 'This Week')),
                    SizedBox(width: 8),
                    Expanded(child: _FilterPill(label: 'This Month')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'From',
                        value: 'Oct 01, 2023',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DatePickerField(
                        label: 'To',
                        value: 'Oct 24, 2023',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Type
                const _SheetLabel('TYPE'),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(
                      child: _FilterPill(label: 'All', isSelected: true),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: _FilterPill(label: 'Stock In')),
                    SizedBox(width: 8),
                    Expanded(child: _FilterPill(label: 'Stock Out')),
                  ],
                ),
                const SizedBox(height: 20),

                // Category
                const _SheetLabel('CATEGORY'),
                const SizedBox(height: 8),
                const _DropdownField(
                  icon: Icons.category_outlined,
                  label: 'All Categories',
                ),
                const SizedBox(height: 20),

                // User
                const _SheetLabel('USER'),
                const SizedBox(height: 8),
                const _DropdownField(
                  icon: Icons.person_outline,
                  label: 'All Users',
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed app bar ────────────────────────────────────────────
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
                    'Stock Report',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),

          // ── Scrollable body ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // ── Context card ─────────────────────────────────────
                  _ContextCard(),
                  const SizedBox(height: 16),

                  // ── Action buttons ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Share',
                          icon: Icons.share_rounded,
                          color: const Color(0xFF00C853),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Download PDF',
                          icon: Icons.download_rounded,
                          color: AppTheme.primaryBlue,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Transaction log header ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction Log',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showFilterSheet(context),
                        icon: const Icon(
                          Icons.filter_list_rounded,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        label: const Text(
                          'Filter',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ── Summary chips ─────────────────────────────────────
                  Row(
                    children: [
                      _SummaryChip(
                        label: 'Total',
                        value: '142',
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        label: 'Stock In',
                        value: '98',
                        color: const Color(0xFF3DDC84),
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        label: 'Stock Out',
                        value: '44',
                        color: const Color(0xFFFF5252),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Log cards ─────────────────────────────────────────
                  ..._sampleLogs.map((e) => _LogCard(entry: e)).toList(),

                  // ── Pagination ────────────────────────────────────────
                  const SizedBox(height: 8),
                  _PaginationRow(),
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

// ════════════════════════════════════════════════════════════════════════════
// Log card — replaces the old table row
// ════════════════════════════════════════════════════════════════════════════

class _LogCard extends StatelessWidget {
  final _LogEntry entry;

  const _LogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isStockIn;
    final accentColor = isIn
        ? const Color(0xFF3DDC84)
        : const Color(0xFFFF5252);
    final bgColor = isIn ? const Color(0xFF0D3320) : const Color(0xFF3D1212);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Leading icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Item name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MetaBadge(text: entry.sku, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    _MetaBadge(
                      text: entry.category,
                      color: AppTheme.primaryBlue,
                      tinted: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right side: qty + time + user
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Qty
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isIn ? '+${entry.qty}' : '${entry.qty}',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Time + user avatar
              Row(
                children: [
                  Text(
                    entry.time,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.borderColor,
                    child: Text(
                      entry.userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool tinted;

  const _MetaBadge({
    required this.text,
    required this.color,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tinted ? color.withOpacity(0.12) : AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tinted ? color : AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Action button
// ════════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
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

// ════════════════════════════════════════════════════════════════════════════
// Summary chip strip
// ════════════════════════════════════════════════════════════════════════════

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Pagination
// ════════════════════════════════════════════════════════════════════════════

class _PaginationRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Showing 4 of 142',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Row(
          children: [
            _PageBtn(label: 'Prev', icon: Icons.chevron_left, onTap: () {}),
            const SizedBox(width: 6),
            _PageNumBtn(num: '1', isActive: true),
            const SizedBox(width: 4),
            _PageNumBtn(num: '2'),
            const SizedBox(width: 4),
            _PageNumBtn(num: '3'),
            const SizedBox(width: 6),
            _PageBtn(
              label: 'Next',
              icon: Icons.chevron_right,
              onTap: () {},
              iconTrailing: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool iconTrailing;

  const _PageBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: iconTrailing
          ? [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: AppTheme.textSecondary, size: 16),
            ]
          : [
              Icon(icon, color: AppTheme.textSecondary, size: 16),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
    );
    return GestureDetector(onTap: onTap, child: child);
  }
}

class _PageNumBtn extends StatelessWidget {
  final String num;
  final bool isActive;

  const _PageNumBtn({required this.num, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryBlue : AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        num,
        style: TextStyle(
          color: isActive ? Colors.white : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Report context card
// ════════════════════════════════════════════════════════════════════════════

class _ContextCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Context',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Daily Movement',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _ContextMetric(label: 'DATE', value: 'Oct 24, 2023'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ContextMetric(
                  label: 'TOTAL ENTRIES',
                  value: '142 Records',
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ContextMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.primaryBlue : AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Filter sheet helpers
// ════════════════════════════════════════════════════════════════════════════

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterPill({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(999),
        border: isSelected
            ? null
            : Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Center(
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

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DropdownField({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            color: AppTheme.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}
