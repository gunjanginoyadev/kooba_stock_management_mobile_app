import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/stock/stock_refresh_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/toast_helper.dart';
import '../models/item_models.dart';
import '../repository/items_repository.dart';

class EntryDetailsScreen extends StatefulWidget {
  const EntryDetailsScreen({super.key});

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  final _repo = ItemsRepository();
  bool _loading = true;
  bool _deleting = false;
  StockEntryV2? _entry;
  String? _loadedEntryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    final entryId = extra is Map ? extra['entryId'] as String? : null;
    if (entryId != _loadedEntryId) {
      _loadedEntryId = entryId;
      _load(entryId);
    }
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
    try {
      final entry = await _repo.getStockEntryById(entryId);
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entry = null;
        _loading = false;
      });
    }
  }

  String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    var hour = local.hour % 12;
    if (hour == 0) hour = 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year · $hour:$minute $period';
  }

  Future<void> _delete(StockEntryV2 entry) async {
    setState(() => _deleting = true);
    try {
      await _repo.deleteStockEntry(entry.id);
      if (!mounted) return;
      StockRefreshNotifier.instance.notifyStockChanged();
      ToastHelper.success(context, 'Entry deleted');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      ToastHelper.error(context, msg);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final isIn = entry?.isIn ?? true;
    final accent = isIn ? AppTheme.success : AppTheme.danger;

    return AppScaffold(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppTheme.textPrimary,
              ),
              Expanded(
                child: Text(
                  'Entry details',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : entry == null
                    ? Center(
                        child: Text(
                          'Entry not found',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          _HeroCard(
                            entry: entry,
                            accent: accent,
                            whenLabel: _formatWhen(entry.createdAt),
                          ),
                          const SizedBox(height: 20),
                          Text('DETAILS', style: AppTheme.label),
                          const SizedBox(height: 10),
                          _DetailsCard(
                            children: [
                              _DetailLine(
                                label: 'Performed by',
                                value: (entry.enteredByName?.trim().isNotEmpty ??
                                        false)
                                    ? entry.enteredByName!.trim()
                                    : '—',
                              ),
                              _DetailLine(
                                label: 'Date & time',
                                value: _formatWhen(entry.createdAt),
                              ),
                              if ((entry.location?.trim().isNotEmpty ?? false))
                                _DetailLine(
                                  label: 'Location',
                                  value: entry.location!.trim(),
                                ),
                              if ((entry.notes?.trim().isNotEmpty ?? false))
                                _DetailLine(
                                  label: 'Notes',
                                  value: entry.notes!.trim(),
                                ),
                              _DetailLine(
                                label: 'Entry ID',
                                value: entry.id,
                                mono: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AppPrimaryButton(
                            label: 'Edit entry',
                            icon: Icons.edit_rounded,
                            onPressed: () async {
                              await context.push(
                                AppConstants.editEntryRoute,
                                extra: <String, dynamic>{'entryId': entry.id},
                              );
                              if (!mounted) return;
                              _load(entry.id);
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _deleting
                                  ? null
                                  : () => _delete(entry),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.danger,
                                side: BorderSide(
                                  color: AppTheme.danger.withValues(alpha: 0.45),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _deleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.danger,
                                      ),
                                    )
                                  : Text(
                                      'Delete entry',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final StockEntryV2 entry;
  final Color accent;
  final String whenLabel;

  const _HeroCard({
    required this.entry,
    required this.accent,
    required this.whenLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isIn;
    final hasImage =
        entry.typeImageUrl != null && entry.typeImageUrl!.trim().isNotEmpty;
    final qty = [
      if (entry.delta10ft != 0)
        '${isIn ? '+' : '-'}${entry.delta10ft} (10ft)',
      if (entry.delta12ft != 0)
        '${isIn ? '+' : '-'}${entry.delta12ft} (12ft)',
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: hasImage
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return AppNetworkImage(
                        url: entry.typeImageUrl,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.zero,
                        placeholderIcon: Icons.inventory_2_outlined,
                      );
                    },
                  )
                : Container(
                    color: accent.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Icon(
                      isIn
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: accent,
                      size: 42,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isIn ? 'STOCK IN' : 'STOCK OUT',
                        style: GoogleFonts.dmSans(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      whenLabel,
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.itemLabel.isEmpty ? 'Item' : entry.itemLabel,
                  style: GoogleFonts.sora(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    qty.isEmpty ? 'No quantity' : qty,
                    style: GoogleFonts.dmSans(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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

class _DetailsCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, color: AppTheme.borderColor),
          ],
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailLine({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                color: AppTheme.textPrimary,
                fontSize: mono ? 12 : 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
