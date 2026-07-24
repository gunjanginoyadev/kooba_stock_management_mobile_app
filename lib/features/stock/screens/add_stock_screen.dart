import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/stock/stock_refresh_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/toast_helper.dart';
import '../../items/models/item_models.dart';
import '../../items/repository/items_repository.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _repository = ItemsRepository();
  List<StockSheetItem> _items = [];
  bool _loading = true;

  StockSheetItem? _selectedItem;
  int _qty10ft = 0;
  int _qty12ft = 0;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repository.getStockSheetItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  void _showItemPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        var query = '';
        final filtered = () {
          final q = query.trim().toLowerCase();
          if (q.isEmpty) return _items;
          return _items
              .where((e) =>
                  e.typeName.toLowerCase().contains(q) ||
                  e.code.toLowerCase().contains(q) ||
                  e.finish.toLowerCase().contains(q))
              .toList();
        }();

        return StatefulBuilder(
          builder: (ctx, setModalState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select item',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search type, code, finish…',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.darkBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final it = filtered[i];
                          final isSelected = _selectedItem?.id == it.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: isSelected
                                  ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                                  : AppTheme.darkBackground,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() => _selectedItem = it);
                                  Navigator.of(ctx).pop();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardBackground,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.qr_code_2_rounded,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${it.code} · ${it.finish}',
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              it.typeName,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '10ft: ${it.qty10ft}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '12ft: ${it.qty12ft}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSave() async {
    final item = _selectedItem;
    if (item == null) {
      ToastHelper.error(context, 'Please select an item');
      return;
    }
    if (_qty10ft <= 0 && _qty12ft <= 0) {
      ToastHelper.error(context, 'Enter at least one quantity');
      return;
    }

    try {
      await _repository.recordStockEntry(
        itemId: item.id,
        entryType: 'in',
        delta10ft: _qty10ft,
        delta12ft: _qty12ft,
        notes: _notesController.text,
      );
      if (!mounted) return;
      StockRefreshNotifier.instance.notifyStockChanged();
      context.push(
        AppConstants.stockSuccessRoute,
        extra: <String, dynamic>{
          'type': 'in',
          'itemName': '${item.code} · ${item.finish}',
          'qty10ft': _qty10ft,
          'qty12ft': _qty12ft,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ToastHelper.error(context, e.toString());
    }
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
          'Stock in',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _SectionLabel('SELECT ITEM'),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              )
            else
              GestureDetector(
                onTap: _showItemPicker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedItem != null
                          ? AppTheme.primaryBlue
                          : AppTheme.borderColor,
                      width: _selectedItem != null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedItem == null
                              ? 'Tap to choose item…'
                              : '${_selectedItem!.code} · ${_selectedItem!.finish}\n${_selectedItem!.typeName}',
                          style: TextStyle(
                            color: _selectedItem == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: _selectedItem == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                'QUANTITY RECEIVED',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QtyCard(
                    label: '10 ft',
                    value: _qty10ft,
                    onChanged: (v) => setState(() => _qty10ft = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QtyCard(
                    label: '12 ft',
                    value: _qty12ft,
                    onChanged: (v) => setState(() => _qty12ft = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

          // ══ Notes ════════════════════════════════════════════════════
          const Text(
            'Notes (Optional)',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Add details about this batch (e.g., damaged box, supplier note)...',
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 24),

          // ══ Save button ══════════════════════════════════════════════
          AppPrimaryButton(
            label: 'Save stock in',
            icon: Icons.download_rounded,
            onPressed: _onSave,
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets
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
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _QtyCard extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _QtyCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => onChanged((value - 1).clamp(0, 999999)),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: AppTheme.textSecondary,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add_circle_rounded),
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
