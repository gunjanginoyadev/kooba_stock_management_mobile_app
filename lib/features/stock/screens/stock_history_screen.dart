import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

// ── Demo history entries ────────────────────────────────────────────────────
class _HistoryEntry {
  final bool isStockIn;
  final String itemName;
  final int quantity;
  final String when;
  final String by;

  const _HistoryEntry({
    required this.isStockIn,
    required this.itemName,
    required this.quantity,
    required this.when,
    required this.by,
  });
}

const List<_HistoryEntry> _todayEntries = [
  _HistoryEntry(
    isStockIn: true,
    itemName: 'Buff Board 12mm',
    quantity: 50,
    when: '10:30 AM',
    by: 'You',
  ),
  _HistoryEntry(
    isStockIn: false,
    itemName: 'Leather – Thin (Materials)',
    quantity: 24,
    when: '9:15 AM',
    by: 'You',
  ),
  _HistoryEntry(
    isStockIn: true,
    itemName: 'Hammer Blade Pro',
    quantity: 12,
    when: '8:00 AM',
    by: 'You',
  ),
];

const List<_HistoryEntry> _yesterdayEntries = [
  _HistoryEntry(
    isStockIn: false,
    itemName: 'Premium Foam XL (Packaging)',
    quantity: 8,
    when: '4:45 PM',
    by: 'You',
  ),
  _HistoryEntry(
    isStockIn: true,
    itemName: 'Ply 4x8',
    quantity: 20,
    when: '11:20 AM',
    by: 'You',
  ),
];

const List<_HistoryEntry> _thisWeekEntries = [
  _HistoryEntry(
    isStockIn: true,
    itemName: 'Adhesive 5L',
    quantity: 10,
    when: 'Mon, 2:00 PM',
    by: 'You',
  ),
  _HistoryEntry(
    isStockIn: false,
    itemName: 'Drill Bit 10mm (Tools)',
    quantity: 5,
    when: 'Mon, 10:00 AM',
    by: 'You',
  ),
];

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  String _dateFilter = 'Today'; // Today, This week, This month
  String _typeFilter = 'All';   // All, Stock in, Stock out

  @override
  Widget build(BuildContext context) {
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
          'Activity history',
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
            'All stock in and stock out entries. Tap Filter to narrow down.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by item name…',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          const Text(
            'DATE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FilterChip(
                label: 'Today',
                isSelected: _dateFilter == 'Today',
                onTap: () => setState(() => _dateFilter = 'Today'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'This week',
                isSelected: _dateFilter == 'This week',
                onTap: () => setState(() => _dateFilter = 'This week'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'This month',
                isSelected: _dateFilter == 'This month',
                onTap: () => setState(() => _dateFilter = 'This month'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'TYPE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _typeFilter == 'All',
                onTap: () => setState(() => _typeFilter = 'All'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Stock in',
                isSelected: _typeFilter == 'Stock in',
                onTap: () => setState(() => _typeFilter = 'Stock in'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Stock out',
                isSelected: _typeFilter == 'Stock out',
                onTap: () => setState(() => _typeFilter = 'Stock out'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _SectionHeader(label: 'Today'),
                const SizedBox(height: 8),
                ..._todayEntries.map((e) => _HistoryTile(entry: e)),
                const SizedBox(height: 20),
                _SectionHeader(label: 'Yesterday'),
                const SizedBox(height: 8),
                ..._yesterdayEntries.map((e) => _HistoryTile(entry: e)),
                const SizedBox(height: 20),
                _SectionHeader(label: 'This week'),
                const SizedBox(height: 8),
                ..._thisWeekEntries.map((e) => _HistoryTile(entry: e)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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

class _HistoryTile extends StatelessWidget {
  final _HistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isStockIn;
    final accentColor = isIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final typeLabel = isIn ? 'Stock in' : 'Stock out';
    final qtyText = isIn ? '+${entry.quantity}' : '-${entry.quantity}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.itemName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.when} · by ${entry.by}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$qtyText units',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
