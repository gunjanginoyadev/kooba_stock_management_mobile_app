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

class StockUsageScreen extends StatefulWidget {
  const StockUsageScreen({super.key});

  @override
  State<StockUsageScreen> createState() => _StockUsageScreenState();
}

class _StockUsageScreenState extends State<StockUsageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _repository = ItemsRepository();

  List<StockSheetItem> _items = [];
  bool _loading = true;
  StockSheetItem? _selectedItem;
  int _qty10ft = 0;
  int _qty12ft = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _locationController.dispose();
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
    if (!_formKey.currentState!.validate()) return;
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
        entryType: 'out',
        delta10ft: _qty10ft,
        delta12ft: _qty12ft,
        location: _locationController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      StockRefreshNotifier.instance.notifyStockChanged();
      context.push(
        AppConstants.stockSuccessRoute,
        extra: <String, dynamic>{
          'type': 'out',
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
          'Stock out',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Record which stock was used and where.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel('1. Item'),
              const SizedBox(height: 10),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  ),
                )
              else
                _SelectTile(
                  label: _selectedItem == null
                      ? 'Select item'
                      : '${_selectedItem!.code} · ${_selectedItem!.finish}',
                  hint: _selectedItem == null
                      ? 'Tap to choose item'
                      : '${_selectedItem!.typeName} · 10ft:${_selectedItem!.qty10ft} · 12ft:${_selectedItem!.qty12ft}',
                  isSelected: _selectedItem != null,
                  icon: Icons.qr_code_2_rounded,
                  onTap: _showItemPicker,
                ),
              const SizedBox(height: 24),

              _SectionLabel('2. Quantity used'),
              const SizedBox(height: 12),
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

              // Notes
              _SectionLabel(
                '3. Usage location / notes',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Zone B – Line 1, project reference…',
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter usage location or a note';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Optional notes…',
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Save stock out',
                onPressed: _onSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  final String label;
  final String hint;
  final bool isSelected;
  final IconData icon;
  final VoidCallback? onTap;

  const _SelectTile({
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 22,
            ),
          ],
        ),
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
