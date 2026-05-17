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

class _AppShellState extends State<AppShell> {
  MarketTab _currentTab = MarketTab.products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: const [
          MarketDashboardView(),
          ProductManagementPage(),
          ReportsPage(),
          MorePage(),
        ],
      ),
      bottomNavigationBar: MarketBottomNav(
        currentTab: _currentTab,
        onChanged: (tab) => setState(() => _currentTab = tab),
      ),
    );
  }
}
