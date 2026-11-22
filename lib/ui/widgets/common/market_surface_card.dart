import '../app_design.dart';
import 'package:flutter/material.dart';

class MarketSurfaceCard extends StatelessWidget {
  const MarketSurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius = AppRadius.standard,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
