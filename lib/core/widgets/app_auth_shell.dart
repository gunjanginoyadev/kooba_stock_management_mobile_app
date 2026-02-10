import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Common background and padding used for Kooba auth screens.
class AppAuthShell extends StatelessWidget {
  final Widget child;

  const AppAuthShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}


