import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import 'app_design.dart';
import 'app_theme_palette.dart';

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
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final cartLineCount = store.cartItems.length;

    final items = [
      _NavItem(
        tab: MarketTab.dashboard,
        label: strings.dashboard,
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
      ),
      _NavItem(
        tab: MarketTab.products,
        label: strings.inventory,
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
      ),
      _NavItem(
        tab: MarketTab.sales,
        label: strings.sales,
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale_rounded,
        badgeCount: cartLineCount,
      ),
      _NavItem(
        tab: MarketTab.more,
        label: strings.more,
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
    ];

    final palette = AppThemePalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.headerSurface,
        border: Border(
          top: BorderSide(color: palette.border, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: Row(
            children: items.map((item) {
              final selected = item.tab == currentTab;
              return Expanded(
                child: _NavItemButton(
                  item: item,
                  selected: selected,
                  onTap: () {
                    if (!selected) {
                      HapticFeedback.selectionClick();
                    }
                    onChanged(item.tab);
                  },
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
    final palette = AppThemePalette.of(context);
    final iconColor = selected ? palette.primaryDeep : palette.textMuted;
    final labelColor = selected ? palette.primaryDeep : palette.textBody;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 26,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          color: iconColor,
                          size: 24,
                        ),
                        if (item.badgeCount > 0)
                          Positioned(
                            top: -5,
                            right: -10,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.badgeCount > 99
                                    ? '99+'
                                    : '${item.badgeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: labelColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 11.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeCount = 0,
  });

  final MarketTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badgeCount;
}
