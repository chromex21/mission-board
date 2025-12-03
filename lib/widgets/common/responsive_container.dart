import 'package:flutter/material.dart';

class ResponsiveFormContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool useCard;

  const ResponsiveFormContainer({
    super.key,
    required this.child,
    this.padding,
    this.useCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double maxWidth;

    if (screenWidth > 1200) {
      maxWidth = 800;
    } else if (screenWidth > 800) {
      maxWidth = 600;
    } else {
      maxWidth = double.infinity;
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class ResponsiveContentContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double containerMaxWidth;

    if (maxWidth != null) {
      containerMaxWidth = maxWidth!;
    } else if (screenWidth > 1400) {
      containerMaxWidth = 1200;
    } else if (screenWidth > 900) {
      containerMaxWidth = 800;
    } else {
      containerMaxWidth = double.infinity;
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: containerMaxWidth),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
