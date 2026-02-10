import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';

class ReportFiltersScreen extends StatelessWidget {
  const ReportFiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      'Report Filters',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'TIMEFRAME',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _DateCard(
                    label: 'Start Date',
                    date: '01',
                    monthYear: 'Oct 2023',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _DateCard(
                    label: 'End Date',
                    date: '31',
                    monthYear: 'Oct 2023',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _TimeframeChip(label: 'This Month', isSelected: true),
                SizedBox(width: 8),
                _TimeframeChip(label: 'Last Month'),
                SizedBox(width: 8),
                _TimeframeChip(label: 'Last Quarter'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'REPORT CRITERIA',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const _FilterRow(
              icon: Icons.inventory_2_rounded,
              iconBg: Color(0xFF1A237E),
              title: 'Electronics',
              subtitle: 'Computer parts, Sensors, Cables',
            ),
            const SizedBox(height: 12),
            const _FilterRow(
              icon: Icons.people_alt_outlined,
              iconBg: Color(0xFF4A148C),
              title: 'All Users',
              subtitle: 'Warehouse Staff, Managers',
            ),
            const SizedBox(height: 12),
            const _FilterRow(
              icon: Icons.home_work_outlined,
              iconBg: Color(0xFF4E342E),
              title: 'Main Depot - London',
              subtitle: 'Zone A, B & C',
            ),
            const SizedBox(height: 24),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Generate Report',
              icon: Icons.bar_chart_rounded,
              onPressed: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final String date;
  final String monthYear;

  const _DateCard({
    required this.label,
    required this.date,
    required this.monthYear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            date,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            monthYear,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeframeChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TimeframeChip({
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _FilterRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}


