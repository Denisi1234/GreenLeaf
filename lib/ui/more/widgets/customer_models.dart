import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

enum CustomerSortMode { newest, oldest, name, highestSpend, mostOrders, debtors }

extension CustomerSortModeExt on CustomerSortMode {
  String label(AppStrings strings) => switch (this) {
        CustomerSortMode.newest => _dual(strings, 'Newest first', 'Mpya kwanza'),
        CustomerSortMode.oldest => _dual(strings, 'Oldest first', 'Zamani kwanza'),
        CustomerSortMode.name => _dual(strings, 'Name (A-Z)', 'Jina (A-Z)'),
        CustomerSortMode.highestSpend =>
          _dual(strings, 'Highest spend', 'Matumizi makubwa'),
        CustomerSortMode.mostOrders => _dual(strings, 'Most orders', 'Oda nyingi'),
        CustomerSortMode.debtors => _dual(strings, 'Debt balance', 'Madeni'),
      };

  IconData get icon => switch (this) {
        CustomerSortMode.newest => Icons.schedule_rounded,
        CustomerSortMode.oldest => Icons.history_rounded,
        CustomerSortMode.name => Icons.sort_by_alpha_rounded,
        CustomerSortMode.highestSpend => Icons.trending_up_rounded,
        CustomerSortMode.mostOrders => Icons.receipt_long_rounded,
        CustomerSortMode.debtors => Icons.account_balance_wallet_outlined,
      };
}

enum CustomerFilterOption { all, vip, wholesale, debtors, recent }

CustomerFilterOption filterFromName(String value) {
  for (final filter in CustomerFilterOption.values) {
    if (filter.name == value) return filter;
  }
  return CustomerFilterOption.all;
}

extension CustomerFilterOptionExt on CustomerFilterOption {
  String get name => switch (this) {
        CustomerFilterOption.all => 'all',
        CustomerFilterOption.vip => 'vip',
        CustomerFilterOption.wholesale => 'wholesale',
        CustomerFilterOption.debtors => 'debtors',
        CustomerFilterOption.recent => 'new',
      };

  String label(AppStrings strings) => switch (this) {
        CustomerFilterOption.all => _dual(strings, 'All', 'Zote'),
        CustomerFilterOption.vip => 'VIP',
        CustomerFilterOption.wholesale => _dual(strings, 'Wholesale', 'Jumla'),
        CustomerFilterOption.debtors => _dual(strings, 'Debtors', 'Wadaiwa'),
        CustomerFilterOption.recent =>
          _dual(strings, 'New (30d)', 'Wapya (siku 30)'),
      };
}

class CustomerStats {
  const CustomerStats({
    required this.orders,
    required this.spent,
    required this.lastOrder,
  });

  final int orders;
  final double spent;
  final DateTime? lastOrder;

  static const empty = CustomerStats(orders: 0, spent: 0, lastOrder: null);
}

enum LoyaltyTier { none, bronze, silver, gold, platinum }

LoyaltyTier tierForSpend(double spent) {
  if (spent >= 2000000) return LoyaltyTier.platinum;
  if (spent >= 750000) return LoyaltyTier.gold;
  if (spent >= 250000) return LoyaltyTier.silver;
  if (spent > 0) return LoyaltyTier.bronze;
  return LoyaltyTier.none;
}

extension LoyaltyTierExt on LoyaltyTier {
  String label(AppStrings strings) => switch (this) {
        LoyaltyTier.none => _dual(strings, 'New', 'Mpya'),
        LoyaltyTier.bronze => 'Bronze',
        LoyaltyTier.silver => 'Silver',
        LoyaltyTier.gold => 'Gold',
        LoyaltyTier.platinum => 'Platinum',
      };

  Color get color => switch (this) {
        LoyaltyTier.none => AppColors.textMuted,
        LoyaltyTier.bronze => AppColors.warningDeep,
        LoyaltyTier.silver => AppColors.textBody,
        LoyaltyTier.gold => AppColors.warning,
        LoyaltyTier.platinum => AppColors.primaryDeep,
      };

  Color get background => switch (this) {
        LoyaltyTier.none => AppColors.surfaceSecondary,
        LoyaltyTier.bronze => AppColors.warningLight,
        LoyaltyTier.silver => AppColors.surfaceHover,
        LoyaltyTier.gold => AppColors.warningLight,
        LoyaltyTier.platinum => AppColors.surfaceSecondary,
      };
}
