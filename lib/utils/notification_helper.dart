import 'package:flutter/material.dart';
import '../widgets/notifications/app_notification.dart';

extension NotificationExtension on BuildContext {
  void showSuccess(String message, {Duration? duration}) {
    AppNotification.show(
      this,
      message: message,
      type: NotificationType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void showError(String message, {Duration? duration}) {
    AppNotification.show(
      this,
      message: message,
      type: NotificationType.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  void showWarning(String message, {Duration? duration}) {
    AppNotification.show(
      this,
      message: message,
      type: NotificationType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void showInfo(String message, {Duration? duration}) {
    AppNotification.show(
      this,
      message: message,
      type: NotificationType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void showNotification(
    String message, {
    NotificationType type = NotificationType.info,
    Duration? duration,
    IconData? icon,
  }) {
    AppNotification.show(
      this,
      message: message,
      type: type,
      duration: duration ?? const Duration(seconds: 3),
      icon: icon,
    );
  }
}
