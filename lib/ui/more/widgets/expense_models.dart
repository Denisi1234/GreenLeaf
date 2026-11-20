import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';

String expenseDual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String formatExpenseMoney(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

enum ExpenseSortMode { newest, oldest, highest, lowest }

extension ExpenseSortModeX on ExpenseSortMode {
  String label(AppStrings strings) => switch (this) {
        ExpenseSortMode.newest => expenseDual(strings, 'Newest first', 'Mpya kwanza'),
        ExpenseSortMode.oldest => expenseDual(strings, 'Oldest first', 'Zamani kwanza'),
        ExpenseSortMode.highest => expenseDual(strings, 'Highest amount', 'Kiasi kikubwa'),
        ExpenseSortMode.lowest => expenseDual(strings, 'Lowest amount', 'Kiasi kidogo'),
      };

  IconData get icon => switch (this) {
        ExpenseSortMode.newest => Icons.schedule_rounded,
        ExpenseSortMode.oldest => Icons.history_rounded,
        ExpenseSortMode.highest => Icons.trending_up_rounded,
        ExpenseSortMode.lowest => Icons.trending_down_rounded,
      };
}

enum ExpenseRange { today, thisWeek, thisMonth, lastMonth, all, custom }

extension ExpenseRangeX on ExpenseRange {
  String label(AppStrings strings) => switch (this) {
        ExpenseRange.today => expenseDual(strings, 'Today', 'Leo'),
        ExpenseRange.thisWeek => expenseDual(strings, 'This week', 'Wiki hii'),
        ExpenseRange.thisMonth => expenseDual(strings, 'This month', 'Mwezi huu'),
        ExpenseRange.lastMonth =>
          expenseDual(strings, 'Last month', 'Mwezi uliopita'),
        ExpenseRange.all => expenseDual(strings, 'All time', 'Muda wote'),
        ExpenseRange.custom =>
          expenseDual(strings, 'Custom range', 'Kipindi maalum'),
      };
}

class CategoryStyle {
  const CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const _known = <String, CategoryStyle>{
    'Operations': CategoryStyle(Icons.settings_outlined, AppColors.primary),
    'Inventory': CategoryStyle(Icons.inventory_2_outlined, AppColors.toneTeal),
    'Rent': CategoryStyle(Icons.home_work_outlined, AppColors.ink),
    'Utilities': CategoryStyle(Icons.bolt_outlined, AppColors.warning),
    'Marketing': CategoryStyle(Icons.campaign_outlined, AppColors.toneIndigo),
    'Transport':
        CategoryStyle(Icons.local_shipping_outlined, AppColors.toneViolet),
    'Office':
        CategoryStyle(Icons.business_center_outlined, AppColors.primaryDeep),
    'Supplies':
        CategoryStyle(Icons.shopping_basket_outlined, AppColors.success),
    'Maintenance': CategoryStyle(Icons.build_outlined, AppColors.textMuted),
  };

  static CategoryStyle forName(String name) {
    return _known[name] ??
        const CategoryStyle(Icons.receipt_long_outlined, AppColors.textMuted);
  }
}
