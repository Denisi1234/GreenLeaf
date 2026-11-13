import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import 'app_design.dart';

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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: items.map((item) {
              final selected = item.tab == currentTab;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _NavItemButton(
                    item: item,
                    selected: selected,
                    onTap: () => onChanged(item.tab),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  const _NavItemButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : AppColors.textMuted;
    final labelColor = selected ? Colors.white : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: iconColor,
                size: selected ? 23 : 22,
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                style: AppTypography.helperText.copyWith(
                  color: labelColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: selected ? 11.5 : 11,
                  height: 1.1,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
