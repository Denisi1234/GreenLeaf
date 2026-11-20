import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';

String customerDual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String formatCustomerMoney(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

enum CustomerTier { none, bronze, silver, gold, platinum }

CustomerTier tierForSpend(double spent) {
  if (spent >= 2000000) return CustomerTier.platinum;
  if (spent >= 750000) return CustomerTier.gold;
  if (spent >= 250000) return CustomerTier.silver;
  if (spent > 0) return CustomerTier.bronze;
  return CustomerTier.none;
}

extension CustomerTierX on CustomerTier {
  String label(AppStrings strings) => switch (this) {
        CustomerTier.none => customerDual(strings, 'New', 'Mpya'),
        CustomerTier.bronze => 'Bronze',
        CustomerTier.silver => 'Silver',
        CustomerTier.gold => 'Gold',
        CustomerTier.platinum => 'Platinum',
      };

  Color get color => switch (this) {
        CustomerTier.none => AppColors.textMuted,
        CustomerTier.bronze => AppColors.warningDeep,
        CustomerTier.silver => AppColors.textBody,
        CustomerTier.gold => AppColors.warning,
        CustomerTier.platinum => AppColors.primaryDeep,
      };

  Color get background => switch (this) {
        CustomerTier.none => AppColors.surfaceSecondary,
        CustomerTier.bronze => AppColors.warningLight,
        CustomerTier.silver => AppColors.surfaceHover,
        CustomerTier.gold => AppColors.warningLight,
        CustomerTier.platinum => AppColors.primaryLight,
      };
}
