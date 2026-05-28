import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../models/item_models.dart';
import '../repository/items_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/toast_helper.dart';

class EntryDetailsScreen extends StatefulWidget {
  const EntryDetailsScreen({super.key});

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  final _repo = ItemsRepository();
  bool _loading = true;
  StockEntryV2? _entry;
  bool _deleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    final entryId = extra is Map ? extra['entryId'] as String? : null;
    _load(entryId);
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

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    return AppScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      'Entry Details',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_rounded),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              )
            else if (entry == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Entry not found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              _HeaderCard(entry: entry),
            const SizedBox(height: 24),
            const Text(
              'TRANSACTION INFO',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person_outline,
              iconBg: Color(0xFF263238),
              label: 'Performed by',
              value: 'You',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              iconBg: Color(0xFF263238),
              label: 'Date & Time',
              value: entry?.createdAt.toLocal().toString() ?? '—',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on_outlined,
              iconBg: Color(0xFF4E342E),
              label: 'Destination',
              value: entry?.location ?? '—',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.description_outlined,
              iconBg: Color(0xFF4A148C),
              label: 'Notes',
              value: entry?.notes ?? '—',
              isMultiline: true,
            ),
            const SizedBox(height: 24),
            if (entry != null)
              Center(
                child: Text(
                  'Entry ID: ${entry.id}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Edit Entry',
              icon: Icons.edit_rounded,
              onPressed: () {
                if (entry == null) return;
                context.push(
                  AppConstants.editEntryRoute,
                  extra: <String, dynamic>{'entryId': entry.id},
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5252),
                  side: const BorderSide(color: Color(0x33FF5252)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _deleting
                    ? null
                    : () async {
                        if (entry == null) return;
                        final ctx = context;
                        setState(() => _deleting = true);
                        try {
                          await _repo.deleteStockEntry(entry.id);
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          ToastHelper.success(ctx, 'Entry deleted');
                          // ignore: use_build_context_synchronously
                          ctx.pop();
                        } catch (e) {
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          ToastHelper.error(ctx, e.toString());
                        } finally {
                          if (mounted) setState(() => _deleting = false);
                        }
                      },
                child: const Text(
                  'Delete Entry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final StockEntryV2 entry;
  const _HeaderCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isIn;
    final color = isIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _EntryImage(url: entry.typeImageUrl),
          ),
          const SizedBox(height: 16),
          Text(
            entry.itemLabel.isEmpty ? 'Item' : entry.itemLabel,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isIn ? 'Stock in' : 'Stock out',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              [
                if (entry.delta10ft != 0)
                  '${isIn ? "+" : "-"}${entry.delta10ft} (10ft)',
                if (entry.delta12ft != 0)
                  '${isIn ? "+" : "-"}${entry.delta12ft} (12ft)',
              ].join(' · '),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isIn ? 'Stock Adjustment (Inbound)' : 'Stock Adjustment (Outbound)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryImage extends StatelessWidget {
  final String? url;
  const _EntryImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim();
    final hasUrl = trimmed != null && trimmed.isNotEmpty;
    if (!hasUrl) {
      return const Icon(
        Icons.inventory_2_rounded,
        color: Colors.white,
        size: 36,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;
  final bool isMultiline;

  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.4,
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


