# Responsive Design System

## Overview

This app now includes a comprehensive responsive design system to handle different screen sizes and prevent overflow issues. The system automatically adapts the layout based on the device's screen width.

## Breakpoints

```dart
- Mobile: < 600px (smartphones)
- Tablet: 600px - 1200px (tablets, small laptops)
- Desktop: > 1200px (large screens)
```

## Key Components

### 1. AppBreakpoints
Provides screen size detection:
- `isMobile(context)` - Returns true for mobile screens
- `isTablet(context)` - Returns true for tablet screens
- `isDesktop(context)` - Returns true for desktop screens
- `shouldShowSidebar(context)` - Returns true if sidebar should be visible (≥900px)

### 2. AppPadding
Context-aware padding that adapts to screen size:
- `page(context)` - 12px (mobile) / 16px (tablet) / 20px (desktop)
- `card(context)` - 12px (mobile) / 16px (tablet) / 20px (desktop)
- `dialog(context)` - 16px (mobile) / 20px (tablet) / 24px (desktop)

### 3. AppSizing
Maximum width constraints for content:
- `maxContentWidth(context)` - ∞ (mobile) / 800px (tablet) / 1200px (desktop)
- `maxFormWidth(context)` - ∞ (mobile) / 600px (tablet) / 800px (desktop)
- `maxCardWidth(context)` - ∞ (mobile) / ∞ (tablet) / 600px (desktop)
- `gridColumns(context, availableWidth)` - Calculates grid columns based on available width

### 4. ResponsiveContent
A wrapper widget that centers and constrains content:
```dart
ResponsiveContent(
  maxWidth: AppSizing.maxContentWidth(context),
  child: YourContent(),
)
```

### 5. ResponsiveGrid
A grid layout that automatically adjusts columns based on screen width:
```dart
ResponsiveGrid(
  padding: AppPadding.page(context),
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### 6. ResponsiveHelper
Utility class for calculations:
- `availableWidth(context, sidebarExpanded)` - Calculates available width accounting for sidebar

## Layout Features

### AppLayout
- **Mobile (< 900px)**: Sidebar hidden, accessible via drawer menu
- **Tablet/Desktop (≥ 900px)**: Sidebar always visible
- Automatically adds menu button to AppTopBar on mobile
- Adds drawer navigation for mobile users

### Content Areas
All major screens now wrapped with `ResponsiveContent` to:
- Prevent overflow when sidebar collapses
- Center content on large screens
- Apply appropriate padding based on screen size
- Constrain content width for better readability

## Updated Screens

The following screens now use the responsive system:

1. **Profile Screen** - Uses ResponsiveContent with maxContentWidth
2. **Settings Screen** - Uses ResponsiveContent with page padding
3. **Teams Screen** - Uses ResponsiveGrid for team cards

## Usage Example

### Basic Screen with Responsive Layout
```dart
import '../../utils/responsive_helper.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: '/my-route',
      title: 'My Screen',
      onNavigate: (route) => Navigator.pushReplacementNamed(context, route),
      child: ResponsiveContent(
        maxWidth: AppSizing.maxContentWidth(context),
        child: SingleChildScrollView(
          padding: AppPadding.page(context),
          child: Column(
            children: [
              // Your content here
            ],
          ),
        ),
      ),
    );
  }
}
```

### Grid Layout
```dart
ResponsiveGrid(
  padding: AppPadding.page(context),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return MyCard(item: items[index]);
  },
)
```

### Conditional Rendering
```dart
if (AppBreakpoints.isMobile(context))
  // Mobile-specific widget
else if (AppBreakpoints.isTablet(context))
  // Tablet-specific widget
else
  // Desktop-specific widget
```

## Benefits

1. **No More Overflow**: Content automatically adjusts to available width
2. **Better Mobile Experience**: Drawer navigation, optimized spacing
3. **Improved Desktop Experience**: Content centered, not stretched too wide
4. **Maintainable**: Centralized sizing and spacing constants
5. **Consistent**: All screens follow the same responsive patterns

## Testing

To test responsive behavior:
1. Run app on Chrome: `flutter run -d chrome`
2. Open Chrome DevTools (F12)
3. Toggle device toolbar (Ctrl+Shift+M)
4. Test at different screen widths:
   - Mobile: 375px (iPhone), 414px (iPhone Plus)
   - Tablet: 768px (iPad), 1024px (iPad Pro)
   - Desktop: 1280px, 1920px

## Future Enhancements

- Add landscape orientation handling
- Implement orientation-specific layouts
- Add responsive font sizes
- Create responsive spacing system for margins
