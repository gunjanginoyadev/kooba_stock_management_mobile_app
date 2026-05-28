import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../models/item_models.dart';
import '../repository/items_repository.dart';

class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final _repo = ItemsRepository();
  bool _loading = true;
  StockSheetItem? _item;
  List<StockEntryV2> _entries = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    final itemId = extra is Map ? extra['itemId'] as String? : null;
    _load(itemId);
  }

  Future<void> _load(String? itemId) async {
    if (itemId == null || itemId.isEmpty) {
      setState(() {
        _loading = false;
        _item = null;
        _entries = const [];
      });
      return;
    }
    setState(() => _loading = true);
    final item = await _repo.getStockSheetItemById(itemId);
    final entries = await _repo.getStockEntries(limit: 10, itemId: itemId);
    if (!mounted) return;
    setState(() {
      _item = item;
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
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
          'Item details',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showOptionsMenu(context),
            icon: const Icon(Icons.more_vert_rounded),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              )
            else if (item == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Item not found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              _ItemHeaderCard(item: item),
            const SizedBox(height: 24),
            if (item != null) _DetailsSection(item: item),
            const SizedBox(height: 24),
            if (item != null) _HistorySection(entries: _entries),
            const SizedBox(height: 24),
            if (item != null) _OptionsSection(itemId: item.id),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Options',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _OptionTile(
                icon: Icons.edit_rounded,
                label: 'Edit item',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppConstants.editEntryRoute);
                },
              ),
              _OptionTile(
                icon: Icons.inventory_2_rounded,
                label: 'Adjust stock',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppConstants.addStockRoute);
                },
              ),
              _OptionTile(
                icon: Icons.arrow_upward_rounded,
                label: 'Record stock out',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppConstants.stockUsageRoute);
                },
              ),
              _OptionTile(
                icon: Icons.history_rounded,
                label: 'View full history',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppConstants.stockHistoryRoute);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemHeaderCard extends StatelessWidget {
  final StockSheetItem item;
  const _ItemHeaderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final total = item.qty10ft + item.qty12ft;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.typeName,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.code} · ${item.finish}',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '10ft: ${item.qty10ft} · 12ft: ${item.qty12ft}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (total == 0
                            ? const Color(0xFFFF5252)
                            : total < AppConstants.lowStockThreshold
                                ? const Color(0xFFFFC107)
                                : const Color(0xFF2E7D32))
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    total == 0
                        ? 'Out of stock'
                        : total < AppConstants.lowStockThreshold
                            ? 'Low stock'
                            : 'In stock',
                    style: TextStyle(
                      color: total == 0
                          ? const Color(0xFFFF5252)
                          : total < AppConstants.lowStockThreshold
                              ? const Color(0xFFFFC107)
                              : const Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ItemImageThumb(url: item.typeImageUrl),
              const SizedBox(height: 12),
              Text(
                '$total',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'total',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemImageThumb extends StatelessWidget {
  final String? url;

  const _ItemImageThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim();
    final hasUrl = trimmed != null && trimmed.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 72,
        height: 72,
        color: AppTheme.borderColor,
        child: !hasUrl
            ? const Icon(
                Icons.image_outlined,
                color: AppTheme.textSecondary,
                size: 34,
              )
            : Image.network(
                trimmed,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textSecondary,
                    size: 28,
                  );
                },
              ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final StockSheetItem item;
  const _DetailsSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETAILS',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _DetailRow(label: 'Type', value: item.typeName),
              const Divider(height: 24, color: AppTheme.borderColor),
              _DetailRow(label: 'Code', value: item.code),
              const Divider(height: 24, color: AppTheme.borderColor),
              _DetailRow(label: 'Finish', value: item.finish),
              const Divider(height: 24, color: AppTheme.borderColor),
              _DetailRow(label: 'Qty (10ft)', value: '${item.qty10ft}'),
              const Divider(height: 24, color: AppTheme.borderColor),
              _DetailRow(label: 'Qty (12ft)', value: '${item.qty12ft}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<StockEntryV2> entries;
  const _HistorySection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HISTORY',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppConstants.stockHistoryRoute),
              child: const Text(
                'View all',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const Text(
            'No history yet.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          )
        else
          ...entries.take(3).expand(
                (e) => [
                  _HistoryTile(entry: e),
                  const SizedBox(height: 8),
                ],
              ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final StockEntryV2 entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isIn;
    final qtyColor = isIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    return Container(
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
              color: qtyColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: qtyColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIn ? 'Stock in' : 'Stock out',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.createdAt.toLocal().toString(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            [
              if (entry.delta10ft != 0)
                '${isIn ? "+" : "-"}${entry.delta10ft} (10ft)',
              if (entry.delta12ft != 0)
                '${isIn ? "+" : "-"}${entry.delta12ft} (12ft)',
            ].join('\n'),
            style: TextStyle(
              color: qtyColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsSection extends StatelessWidget {
  final String itemId;
  const _OptionsSection({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIONS',
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
              child: _ActionButton(
                icon: Icons.arrow_downward_rounded,
                label: 'Stock in',
                color: const Color(0xFF2E7D32),
                onTap: () => context.push(AppConstants.addStockRoute),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.arrow_upward_rounded,
                label: 'Stock out',
                color: const Color(0xFFE65100),
                onTap: () => context.push(AppConstants.stockUsageRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(
              AppConstants.editEntryRoute,
              extra: <String, dynamic>{'itemId': itemId},
            ),
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('Edit item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 24),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textSecondary,
        size: 22,
      ),
      onTap: onTap,
    );
  }
}
