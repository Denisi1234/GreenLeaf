import 'package:flutter/material.dart';

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
      _NavItem(MarketTab.dashboard, 'Dashboard', Icons.grid_view_rounded),
      _NavItem(MarketTab.products, 'Products', Icons.shopping_bag_outlined),
      _NavItem(MarketTab.reports, 'Reports', Icons.bar_chart_rounded),
      _NavItem(MarketTab.more, 'More', Icons.more_horiz_rounded),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFD),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.map((item) {
            final selected = item.tab == currentTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item.tab),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        height: 2.5,
                        width: selected ? 44 : 0,
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B6FF3),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Icon(
                        item.icon,
                        color: selected
                            ? const Color(0xFF2B6FF3)
                            : const Color(0xFF7A8393),
                        size: 23,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF2B6FF3)
                              : const Color(0xFF7A8393),
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
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
