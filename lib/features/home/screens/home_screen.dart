import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/stock/stock_refresh_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../items/models/item_models.dart';
import '../../items/repository/items_repository.dart';

enum _HomeFilter { all, low, out }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ItemsRepository();
  final _refresh = StockRefreshNotifier.instance;
  final _search = TextEditingController();
  bool _loading = true;
  _HomeFilter _filter = _HomeFilter.all;
  List<StockSheetItem> _items = const [];
  List<StockEntryV2> _recent = const [];

  @override
  void initState() {
    super.initState();
    _refresh.addListener(_onStockChanged);
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _refresh.removeListener(_onStockChanged);
    _search.dispose();
    super.dispose();
  }

  void _onStockChanged() {
    if (!mounted) return;
    _load();
  }

  int _totalQty(StockSheetItem i) => i.qty10ft + i.qty12ft;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.getStockSheetItems();
      final entries = await _repo.getStockEntries(limit: 8);
      if (!mounted) return;
      setState(() {
        _items = items;
        _recent = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _recent = const [];
        _loading = false;
      });
    }
  }

  List<StockSheetItem> get _filtered {
    var list = _items;
    switch (_filter) {
      case _HomeFilter.all:
        break;
      case _HomeFilter.low:
        list = list
            .where((i) {
              final t = _totalQty(i);
              return t > 0 && t < AppConstants.lowStockThreshold;
            })
            .toList();
      case _HomeFilter.out:
        list = list.where((i) => _totalQty(i) == 0).toList();
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (i) =>
                i.code.toLowerCase().contains(q) ||
                i.finish.toLowerCase().contains(q) ||
                i.typeName.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = _items.where((i) {
      final t = _totalQty(i);
      return t > 0 && t < AppConstants.lowStockThreshold;
    }).length;
    final outCount = _items.where((i) => _totalQty(i) == 0).length;
    final filtered = _filtered;

    return AppScaffold(
      padHorizontal: false,
      child: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KOOBA · WAREHOUSE A',
                                style: AppTheme.label.copyWith(
                                  color: AppTheme.primaryBlue,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stock overview',
                                style: GoogleFonts.sora(
                                  color: AppTheme.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quick view of levels and movements',
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.accentSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: const Icon(
                            Icons.warehouse_rounded,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _HeroStat(
                              label: 'Items',
                              value: '${_items.length}',
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.borderColor,
                          ),
                          Expanded(
                            child: _HeroStat(
                              label: 'Low',
                              value: '$lowCount',
                              color: AppTheme.warning,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.borderColor,
                          ),
                          Expanded(
                            child: _HeroStat(
                              label: 'Out',
                              value: '$outCount',
                              color: AppTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroAction(
                            label: 'Stock in',
                            icon: Icons.south_west_rounded,
                            color: AppTheme.success,
                            onTap: () =>
                                context.push(AppConstants.addStockRoute),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeroAction(
                            label: 'Stock out',
                            icon: Icons.north_east_rounded,
                            color: AppTheme.danger,
                            onTap: () =>
                                context.push(AppConstants.stockUsageRoute),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_recent.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        'Recent movement',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            context.push(AppConstants.stockHistoryRoute),
                        child: Text(
                          'See all',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _recent.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final e = _recent[index];
                      return _RecentChip(
                        entry: e,
                        onTap: () => context.push(
                          AppConstants.entryDetailsRoute,
                          extra: <String, dynamic>{'entryId': e.id},
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'Search type, code, finish…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _FilterPill(
                          label: 'All',
                          selected: _filter == _HomeFilter.all,
                          onTap: () =>
                              setState(() => _filter = _HomeFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Low',
                          selected: _filter == _HomeFilter.low,
                          onTap: () =>
                              setState(() => _filter = _HomeFilter.low),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Out',
                          selected: _filter == _HomeFilter.out,
                          onTap: () =>
                              setState(() => _filter = _HomeFilter.out),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: _EmptyInventory(
                    onAdd: () =>
                        context.push(AppConstants.addItemCategoryRoute),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final total = _totalQty(item);
                    final Color statusColor;
                    final String status;
                    if (total == 0) {
                      statusColor = AppTheme.danger;
                      status = 'Out';
                    } else if (total < AppConstants.lowStockThreshold) {
                      statusColor = AppTheme.warning;
                      status = 'Low';
                    } else {
                      statusColor = AppTheme.success;
                      status = 'OK';
                    }
                    return _InventoryRow(
                      typeName: item.typeName,
                      title: '${item.code} · ${item.finish}',
                      qtyLabel: '10ft ${item.qty10ft}  ·  12ft ${item.qty12ft}',
                      imageUrl: item.typeImageUrl,
                      status: status,
                      statusColor: statusColor,
                      onTap: () => context.push(
                        AppConstants.itemDetailsRoute,
                        extra: <String, dynamic>{'itemId': item.id},
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.sora(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeroAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  final StockEntryV2 entry;
  final VoidCallback onTap;

  const _RecentChip({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isIn;
    final color = isIn ? AppTheme.success : AppTheme.danger;
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              AppNetworkImage(
                url: entry.typeImageUrl,
                width: 52,
                height: 52,
                borderRadius: BorderRadius.circular(12),
                placeholderIcon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isIn ? 'IN' : 'OUT',
                        style: GoogleFonts.dmSans(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.itemLabel.isEmpty ? 'Item' : entry.itemLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final String typeName;
  final String title;
  final String qtyLabel;
  final String? imageUrl;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;

  const _InventoryRow({
    required this.typeName,
    required this.title,
    required this.qtyLabel,
    required this.imageUrl,
    required this.status,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              AppNetworkImage(
                url: imageUrl,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(14),
                placeholderIcon: Icons.view_in_ar_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeName.isEmpty ? 'Type' : typeName,
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      qtyLabel,
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyInventory({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 40, color: AppTheme.inkMuted),
          const SizedBox(height: 12),
          Text(
            'No items match',
            style: GoogleFonts.sora(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a stock item or clear filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add item'),
          ),
        ],
      ),
    );
  }
}
