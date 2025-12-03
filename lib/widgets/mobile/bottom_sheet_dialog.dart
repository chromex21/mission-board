import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BottomSheetAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const BottomSheetAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });
}

class BottomSheetListItem<T> {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final T? value;
  final VoidCallback? onTap;
  final bool isDestructive;

  const BottomSheetListItem({
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.value,
    this.onTap,
    this.isDestructive = false,
  });
}

class BottomSheetDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<BottomSheetAction>? actions,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.grey900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            if (enableDrag)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grey600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                  if (isDismissible)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.grey400),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: child,
              ),
            ),
            // Actions
            if (actions != null && actions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.grey800,
                  border: Border(top: BorderSide(color: AppTheme.grey700)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: action.isPrimary
                          ? ElevatedButton(
                              onPressed: action.onPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                                foregroundColor: AppTheme.white,
                              ),
                              child: Text(action.label),
                            )
                          : TextButton(
                              onPressed: action.onPressed,
                              child: Text(action.label),
                            ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<T?> showList<T>({
    required BuildContext context,
    required String title,
    required List<BottomSheetListItem<T>> items,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.grey900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ),
            // Items
            ...items.map((item) {
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop(item.value);
                  item.onTap?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.grey700)),
                  ),
                  child: Row(
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          color: item.iconColor ?? AppTheme.white,
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 16,
                                color: item.isDestructive
                                    ? AppTheme.errorRed
                                    : AppTheme.white,
                              ),
                            ),
                            if (item.subtitle != null)
                              Text(
                                item.subtitle!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.grey400,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (item.trailing != null) item.trailing!,
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
