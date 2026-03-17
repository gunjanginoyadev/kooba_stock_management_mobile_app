import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/toast_helper.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Profile',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            // Profile picture option
            Center(
              child: GestureDetector(
                onTap: () {
                  ToastHelper.info(context, 'Change profile picture');
                },
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 56,
                      backgroundColor: AppTheme.cardBackground,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Name option
            _OptionRow(
              icon: Icons.person_outline_rounded,
              label: 'Name',
              value: 'Jane Doe',
              onTap: () {
                ToastHelper.info(context, 'Edit name');
              },
            ),
            const SizedBox(height: 8),
            // Change password option
            _OptionRow(
              icon: Icons.lock_outline_rounded,
              label: 'Change password',
              onTap: () => context.push(AppConstants.forgotPasswordRoute),
            ),
            const SizedBox(height: 8),
            // Log out
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardBackground,
                        title: const Text(
                          'Log out?',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        content: const Text(
                          'You will need to log in again to access stock data.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.read<AuthBloc>().add(const LogoutEvent());
                              context.go(AppConstants.loginRoute);
                            },
                            child: const Text(
                              'Log Out',
                              style: TextStyle(color: Color(0xFFFF5252)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        value!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
    );
  }
}
