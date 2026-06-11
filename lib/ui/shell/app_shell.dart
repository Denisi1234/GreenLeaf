import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../business_category_config.dart';
import '../home/sales_page.dart';
import '../more/more_page.dart';
import '../products/add_product_page.dart';
import '../products/product_management_page.dart';
import '../reports/dashboard_page.dart';
import '../reports/report_hub_page.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/market_bottom_nav.dart';
import '../more/duka_ai_page.dart';
import '../notifications/notifications_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialTab = MarketTab.products,
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
    ReportHubPage(),
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

  String _drawerSelectedItemForTab(MarketTab tab, AppStrings strings) {
    switch (tab) {
      case MarketTab.dashboard:
        return strings.home;
      case MarketTab.products:
        return strings.inventory;
      case MarketTab.sales:
        return strings.sales;
      case MarketTab.reports:
        return strings.reports;
      case MarketTab.more:
        return strings.more;
    }
  }

  String _headerTitleForTab(MarketTab tab, AppStrings strings) {
    switch (tab) {
      case MarketTab.dashboard:
        return strings.dashboard;
      case MarketTab.products:
        return strings.products;
      case MarketTab.sales:
        return strings.sales;
      case MarketTab.reports:
        return strings.reports;
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
      case MarketTab.reports:
        return strings.reportsSubtitle;
      case MarketTab.more:
        return strings.moreSubtitle;
    }
  }

  String _primaryActionLabel(
    MarketTab tab,
    BusinessCategory category,
    AppStrings strings,
  ) {
    final isAddFlow = tab == MarketTab.products || tab == MarketTab.sales;
    return switch (category) {
      BusinessCategory.pharmacy => isAddFlow ? 'Ongeza Dawa' : 'Mauzo Mapya',
      BusinessCategory.electronics => isAddFlow ? 'Ongeza Kifaa' : strings.sales,
      BusinessCategory.retail => isAddFlow ? 'Ongeza Bidhaa' : strings.sales,
    };
  }

  IconData _primaryActionIcon(
    MarketTab tab,
    BusinessCategory category,
  ) {
    final isAddFlow = tab == MarketTab.products || tab == MarketTab.sales;
    if (isAddFlow) {
      return switch (category) {
        BusinessCategory.pharmacy => Icons.medication_rounded,
        BusinessCategory.electronics => Icons.devices_other_rounded,
        BusinessCategory.retail => Icons.inventory_2_outlined,
      };
    }

    return switch (category) {
      BusinessCategory.pharmacy => Icons.receipt_long_outlined,
      BusinessCategory.electronics => Icons.shopping_bag_outlined,
      BusinessCategory.retail => Icons.point_of_sale_outlined,
    };
  }

  Future<void> _openPrimaryAction(
    BuildContext context,
    MarketTab tab,
    PosLocalStore store,
  ) async {
    final isAddFlow = tab == MarketTab.products || tab == MarketTab.sales;
    final shouldOpenProductForm = isAddFlow;

    if (shouldOpenProductForm) {
      final nextCode =
          'P${(store.inventory.length + 1).toString().padLeft(3, '0')}';
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => AddProductPage(nextCode: nextCode),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const SalesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final strings = AppStrings.of(store.languageCode);
    return Scaffold(
      drawer: MarketAppDrawer(
        selectedItem: _drawerSelectedItemForTab(_currentTab, strings),
      ),
      body: Column(
        children: [
          MarketPageHeader(
            title: _headerTitleForTab(_currentTab, strings),
            subtitle: _headerSubtitleForTab(_currentTab, strings),
            showBackButton: false,
            leading: const DrawerMenuButton(),
            centerTitle: false,
            titleSize: 22,
            titleWeight: FontWeight.w800,
            showBorder: true,
            actions: [
              MarketHeaderActionButtons(
                aiBackground: config.primaryLightColor,
                aiForeground: config.primaryColor,
                aiBorderColor: config.primaryColor.withValues(alpha: 0.12),
                notificationBackground: config.primaryLightColor,
                notificationForeground: config.primaryColor,
                notificationBorderColor:
                    config.primaryColor.withValues(alpha: 0.12),
                showNotificationDot: true,
                onDukaAiTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const DukaAiAdvisorPage(),
                    ),
                  );
                },
                onNotificationTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
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
                          isCurrent || isPrevious || _previousTab == null;

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
                            enabled:
                                isCurrent || isPrevious || _previousTab == null,
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
            ),
          ),
        ],
      ),
      floatingActionButton: (_currentTab == MarketTab.dashboard ||
              _currentTab == MarketTab.sales ||
              _currentTab == MarketTab.more)
          ? null
          : FloatingActionButton.extended(
              heroTag: 'app_shell_primary_action_fab',
              onPressed: () => _openPrimaryAction(context, _currentTab, store),
              backgroundColor: config.primaryColor,
              foregroundColor: Colors.white,
              icon: Icon(_primaryActionIcon(_currentTab, config.category)),
              label: Text(_primaryActionLabel(_currentTab, config.category, strings)),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: MarketBottomNav(
        currentTab: _currentTab,
        onChanged: _handleTabChange,
      ),
    );
  }
}
