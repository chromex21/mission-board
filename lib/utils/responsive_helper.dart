import 'package:flutter/material.dart';

/// Responsive breakpoints for the application
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  static bool shouldShowSidebar(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }
}

/// Responsive padding values
class AppPadding {
  static EdgeInsets page(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (AppBreakpoints.isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  static EdgeInsets card(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  static EdgeInsets dialog(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }
}

/// Responsive sizing for content containers
class AppSizing {
  /// Maximum width for content areas
  static double maxContentWidth(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return double.infinity;
    } else if (AppBreakpoints.isTablet(context)) {
      return 800;
    } else {
      return 1200;
    }
  }

  /// Maximum width for form containers
  static double maxFormWidth(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return double.infinity;
    } else if (AppBreakpoints.isTablet(context)) {
      return 600;
    } else {
      return 800;
    }
  }

  /// Maximum width for cards
  static double maxCardWidth(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return double.infinity;
    } else {
      return 600;
    }
  }

  /// Grid crossAxisCount based on available width
  static int gridColumns(BuildContext context, {double itemWidth = 300}) {
    final width = MediaQuery.of(context).size.width;
    final availableWidth =
        width - (AppBreakpoints.shouldShowSidebar(context) ? 240 : 0);

    if (availableWidth < 600) return 1;
    if (availableWidth < 900) return 2;
    if (availableWidth < 1200) return 3;
    return 4;
  }
}

/// Responsive text scaling
class AppTextScale {
  static double scale(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return 0.9;
    } else if (AppBreakpoints.isTablet(context)) {
      return 1.0;
    } else {
      return 1.0;
    }
  }
}

/// Helper widget for responsive content
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool center;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? AppSizing.maxContentWidth(context);
    final effectivePadding = padding ?? AppPadding.page(context);

    Widget content = Container(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      padding: effectivePadding,
      child: child,
    );

    if (center && !AppBreakpoints.isMobile(context)) {
      content = Center(child: content);
    }

    return content;
  }
}

/// Helper widget for responsive grid
class ResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemWidth = 300,
    this.spacing = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = AppSizing.gridColumns(context, itemWidth: itemWidth);

    return GridView.builder(
      padding: padding ?? AppPadding.page(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.4,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Helper to get available content width (excluding sidebar)
class ResponsiveHelper {
  static double availableWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = AppBreakpoints.shouldShowSidebar(context) ? 240 : 0;
    return screenWidth - sidebarWidth;
  }

  static bool shouldUseSingleColumn(BuildContext context) {
    return availableWidth(context) < 600;
  }
}
