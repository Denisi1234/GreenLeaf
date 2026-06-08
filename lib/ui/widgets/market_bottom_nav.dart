import 'package:flutter/material.dart';

import 'app_design.dart';

enum MarketTab {
  dashboard,
  products,
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
    const items = [
      _NavItem(MarketTab.dashboard, 'Home', Icons.home_rounded),
      _NavItem(MarketTab.products, 'Inventory', Icons.inventory_2_outlined),
      _NavItem(MarketTab.reports, 'Reports', Icons.bar_chart_rounded),
      _NavItem(MarketTab.more, 'More', Icons.menu_rounded),
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
