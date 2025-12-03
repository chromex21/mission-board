import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum NotificationType { success, error, warning, info }

class AppNotification {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    // Remove existing notification if any
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: type,
        icon: icon,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);

    // Auto dismiss
    Future.delayed(duration, () {
      if (_currentOverlay == overlayEntry) {
        overlayEntry.remove();
        _currentOverlay = null;
      }
    });
  }

  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final IconData? icon;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.icon,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return AppTheme.successGreen;
      case NotificationType.error:
        return AppTheme.errorRed;
      case NotificationType.warning:
        return AppTheme.warningOrange;
      case NotificationType.info:
        return AppTheme.infoBlue;
    }
  }

  IconData _getIcon() {
    if (widget.icon != null) return widget.icon!;

    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 400.0 : screenWidth - 32;

    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.grey900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getBackgroundColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getBackgroundColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getIcon(),
                        color: _getBackgroundColor(),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _dismiss,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: AppTheme.grey400,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
