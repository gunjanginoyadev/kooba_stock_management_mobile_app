import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/stock/stock_refresh_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../items/repository/items_repository.dart';

class StockHubScreen extends StatefulWidget {
  const StockHubScreen({super.key});

  @override
  State<StockHubScreen> createState() => _StockHubScreenState();
}

class _StockHubScreenState extends State<StockHubScreen> {
  final _repo = ItemsRepository();
  final _refresh = StockRefreshNotifier.instance;
  bool _loading = true;
  List<_RecentActivity> _recent = const [];

  @override
  void initState() {
    super.initState();
    _refresh.addListener(_onStockChanged);
    _load();
  }

  @override
  void dispose() {
    _refresh.removeListener(_onStockChanged);
    super.dispose();
  }

  void _onStockChanged() {
    if (!mounted) return;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await _repo.getStockEntries(limit: 6);
      if (!mounted) return;
      setState(() {
        _recent = entries
            .map(
              (e) => _RecentActivity(
                id: e.id,
                label: e.itemLabel.isEmpty ? 'Item' : e.itemLabel,
                detail: e.createdAt.toLocal().toString(),
                isIn: e.isIn,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recent = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primaryBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 8),
            Text(
              'Work floor',
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a task — everything starts here',
              style: GoogleFonts.dmSans(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                _GridAction(
                  title: 'Add item',
                  subtitle: 'New type / code',
                  icon: Icons.add_rounded,
                  color: AppTheme.primaryBlue,
                  onTap: () =>
                      context.push(AppConstants.addItemCategoryRoute),
                ),
                _GridAction(
                  title: 'Stock in',
                  subtitle: 'Incoming qty',
                  icon: Icons.south_west_rounded,
                  color: AppTheme.success,
                  onTap: () => context.push(AppConstants.addStockRoute),
                ),
                _GridAction(
                  title: 'Stock out',
                  subtitle: 'Usage / dispatch',
                  icon: Icons.north_east_rounded,
                  color: AppTheme.danger,
                  onTap: () => context.push(AppConstants.stockUsageRoute),
                ),
                _GridAction(
                  title: 'Manage',
                  subtitle: 'Browse catalog',
                  icon: Icons.grid_view_rounded,
                  color: const Color(0xFF475569),
                  onTap: () => context.push(AppConstants.manageItemsRoute),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Material(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push(AppConstants.stockHistoryRoute),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accentSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full activity history',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Filter by date and stock in/out',
                              style: GoogleFonts.dmSans(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Timeline',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_recent.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  'No movements yet. Record a stock in or out.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
                ),
              )
            else
              ...List.generate(_recent.length, (index) {
                final e = _recent[index];
                final isLast = index == _recent.length - 1;
                return _TimelineRow(
                  label: e.label,
                  detail: e.detail,
                  isIn: e.isIn,
                  isLast: isLast,
                  onTap: () => context.push(
                    AppConstants.entryDetailsRoute,
                    extra: <String, dynamic>{'entryId': e.id},
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity {
  final String id;
  final String label;
  final String detail;
  final bool isIn;

  const _RecentActivity({
    required this.id,
    required this.label,
    required this.detail,
    required this.isIn,
  });
}

class _GridAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.sora(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String detail;
  final bool isIn;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineRow({
    required this.label,
    required this.detail,
    required this.isIn,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIn ? AppTheme.success : AppTheme.danger;
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 56,
                    color: AppTheme.borderColor,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIn ? 'Stock in' : 'Stock out',
                    style: GoogleFonts.dmSans(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: GoogleFonts.dmSans(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
