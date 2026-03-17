import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ToastHelper {
  static OverlayEntry? _currentToast;

  static const Duration _toastDuration = Duration(seconds: 2);

  static void _showToast(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    _removeCurrentToast();

    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          message: message,
          backgroundColor: backgroundColor,
          icon: icon,
          duration: _toastDuration,
          onDismissed: () {
            _removeCurrentToast();
          },
        );
      },
    );

    _currentToast = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void _removeCurrentToast() {
    _currentToast?.remove();
    _currentToast = null;
  }

  static void info(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      backgroundColor: AppTheme.primaryBlue,
      icon: Icons.info_outline,
    );
  }

  static void success(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      backgroundColor: const Color(0xFF2E7D32),
      icon: Icons.check_circle_outline,
    );
  }

  static void error(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      backgroundColor: const Color(0xFFFF5252),
      icon: Icons.error_outline,
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _autoDismiss();
  }

  Future<void> _autoDismiss() async {
    await Future.delayed(widget.duration);

    if (mounted) {
      await _controller.reverse();
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildToastContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToastContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
