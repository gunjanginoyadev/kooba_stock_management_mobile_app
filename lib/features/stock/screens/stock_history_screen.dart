import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/config/supabase_config.dart';

class _HistoryEntry {
  final String id;
  final bool isStockIn;
  final String itemName;
  final int delta10ft;
  final int delta12ft;
  final DateTime when;

  const _HistoryEntry({
    required this.id,
    required this.isStockIn,
    required this.itemName,
    required this.delta10ft,
    required this.delta12ft,
    required this.when,
  });
}

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  String _dateFilter = 'Today'; // Today, This week, This month
  String _typeFilter = 'All';   // All, Stock in, Stock out
  String _searchQuery = '';
  bool _loading = true;
  List<_HistoryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _entries = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not signed in');

      final res = await client
          .from('stock_entries_v2')
          .select('id, created_at, entry_type, delta_10ft, delta_12ft, items_v2(code, finish, item_types(name))')
          .order('created_at', ascending: false)
          .limit(200);

      final list = (res as List).map((row) {
        final map = row as Map<String, dynamic>;
        final item = map['items_v2'] as Map<String, dynamic>?;
        final type = item?['item_types'] as Map<String, dynamic>?;
        final typeName = (type?['name'] as String?) ?? '';
        final code = (item?['code'] as String?) ?? '';
        final finish = (item?['finish'] as String?) ?? '';

        return _HistoryEntry(
          id: map['id'] as String,
          isStockIn: map['entry_type'] == 'in',
          itemName: [typeName, code.isEmpty ? null : code, finish.isEmpty ? null : finish]
              .whereType<String>()
              .where((e) => e.trim().isNotEmpty)
              .join(' · '),
          delta10ft: (map['delta_10ft'] as num?)?.toInt() ?? 0,
          delta12ft: (map['delta_12ft'] as num?)?.toInt() ?? 0,
          when: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = [];
        _loading = false;
      });
    }
  }

  List<_HistoryEntry> get _filteredEntries {
    var list = _entries;
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) => e.itemName.toLowerCase().contains(q)).toList();
    }

    if (_typeFilter == 'Stock in') {
      list = list.where((e) => e.isStockIn).toList();
    } else if (_typeFilter == 'Stock out') {
      list = list.where((e) => !e.isStockIn).toList();
    }

    final now = DateTime.now();
    DateTime cutoff;
    if (_dateFilter == 'Today') {
      cutoff = DateTime(now.year, now.month, now.day);
    } else if (_dateFilter == 'This week') {
      cutoff = now.subtract(const Duration(days: 7));
    } else {
      cutoff = now.subtract(const Duration(days: 30));
    }
    list = list.where((e) => e.when.isAfter(cutoff)).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
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
            onChanged: (v) => setState(() => _searchQuery = v),
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
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primaryBlue,
                    child: entries.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'No history yet',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            children: [
                              const SizedBox(height: 8),
                              for (final e in entries) _HistoryTile(entry: e),
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
    final qty10Text =
        entry.delta10ft == 0 ? null : '${isIn ? "+" : "-"}${entry.delta10ft} (10ft)';
    final qty12Text =
        entry.delta12ft == 0 ? null : '${isIn ? "+" : "-"}${entry.delta12ft} (12ft)';
    final whenText = '${entry.when}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push(
            '/entry-details',
            extra: <String, dynamic>{'entryId': entry.id},
          ),
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
                        whenText,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  [qty10Text, qty12Text].whereType<String>().join('\n'),
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
