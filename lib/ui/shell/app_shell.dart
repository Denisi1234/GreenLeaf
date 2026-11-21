import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../home/sales_page.dart';
import '../more/more_page.dart';
import '../products/product_management_page.dart';
import '../reports/dashboard_page.dart';
import '../sales/order_history_page.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/market_bottom_nav.dart';
import '../more/settings_page.dart';
import '../notifications/notifications_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialTab = MarketTab.sales,
  });

  final MarketTab initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  static const _transitionDuration = Duration(milliseconds: 300);

  late MarketTab _currentTab;
  MarketTab? _previousTab;
  bool _moveForward = true;
  late final AnimationController _transitionController;

  static const _pages = [
    DashboardPage(useSharedShell: true),
    ProductManagementPage(useSharedShell: true),
    SalesPage(useSharedShell: true),
    MorePage(useSharedShell: true),
  ];

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _transitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      value: 1,
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _handleTabChange(MarketTab tab) {
    if (tab == _currentTab) return;

    final oldTab = _currentTab;
    setState(() {
      _previousTab = oldTab;
      _currentTab = tab;
      _moveForward = tab.index > oldTab.index;
    });

    _transitionController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _previousTab = null);
    });
  }

  String _headerTitleForTab(MarketTab tab, AppStrings strings) {
    switch (tab) {
      case MarketTab.dashboard:
        return strings.dashboard;
      case MarketTab.products:
        return strings.inventory;
      case MarketTab.sales:
        return strings.sales;
      case MarketTab.more:
        return strings.more;
    }
  }

  String _headerSubtitleForTab(MarketTab tab, AppStrings strings) {
    switch (tab) {
      case MarketTab.dashboard:
        return strings.dashboardSubtitle;
      case MarketTab.products:
        return strings.productsSubtitle;
      case MarketTab.sales:
        return strings.salesSubtitle;
      case MarketTab.more:
        return strings.moreSubtitle;
    }
  }

  String _drawerSelectedItemForTab(MarketTab tab, AppStrings strings) {
    return _headerTitleForTab(tab, strings);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final strings = AppStrings.of(store.languageCode);
    final canOpenSettings = store.hasPermission('System Settings');
    final hasActiveAlerts = store.inventory.any((p) => p.stockCount <= 5) ||
        store.customers.any((c) => c.debitBalance > 0);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useRail = screenWidth >= 900;
    final extendedRail = screenWidth >= 1200;

    final contentStack = AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        final progress = _transitionController.value;
        final incomingCurve = Curves.easeOutCubic.transform(progress);
        final outgoingCurve = Curves.easeOutQuad.transform(progress);

        return ClipRect(
          child: Stack(
            children: List.generate(_pages.length, (index) {
              final isCurrent = index == _currentTab.index;
              final isPrevious = index == _previousTab?.index;
              final shouldPaint =
                  isCurrent || (_previousTab != null && isPrevious);

              double opacity = isCurrent ? 1 : 0;
              double scale = 1;
              double dx = 0;

              if (_previousTab != null) {
                if (isCurrent) {
                  opacity = incomingCurve;
                  scale = 0.994 + (0.006 * incomingCurve);
                  dx = (_moveForward ? 0.048 : -0.048) *
                      (1 - incomingCurve) *
                      width;
                } else if (isPrevious) {
                  opacity = 1 - (outgoingCurve * 0.92);
                  scale = 1 - (0.012 * outgoingCurve);
                  dx = (_moveForward ? -0.022 : 0.022) *
                      outgoingCurve *
                      width;
                }
              }

              return Offstage(
                offstage: !shouldPaint,
                child: IgnorePointer(
                  ignoring: !isCurrent,
                  child: TickerMode(
                    enabled: shouldPaint,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(dx, 0),
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.center,
                          child: _pages[index],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );

    final mainColumn = Column(
      children: [
        MarketPageHeader(
          title: _headerTitleForTab(_currentTab, strings),
          subtitle: _headerSubtitleForTab(_currentTab, strings),
          showBackButton: false,
          leading: null,
          centerTitle: false,
          titleSize: 22,
          titleWeight: FontWeight.w800,
          showBorder: true,
          actions: const [],
        ),
        Expanded(child: contentStack),
      ],
    );

    return Scaffold(
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  extended: extendedRail,
                  backgroundColor: AppColors.surface,
                  selectedIndex: _currentTab.index,
                  onDestinationSelected: (idx) =>
                      _handleTabChange(MarketTab.values[idx]),
                  indicatorColor:
                      const Color(0xFF0F766E).withValues(alpha: 0.12),
                  selectedIconTheme:
                      const IconThemeData(color: Color(0xFF0F766E)),
                  selectedLabelTextStyle: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF0F766E),
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedIconTheme:
                      const IconThemeData(color: Color(0xFF64748B)),
                  unselectedLabelTextStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w600,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: config.primaryColor,
                      size: 28,
                    ),
                  ),
                  trailing: canOpenSettings
                      ? Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: IconButton(
                                tooltip: strings.settings,
                                icon: const Icon(Icons.settings_outlined),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SettingsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      : null,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.point_of_sale_outlined),
                      selectedIcon: const Icon(Icons.point_of_sale_rounded),
                      label: Text(strings.sales),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long_rounded),
                      label: Text(strings.orders),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.inventory_2_outlined),
                      selectedIcon: const Icon(Icons.inventory_2_rounded),
                      label: Text(strings.inventory),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.bar_chart_outlined),
                      selectedIcon: const Icon(Icons.bar_chart_rounded),
                      label: Text(strings.dashboard),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      selectedIcon: const Icon(Icons.grid_view_rounded),
                      label: Text(strings.more),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.divider),
                Expanded(child: mainColumn),
              ],
            )
          : mainColumn,
      bottomNavigationBar: useRail
          ? null
          : MarketBottomNav(
              currentTab: _currentTab,
              onChanged: _handleTabChange,
            ),
    );
  }
}
