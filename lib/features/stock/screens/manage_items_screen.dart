import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../items/models/item_models.dart';
import '../../items/repository/items_repository.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  final _repository = ItemsRepository();
  List<MapEntry<StockItemType, List<StockSheetItem>>> _typesWithItems = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!FirebaseConfig.isConfigured) {
      setState(() {
        _typesWithItems = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final types = await _repository.getItemTypes();
      final items = await _repository.getStockSheetItems();
      final byTypeId = <String, List<StockSheetItem>>{};
      for (final item in items) {
        byTypeId.putIfAbsent(item.typeId, () => []).add(item);
      }
      final pairs = <MapEntry<StockItemType, List<StockSheetItem>>>[];
      for (final t in types) {
        final list = byTypeId[t.id] ?? const <StockSheetItem>[];
        pairs.add(MapEntry(t, list));
      }
      if (mounted) {
        setState(() {
          _typesWithItems = pairs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _typesWithItems = [];
          _loading = false;
        });
      }
    }
  }

  List<MapEntry<StockItemType, List<StockSheetItem>>> get _filtered {
    if (_searchQuery.trim().isEmpty) return _typesWithItems;
    final q = _searchQuery.trim().toLowerCase();
    return _typesWithItems
        .map((e) {
          final type = e.key;
          final items = e.value
              .where((i) =>
                  i.code.toLowerCase().contains(q) ||
                  i.finish.toLowerCase().contains(q) ||
                  type.name.toLowerCase().contains(q))
              .toList();
          return MapEntry(type, items);
        })
        .where((e) => e.value.isNotEmpty)
        .toList();
  }

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
          'Manage items',
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
            'View and manage your stock sheet items.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search by type, code, finish…',
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
                    child: _SheetItemsList(
                      typesWithItems: _filtered,
                      emptyMessage: !FirebaseConfig.isConfigured
                          ? 'Sign in and add items to see them here.'
                          : 'No items yet. Tap Add new item.',
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context
                      .push(AppConstants.addItemCategoryRoute)
                      .then((_) => _load()),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Add new item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _SheetItemsList extends StatelessWidget {
  final List<MapEntry<StockItemType, List<StockSheetItem>>> typesWithItems;
  final String emptyMessage;

  const _SheetItemsList({
    required this.typesWithItems,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (typesWithItems.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          const SizedBox(height: 32),
          Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final entry in typesWithItems) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Row(
              children: [
                _TypeThumb(url: entry.key.imageUrl),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...entry.value.map(
            (item) => _SheetItemTile(
              itemId: item.id,
              code: item.code,
              finish: item.finish,
              qty10ft: item.qty10ft,
              qty12ft: item.qty12ft,
              onTap: () => context.push(
                AppConstants.itemDetailsRoute,
                extra: <String, dynamic>{'itemId': item.id},
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TypeThumb extends StatelessWidget {
  final String? url;

  const _TypeThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim();
    final hasUrl = trimmed != null && trimmed.isNotEmpty;

    if (!hasUrl) {
      return const Icon(
        Icons.view_in_ar_rounded,
        size: 18,
        color: AppTheme.primaryBlue,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.view_in_ar_rounded,
              size: 18,
              color: AppTheme.primaryBlue,
            );
          },
        ),
      ),
    );
  }
}

class _SheetItemTile extends StatelessWidget {
  final String itemId;
  final String code;
  final String finish;
  final int qty10ft;
  final int qty12ft;
  final VoidCallback? onTap;

  const _SheetItemTile({
    required this.itemId,
    required this.code,
    required this.finish,
    required this.qty10ft,
    required this.qty12ft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppTheme.primaryBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        finish,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _QtyPill(label: '10ft', value: qty10ft),
                          const SizedBox(width: 8),
                          _QtyPill(label: '12ft', value: qty12ft),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyPill extends StatelessWidget {
  final String label;
  final int value;

  const _QtyPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.borderColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}