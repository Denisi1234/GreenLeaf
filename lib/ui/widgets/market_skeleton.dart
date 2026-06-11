import 'package:flutter/material.dart';

import 'app_design.dart';

class MarketSkeleton extends StatefulWidget {
  const MarketSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.standard,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<MarketSkeleton> createState() => _MarketSkeletonState();
}

class _MarketSkeletonState extends State<MarketSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(
                alpha: 0.5 + (_controller.value * 0.5)),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
