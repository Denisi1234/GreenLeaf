import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

class LedgerCard extends StatelessWidget {
  const LedgerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: padding,
      showShadow: true,
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      child: child,
    );
  }
}

class MoneyMetric extends StatelessWidget {
  const MoneyMetric({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTypography.helperText.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.h3.copyWith(
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs(
      {super.key, required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppCorners.control,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:
            AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        tabs: [for (final label in labels) Tab(height: 38, text: label)],
      ),
    );
  }
}
