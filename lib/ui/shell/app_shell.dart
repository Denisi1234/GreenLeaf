import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../more/more_page.dart';
import '../products/product_management_page.dart';
import '../reports/reports_page.dart';
import '../widgets/market_bottom_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  static const _transitionDuration = Duration(milliseconds: 300);

  MarketTab _currentTab = MarketTab.products;
  MarketTab? _previousTab;
  bool _moveForward = true;
  late final AnimationController _transitionController;

  static const _pages = [
    ReportsPage(),
    ProductManagementPage(),
    MarketHomePage(),
    MorePage(),
  ];

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
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
                      enabled: isCurrent || isPrevious || _previousTab == null,
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
      bottomNavigationBar: MarketBottomNav(
        currentTab: _currentTab,
        onChanged: _handleTabChange,
      ),
    );
  }
}
