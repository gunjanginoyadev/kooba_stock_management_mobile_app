import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared network image with loading / error placeholders.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim();
    final radius = borderRadius ?? BorderRadius.circular(12);

    Widget child;
    if (trimmed == null || trimmed.isEmpty) {
      child = _Placeholder(icon: placeholderIcon);
    } else {
      child = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppTheme.cardBackground,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _Placeholder(icon: Icons.broken_image_outlined),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  const _Placeholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.borderColor.withValues(alpha: 0.35),
      child: Center(
        child: Icon(icon, color: AppTheme.textSecondary, size: 22),
      ),
    );
  }
}
