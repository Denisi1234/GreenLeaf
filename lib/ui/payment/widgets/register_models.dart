import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

String formatRegisterMoney(double value, {bool signed = false}) {
  final negative = value < 0;
  final abs = formatCurrency(value.abs());
  if (signed) {
    if (value > 0) return '+TSh $abs';
    if (value < 0) return '-TSh $abs';
    return 'TSh $abs';
  }
  return '${negative ? '-' : ''}TSh $abs';
}

String formatRegisterDateTime(DateTime dt) {
  final l = dt.toLocal();
  final d = l.toString().substring(0, 10);
  final h = l.hour.toString().padLeft(2, '0');
  final m = l.minute.toString().padLeft(2, '0');
  return '$d $h:$m';
}

class RegisterFlatCard extends StatelessWidget {
  const RegisterFlatCard({
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
      showShadow: false,
      borderColor: AppColors.border,
      radius: 0,
      child: child,
    );
  }
}
