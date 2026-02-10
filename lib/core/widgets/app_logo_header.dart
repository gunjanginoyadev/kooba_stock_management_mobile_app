import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

/// Reusable logo + title + subtitle header used in auth screens.
class LogoHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const LogoHeader({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? AppConstants.appName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          resolvedTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}


