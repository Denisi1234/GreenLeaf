import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

String bankReconciliationMoney(double value, {bool showSign = true}) {
  final negative = value < 0;
  final abs = value.abs().toStringAsFixed(0);
  if (!showSign) {
    return 'TSh $abs';
  }
  return '${negative ? '-' : ''}TSh $abs';
}

class ReconciliationCard extends StatelessWidget {
  const ReconciliationCard({
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
