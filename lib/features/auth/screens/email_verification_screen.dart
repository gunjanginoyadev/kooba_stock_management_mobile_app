import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_auth_shell.dart';
import '../../../core/widgets/app_logo_header.dart';
import '../../../core/widgets/app_primary_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppAuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LogoHeader(
            title: 'Verify your email',
            subtitle:
                'We\'ve sent a verification link to your inbox. Tap the link, then continue here.',
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: const [
                Icon(Icons.email_outlined,
                    color: AppTheme.primaryBlue, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remember to check your spam folder if you don\'t see the email right away.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            label: 'I\'ve Verified My Email',
            onPressed: () {
              context.go(AppConstants.homeRoute);
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _canResend ? () {} : null,
              child: Text(
                _canResend ? 'Resend verification email' : 'Resend in a moment…',
                style: TextStyle(
                  color: _canResend
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppConstants.loginRoute),
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


