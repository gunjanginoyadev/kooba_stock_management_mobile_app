import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared page shell with canvas background and comfortable padding.
/// On wide screens (web/desktop) content is centered with a readable max width.
class AppScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool padHorizontal;
  final double maxContentWidth;

  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.padHorizontal = true,
    this.maxContentWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = padHorizontal
        ? (width >= 900 ? 32.0 : 20.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
