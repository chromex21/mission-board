# Custom Notification System

## Overview
Compact, theme-matching notification overlay system that replaces Flutter's default SnackBar.

## Features
- **Compact Design**: Small, non-intrusive notifications
- **Theme Matching**: Uses app colors (purple, dark grey)
- **4 Types**: Success (green), Error (red), Warning (orange), Info (blue)
- **Animated**: Smooth slide-in from top
- **Auto-dismiss**: Configurable duration
- **Manual Dismiss**: Close button included
- **Responsive**: Adapts to screen width

## Usage

### Import
```dart
import '../../utils/notification_helper.dart';
```

### Quick Methods
```dart
// Success notification
context.showSuccess('Profile updated successfully!');

// Error notification
context.showError('Invalid credentials');

// Warning notification
context.showWarning('Low storage space');

// Info notification
context.showInfo('New feature available');
```

### Custom Duration
```dart
context.showSuccess(
  'Mission completed!',
  duration: Duration(seconds: 5),
);
```

### Custom Icon
```dart
context.showNotification(
  'Custom notification',
  type: NotificationType.success,
  icon: Icons.rocket_launch,
);
```

### Direct API
```dart
AppNotification.show(
  context,
  message: 'Custom message',
  type: NotificationType.info,
  duration: Duration(seconds: 3),
);
```

## Migration from SnackBar

### Before
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Profile updated successfully!'),
    backgroundColor: AppTheme.successGreen,
  ),
);
```

### After
```dart
context.showSuccess('Profile updated successfully!');
```

## Notification Types
- `NotificationType.success` - Green with checkmark
- `NotificationType.error` - Red with error icon
- `NotificationType.warning` - Orange with warning icon
- `NotificationType.info` - Blue with info icon

## Design Specs
- **Max Width**: 400px on desktop, screen width - 32px on mobile
- **Padding**: 16px horizontal, 12px vertical
- **Border**: 1px with type color at 30% opacity
- **Shadow**: 12px blur, 4px offset
- **Animation**: 300ms slide + fade
- **Position**: Top center with 16px margin
