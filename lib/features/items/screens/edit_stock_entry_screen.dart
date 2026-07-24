import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/stock/stock_refresh_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/toast_helper.dart';
import '../models/item_models.dart';
import '../repository/items_repository.dart';

class EditStockEntryScreen extends StatefulWidget {
  const EditStockEntryScreen({super.key});

  @override
  State<EditStockEntryScreen> createState() => _EditStockEntryScreenState();
}

class _EditStockEntryScreenState extends State<EditStockEntryScreen> {
  final _repo = ItemsRepository();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  StockEntryV2? _entry;
  int _qty10 = 0;
  int _qty12 = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    final entryId = extra is Map ? extra['entryId'] as String? : null;
    _load(entryId);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _load(String? entryId) async {
    if (entryId == null || entryId.isEmpty) {
      setState(() {
        _loading = false;
        _entry = null;
      });
      return;
    }
    setState(() => _loading = true);
    final entry = await _repo.getStockEntryById(entryId);
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _qty10 = entry?.delta10ft ?? 0;
      _qty12 = entry?.delta12ft ?? 0;
      _locationController.text = entry?.location ?? '';
      _notesController.text = entry?.notes ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final entry = _entry;
    if (entry == null) return;
    if (_qty10 <= 0 && _qty12 <= 0) {
      ToastHelper.error(context, 'Enter at least one quantity');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.updateStockEntry(
        entryId: entry.id,
        newDelta10ft: _qty10,
        newDelta12ft: _qty12,
        newLocation: _locationController.text,
        newNotes: _notesController.text,
      );
      if (!mounted) return;
      StockRefreshNotifier.instance.notifyStockChanged();
      ToastHelper.success(context, 'Entry updated');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg =
          e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      ToastHelper.error(context, msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final entry = _entry;
    if (entry == null) return;
    setState(() => _saving = true);
    try {
      await _repo.deleteStockEntry(entry.id);
      if (!mounted) return;
      StockRefreshNotifier.instance.notifyStockChanged();
      ToastHelper.success(context, 'Entry deleted');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg =
          e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      ToastHelper.error(context, msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Edit Stock Entry',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : _save,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            )
          else if (entry == null)
            const Expanded(
              child: Center(
                child: Text(
                  'Entry not found',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else ...[
            _ItemSummaryCard(entry: entry),
          const SizedBox(height: 24),
          const Text(
            'Quantity Adjustment',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _QtyCard(
                    label: '10 ft',
                    value: _qty10,
                    onChanged: (v) => setState(() => _qty10 = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QtyCard(
                    label: '12 ft',
                    value: _qty12,
                    onChanged: (v) => setState(() => _qty12 = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Previous: 10ft ${entry.delta10ft}, 12ft ${entry.delta12ft}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Text(
              'Edits are checked against full history. If changing this '
              'quantity would make stock negative at any past point, it '
              'will be blocked — use a new stock in/out to correct.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Usage Location / Notes',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Shelf B2, for Project X',
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
              style: const TextStyle(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetaChip(
                label: 'LAST UPDATED',
                value: entry.createdAt.toLocal().toString(),
              ),
              const SizedBox(width: 8),
              _MetaChip(
                label: 'UPDATED BY',
                value: entry.enteredByName ?? '—',
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Update Entry',
            icon: Icons.save_rounded,
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _saving ? null : _delete,
              child: const Text(
                'Delete this entry',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _ItemSummaryCard extends StatelessWidget {
  final StockEntryV2 entry;

  const _ItemSummaryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(18),
            ),
              child: _EntryItemThumb(url: entry.typeImageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  entry.itemLabel.isEmpty ? 'Item' : entry.itemLabel,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  entry.isIn ? 'Stock in' : 'Stock out',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  entry.location ?? '—',
                  style: TextStyle(
                    color: Color(0xFF3DDC84),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryItemThumb extends StatelessWidget {
  final String? url;
  const _EntryItemThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim();
    final hasUrl = trimmed != null && trimmed.isNotEmpty;
    if (!hasUrl) {
      return const Icon(Icons.image_outlined, color: Colors.white);
    }
    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image_outlined, color: Colors.white),
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
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(12),
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
                  fontSize: 22,
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

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
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
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


