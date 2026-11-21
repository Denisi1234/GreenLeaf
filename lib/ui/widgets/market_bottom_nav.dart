import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import 'app_design.dart';

enum MarketTab {
  dashboard,
  products,
  sales,
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
      _NavItem(
        MarketTab.dashboard,
        strings.dashboard.toUpperCase(),
        Icons.bar_chart_outlined,
        Icons.bar_chart_rounded,
      ),
      _NavItem(
        MarketTab.products,
        strings.inventory.toUpperCase(),
        Icons.inventory_2_outlined,
        Icons.inventory_2_rounded,
      ),
      _NavItem(
        MarketTab.sales,
        strings.sales.toUpperCase(),
        Icons.point_of_sale_outlined,
        Icons.point_of_sale_rounded,
      ),
      _NavItem(
        MarketTab.more,
        strings.more.toUpperCase(),
        Icons.menu_rounded,
        Icons.menu_open_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: items.map((item) {
              final selected = item.tab == currentTab;
              return Expanded(
                child: _NavItemButton(
                  item: item,
                  selected: selected,
                  onTap: () => onChanged(item.tab),
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
    // In screenshot: active item has dark teal/forest green icon with dot indicator, inactive has grey icon and bold black label
    const primaryTabColor = Color(0xFF0F766E); // Dark teal green from reference
    const inactiveIconColor = Color(0xFF64748B);
    const labelColor = AppColors.textBody;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? item.activeIcon : item.icon,
            color: selected ? primaryTabColor : inactiveIconColor,
            size: 23,
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: selected ? primaryTabColor : labelColor,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.tab, this.label, this.icon, this.activeIcon);

  final MarketTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
