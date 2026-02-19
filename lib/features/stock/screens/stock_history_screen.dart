import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

class StockHistoryScreen extends StatelessWidget {
  const StockHistoryScreen({super.key});

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter History',
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
              const Text(
                'DATE RANGE',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _FilterPill(label: 'Today', isSelected: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterPill(label: 'This Week'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterPill(label: 'This Month'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'TYPE',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Expanded(
                    child: _FilterPill(label: 'All', isSelected: true),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _FilterPill(label: 'Stock In'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _FilterPill(label: 'Stock Out'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'USER',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: const [
                    Icon(Icons.person_outline,
                        color: AppTheme.textSecondary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All Users',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded,
                        color: AppTheme.textSecondary, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppTheme.textPrimary,
              ),
              const SizedBox(width: 4),
              const Text(
                'Stock History',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'All stock-in and stock-out entries in one place.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search in history…',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
              ),
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showFilterSheet(context),
              icon: const Icon(
                Icons.filter_list_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              label: const Text(
                'Filter',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              children: const [
                _HistoryRow(
                  title: 'Stock In - Buff Board',
                  subtitle: 'Today • +50 units • by Jane Doe',
                  leadingColor: Color(0xFF104F2D),
                  qtyLabel: '+50',
                  qtyColor: Color(0xFF3DDC84),
                ),
                _HistoryRow(
                  title: 'Stock Out - Leather – Thin',
                  subtitle: 'Yesterday • -24 units • by Alex Chen',
                  leadingColor: Color(0xFF4E342E),
                  qtyLabel: '-24',
                  qtyColor: Color(0xFFFF5252),
                ),
                _HistoryRow(
                  title: 'Stock In - Hammer Blade',
                  subtitle: 'Oct 18 • +100 units • by M. Singh',
                  leadingColor: Color(0xFF104F2D),
                  qtyLabel: '+100',
                  qtyColor: Color(0xFF3DDC84),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color leadingColor;
  final String qtyLabel;
  final Color qtyColor;

  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.leadingColor,
    required this.qtyLabel,
    required this.qtyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
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
              color: leadingColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            qtyLabel,
            style: TextStyle(
              color: qtyColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterPill({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}


