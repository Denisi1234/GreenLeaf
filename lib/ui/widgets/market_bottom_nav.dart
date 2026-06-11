import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_design.dart';
import '../../service/pos_local_store.dart';
import '../../l10n/app_strings.dart';

enum MarketTab {
  dashboard,
  products,
  sales,
  reports,
  more,
}

class MarketBottomNav extends StatelessWidget {
  const MarketBottomNav({
    super.key,
    required this.currentTab,
    required this.onChanged,
  });

  final MarketTab currentTab;
  final ValueChanged<MarketTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.watch<PosLocalStore>().languageCode);
    final items = [
      _NavItem(MarketTab.dashboard, strings.home, Icons.home_rounded),
      _NavItem(
          MarketTab.products, strings.inventory, Icons.inventory_2_rounded),
      _NavItem(MarketTab.sales, strings.sales, Icons.point_of_sale_rounded),
      _NavItem(MarketTab.reports, strings.reports, Icons.assessment_outlined),
      _NavItem(MarketTab.more, strings.more, Icons.menu_rounded),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.map((item) {
            final selected = item.tab == currentTab;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(item.tab),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color:
                            selected ? AppColors.primary : AppColors.textLight,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTypography.helperText.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textLight,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.tab, this.label, this.icon);

  final MarketTab tab;
  final String label;
  final IconData icon;
}
