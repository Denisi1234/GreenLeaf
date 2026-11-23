import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/app_update_service.dart';
import '../../service/pos_local_store.dart';
import '../home/sales_page.dart';
import '../more/more_page.dart';
import '../products/product_management_page.dart';
import '../reports/dashboard_page.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/market_bottom_nav.dart';
import '../more/settings_page.dart';
import '../more/theme_selection_page.dart';

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
  static const _transitionDuration = Duration(milliseconds: 180);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late MarketTab _currentTab;
  MarketTab? _previousTab;
  bool _moveForward = true;
  late final AnimationController _transitionController;

  late final List<Widget> _pages = [
    const DashboardPage(useSharedShell: true),
    const ProductManagementPage(useSharedShell: true),
    SalesPage(
      useSharedShell: true,
      onOpenInventory: () => _handleTabChange(MarketTab.products),
    ),
    const MorePage(useSharedShell: true),
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

    if (MediaQuery.disableAnimationsOf(context)) {
      _transitionController.stop();
      setState(() {
        _currentTab = tab;
        _previousTab = null;
      });
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final strings = AppStrings.of(store.languageCode);
    final canOpenSettings = store.hasPermission('System Settings');
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
                  dx = (_moveForward ? 0.012 : -0.012) *
                      (1 - incomingCurve) *
                      width;
                } else if (isPrevious) {
                  opacity = 1 - (outgoingCurve * 0.92);
                  scale = 1 - (0.012 * outgoingCurve);
                  dx = (_moveForward ? -0.006 : 0.006) * outgoingCurve * width;
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

    final palette = AppThemePalette.of(context);
    final mainColumn = Column(
      children: [
        MarketPageHeader(
          title: _headerTitleForTab(_currentTab, strings),
          showBackButton: false,
          leading: useRail
              ? null
              : Tooltip(
                  message: MaterialLocalizations.of(context)
                      .openAppDrawerTooltip,
                  child: HeaderActionButton(
                    icon: Icons.menu_rounded,
                    background: palette.surface,
                    foreground: palette.ink,
                    borderColor: palette.border,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
          centerTitle: false,
          titleSize: 20,
          titleWeight: FontWeight.w800,
          showBorder: true,
          actions: [
            Tooltip(
              message: store.languageCode == 'sw' ? 'Mandhari' : 'Theme',
              child: HeaderActionButton(
                icon: Icons.palette_outlined,
                background: palette.surface,
                foreground: palette.ink,
                borderColor: palette.border,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ThemeSelectionPage(),
                    ),
                  );
                },
              ),
            ),
            if (canOpenSettings) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: strings.settings,
                child: HeaderActionButton(
                  icon: Icons.settings_outlined,
                  background: palette.surface,
                  foreground: palette.ink,
                  borderColor: palette.border,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        ValueListenableBuilder<bool>(
          valueListenable: AppUpdateService.instance.updateDownloaded,
          builder: (context, ready, _) {
            if (!ready) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: palette.primaryLight,
                border: Border(bottom: BorderSide(color: palette.divider)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.system_update_rounded,
                    size: 18,
                    color: palette.primaryDeep,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.isSwahili
                          ? 'Sasisho jipya liko tayari'
                          : 'New update ready',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: AppUpdateService.instance.completeUpdate,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      strings.isSwahili ? 'Weka sasa' : 'Restart',
                      style: AppTypography.bodySmall.copyWith(
                        color: palette.primaryDeep,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(child: contentStack),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.pageBackground,
      drawer: useRail
          ? null
          : MarketAppDrawer(
              selectedTab: _currentTab,
              onSelectTab: _handleTabChange,
            ),
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  extended: extendedRail,
                  backgroundColor: palette.headerSurface,
                  selectedIndex: _currentTab.index,
                  onDestinationSelected: (idx) =>
                      _handleTabChange(MarketTab.values[idx]),
                  indicatorColor: palette.primary.withValues(alpha: 0.14),
                  selectedIconTheme: IconThemeData(color: palette.primaryDeep),
                  selectedLabelTextStyle: AppTypography.bodySmall.copyWith(
                    color: palette.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedIconTheme: IconThemeData(color: palette.textMuted),
                  unselectedLabelTextStyle: AppTypography.bodySmall.copyWith(
                    color: palette.textBody,
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
                      icon: const Icon(Icons.bar_chart_outlined),
                      selectedIcon: const Icon(Icons.bar_chart_rounded),
                      label: Text(strings.dashboard),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.inventory_2_outlined),
                      selectedIcon: const Icon(Icons.inventory_2_rounded),
                      label: Text(strings.inventory),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.point_of_sale_outlined),
                      selectedIcon: const Icon(Icons.point_of_sale_rounded),
                      label: Text(strings.sales),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      selectedIcon: const Icon(Icons.grid_view_rounded),
                      label: Text(strings.more),
                    ),
                  ],
                ),
                VerticalDivider(width: 1, color: AppColors.divider),
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
