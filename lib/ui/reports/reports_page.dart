import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../more/duka_ai_page.dart';
import '../more/expenses_tracking_page.dart';
import '../shell/app_shell.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../widgets/app_design.dart';
import '../widgets/market_bottom_nav.dart';
import '../widgets/market_shared_widgets.dart';
import 'report_hub_page.dart';
import 'reports_catalog_page.dart';

// ignore_for_file: unused_element, unused_field

const Duration _eastAfricaOffset = Duration(hours: 3);

DateTime _eastAfricaNow() => DateTime.now().toUtc().add(_eastAfricaOffset);

enum _ReportPeriod { today, week, month, all }

extension _ReportPeriodLabel on _ReportPeriod {
  String get label {
    switch (this) {
      case _ReportPeriod.today:
        return 'Today';
      case _ReportPeriod.week:
        return 'This Week';
      case _ReportPeriod.month:
        return 'This Month';
      case _ReportPeriod.all:
        return 'All Time';
    }
  }

  String get shortLabel {
    switch (this) {
      case _ReportPeriod.today:
        return 'Today';
      case _ReportPeriod.week:
        return 'Week';
      case _ReportPeriod.month:
        return 'Month';
      case _ReportPeriod.all:
        return 'All';
    }
  }
}

DateTime _periodStart(_ReportPeriod period) {
  final now = _eastAfricaNow();
  switch (period) {
    case _ReportPeriod.today:
      return DateTime(now.year, now.month, now.day);
    case _ReportPeriod.week:
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return DateTime(weekStart.year, weekStart.month, weekStart.day);
    case _ReportPeriod.month:
      return DateTime(now.year, now.month, 1);
    case _ReportPeriod.all:
      return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

bool _orderInPeriod(String dateTime, _ReportPeriod period) {
  final parsed = DateTime.tryParse(dateTime);
  if (parsed == null) return false;
  return !parsed.isBefore(_periodStart(period));
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    this.useSharedShell = false,
  });

  final bool useSharedShell;

  static const Color _ink = Color(0xFF33363F);
  static const Color _muted = Color(0xFF7A859C);
  static const Color _border = Color(0xFFE8EBF1);
  static const Color _blue = Color(0xFF2B6FE8);
  static const Color _green = Color(0xFF30B05C);

  static const List<_QuickActionData> _quickActions = [
    _QuickActionData(
      icon: Icons.shopping_bag_outlined,
      label: 'Start Sale',
      iconColor: _blue,
      background: null,
      foreground: null,
      iconBackground: Color(0xFFEAF0FF),
    ),
    _QuickActionData(
      icon: Icons.point_of_sale_outlined,
      label: 'Open Drawer',
      iconColor: Color(0xFF2AA24F),
      iconBackground: Color(0xFFE9F8ED),
    ),
    _QuickActionData(
      icon: Icons.insert_chart_outlined_rounded,
      label: 'View Reports',
      iconColor: _blue,
      iconBackground: Color(0xFFECF2FF),
    ),
  ];

  static List<_OverviewCardData> _buildOverviewCards(PosLocalStore store) {
    final today = _eastAfricaNow();
    final todayOrders = store.orders.where((order) {
      final orderDate = DateTime.tryParse(order.dateTime);
      return orderDate != null &&
          orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day;
    }).toList();
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayOrders = store.orders.where((order) {
      final orderDate = DateTime.tryParse(order.dateTime);
      return orderDate != null &&
          orderDate.year == yesterday.year &&
          orderDate.month == yesterday.month &&
          orderDate.day == yesterday.day;
    }).toList();

    final totalSales = todayOrders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final yesterdaySales = yesterdayOrders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final transactionCount = todayOrders.length;
    final averageValue =
        transactionCount == 0 ? 0 : totalSales / transactionCount;
    final salesChangePercent = yesterdaySales <= 0
        ? null
        : ((totalSales - yesterdaySales) / yesterdaySales) * 100;
    final salesWentUp =
        salesChangePercent == null ? null : salesChangePercent >= 0;

    final productTotals = <String, int>{};
    for (final order in todayOrders) {
      for (final line in order.lines) {
        productTotals[line.itemName] =
            (productTotals[line.itemName] ?? 0) + line.quantity;
      }
    }

    final topProductEntry = productTotals.entries.isEmpty
        ? null
        : productTotals.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
          );

    return [
      _OverviewCardData(
        icon: Icons.shopping_bag_outlined,
        iconColor: const Color(0xFF26A042),
        iconBackground: const Color(0xFFEAF8EE),
        title: 'Sales today',
        value: 'TSH ${totalSales.toStringAsFixed(0)}',
        delta: salesChangePercent == null
            ? null
            : '${salesChangePercent.abs().toStringAsFixed(0)}% vs yesterday',
        deltaIsPositive: salesWentUp,
        footer: 'Updated today',
      ),
      _OverviewCardData(
        icon: Icons.shopping_cart_outlined,
        iconColor: const Color(0xFF2E6EE8),
        iconBackground: const Color(0xFFECF3FF),
        title: 'Orders today',
        value: transactionCount.toString(),
        footer: 'Updated today',
      ),
      _OverviewCardData(
        icon: Icons.sell_outlined,
        iconColor: const Color(0xFF9747FF),
        iconBackground: const Color(0xFFF3EAFE),
        title: 'Average order',
        value: 'TSH ${averageValue.toStringAsFixed(0)}',
        footer: 'Updated today',
      ),
      _OverviewCardData(
        icon: Icons.inventory_2_outlined,
        iconColor: const Color(0xFFC38A13),
        iconBackground: const Color(0xFFFEF5E3),
        title: 'Best seller',
        value: topProductEntry?.key ?? 'No sales yet',
        footer: topProductEntry == null
            ? 'No items sold yet'
            : '${topProductEntry.value} sold today',
        highlightValue: true,
      ),
    ];
  }

  static List<_ActivityItemData> _buildActivityItems(
    List<CompletedOrder> orders,
  ) {
    return orders.take(5).map((order) {
      final itemCount = order.lines.fold<int>(
        0,
        (sum, line) => sum + line.quantity,
      );
      final paymentMethod = order.paymentMethod.toLowerCase();
      return _ActivityItemData(
        icon: paymentMethod == 'cash'
            ? Icons.payments_outlined
            : Icons.shopping_cart_outlined,
        iconColor: paymentMethod == 'cash'
            ? const Color(0xFF2E6EE8)
            : const Color(0xFF2AA24F),
        iconBackground: paymentMethod == 'cash'
            ? const Color(0xFFECF3FF)
            : const Color(0xFFEAF8EE),
        title: 'Order ${order.id}',
        subtitle:
            '$itemCount item${itemCount == 1 ? '' : 's'} - $paymentMethod payment',
        amount: 'TSH ${order.total.toStringAsFixed(0)}',
        time: order.time,
      );
    }).toList();
  }

  static String _formatToday() {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdayNames = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final now = _eastAfricaNow();
    return '${monthNames[now.month - 1]} ${now.day}, ${now.year} (${weekdayNames[now.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final summary = _buildDashboardSummary(store);
    final todayLabel = _formatToday();
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        drawer: useSharedShell
            ? null
            : const MarketAppDrawer(selectedItem: 'Dashboard'),
        body: SafeArea(
          top: !useSharedShell,
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFFF1F5F9)),
              ),
              Column(
                children: [
                  if (!useSharedShell)
                    _PremiumReportsHeader(
                      dateLabel: todayLabel,
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryPanel(summary: summary, orders: store.orders),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Transform.translate(
                  offset: const Offset(0, -8),
                  child: _NewSaleFloatingButton(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (context) => const AppShell(
                            initialTab: MarketTab.reports,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSummaryData {
  const _DashboardSummaryData({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.monthlySales,
    required this.activeClients,
    required this.todayOrdersCount,
    required this.yesterdaySales,
    required this.todayExpenses,
    required this.conversionRate,
    required this.deltaText,
    required this.deltaIsPositive,
    required this.bestSeller,
    required this.bestSellerCount,
    required this.recentRevenueValues,
    required this.recentRevenueLabel,
  });

  final double totalRevenue;
  final double todayRevenue;
  final int monthlySales;
  final int activeClients;
  final int todayOrdersCount;
  final double yesterdaySales;
  final double todayExpenses;
  final double conversionRate;
  final String? deltaText;
  final bool? deltaIsPositive;
  final String bestSeller;
  final int? bestSellerCount;
  final List<double> recentRevenueValues;
  final String recentRevenueLabel;

  double get revenue => totalRevenue;
  double get today => todayRevenue;
  int get orders => monthlySales;
  double get averageOrder =>
      monthlySales == 0 ? 0.0 : totalRevenue / monthlySales;
}

_DashboardSummaryData _buildDashboardSummary(PosLocalStore store) {
  final now = _eastAfricaNow();
  final todayStart = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);
  final orders = store.orders;
  final todayOrders = orders.where((order) {
    final parsed = DateTime.tryParse(order.dateTime);
    return parsed != null &&
        parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }).toList();
  final yesterday = now.subtract(const Duration(days: 1));
  final yesterdayOrders = orders.where((order) {
    final parsed = DateTime.tryParse(order.dateTime);
    return parsed != null &&
        parsed.year == yesterday.year &&
        parsed.month == yesterday.month &&
        parsed.day == yesterday.day;
  }).toList();

  final monthOrders = orders.where((order) {
    final parsed = DateTime.tryParse(order.dateTime);
    return parsed != null &&
        !parsed.isBefore(monthStart) &&
        !parsed.isAfter(now);
  }).toList();
  final monthRevenue =
      monthOrders.fold<double>(0, (sum, order) => sum + order.total);
  final todayRevenue =
      todayOrders.fold<double>(0, (sum, order) => sum + order.total);
  final yesterdayRevenue =
      yesterdayOrders.fold<double>(0, (sum, order) => sum + order.total);
  final totalRevenue = monthRevenue;
  final monthlySales = monthOrders.length;
  final activeClients = monthOrders
      .map((order) => order.customerName?.trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .length;
  final todayExpenses = store.expenses.where((expense) {
    final parsed = expense.date;
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }).fold<double>(0, (sum, expense) => sum + expense.amount);
  final conversionRate =
      orders.isEmpty ? 0.0 : (monthOrders.length / orders.length) * 100;
  final deltaText = yesterdayRevenue <= 0
      ? null
      : '${(((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100).abs().toStringAsFixed(1)}%';
  final deltaIsPositive =
      yesterdayRevenue <= 0 ? null : todayRevenue >= yesterdayRevenue;

  final soldCounts = <String, int>{};
  for (final order in todayOrders) {
    for (final line in order.lines) {
      soldCounts[line.itemName] =
          (soldCounts[line.itemName] ?? 0) + line.quantity;
    }
  }
  final bestSellerEntry = soldCounts.entries.isEmpty
      ? null
      : soldCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);

  final revenueTrendValues = List<double>.generate(7, (index) {
    final day = todayStart.subtract(Duration(days: 6 - index));
    final dayRevenue = orders.where((order) {
      final parsed = DateTime.tryParse(order.dateTime);
      return parsed != null &&
          parsed.year == day.year &&
          parsed.month == day.month &&
          parsed.day == day.day;
    }).fold<double>(0, (sum, order) => sum + order.total);
    return dayRevenue;
  });

  return _DashboardSummaryData(
    totalRevenue: totalRevenue,
    todayRevenue: todayRevenue,
    monthlySales: monthlySales,
    activeClients: activeClients,
    todayOrdersCount: todayOrders.length,
    yesterdaySales: yesterdayRevenue,
    todayExpenses: todayExpenses,
    conversionRate: conversionRate,
    deltaText: deltaText,
    deltaIsPositive: deltaIsPositive,
    bestSeller: bestSellerEntry?.key ?? 'No sales yet',
    bestSellerCount: bestSellerEntry?.value,
    recentRevenueValues: revenueTrendValues,
    recentRevenueLabel: 'Last 7 days',
  );
}

class _PremiumReportsHeader extends StatelessWidget {
  const _PremiumReportsHeader({
    required this.dateLabel,
  });

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return MarketPageHeader(
      title: 'Dashboard',
      showBackButton: false,
      centerTitle: false,
      titleSize: 22,
      titleWeight: FontWeight.w700,
      leading: const _ReportsBrandIcon(),
      actions: [
        MarketHeaderActionButtons(
          aiForeground: ReportsPage._ink,
          notificationForeground: ReportsPage._ink,
          onDukaAiTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const DukaAiAdvisorPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ReportsBrandIcon extends StatelessWidget {
  const _ReportsBrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF5B8CFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.north_east_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class _NewSaleFloatingButton extends StatelessWidget {
  const _NewSaleFloatingButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFD94B4B),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'New Sale',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_month_outlined,
          size: 16,
          color: Color(0xFF8A93A7),
        ),
        const SizedBox(width: 6),
        Text(
          dateLabel,
          style: const TextStyle(
            color: Color(0xFF7B859A),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: ReportsPage._ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.cards});

  final List<_OverviewCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth > 560 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(
                    width: itemWidth,
                    child: _OverviewCard(card: card),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.card});

  final _OverviewCardData card;

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _OverviewDetailPage(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _openDetails(context),
          child: MarketSurfaceCard(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            borderColor: ReportsPage._border,
            radius: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: card.iconBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(card.icon, color: card.iconColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.title,
                        style: const TextStyle(
                          color: ReportsPage._muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.value,
                  maxLines: card.highlightValue ? 2 : 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: ReportsPage._ink,
                    fontSize: card.highlightValue ? 13 : 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                if (card.delta != null) ...[
                  Row(
                    children: [
                      Icon(
                        card.deltaIsPositive == false
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: card.deltaIsPositive == false
                            ? const Color(0xFFC65B4A)
                            : ReportsPage._green,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        card.delta!,
                        style: TextStyle(
                          color: card.deltaIsPositive == false
                              ? const Color(0xFFC65B4A)
                              : ReportsPage._green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          card.footer,
                          style: const TextStyle(
                            color: ReportsPage._muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    card.footer,
                    style: const TextStyle(
                      color: ReportsPage._muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final isCompact = constraints.maxWidth < 360;
        final itemWidth = isCompact
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (actions.length - 1))) /
                actions.length;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => SizedBox(
                  width: itemWidth,
                  child: _QuickActionCard(action: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, this.hero = false});

  final _QuickActionData action;
  final bool hero;

  void _handleTap(BuildContext context) {
    switch (action.label) {
      case 'Start Sale':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const AppShell(
              initialTab: MarketTab.reports,
            ),
          ),
        );
        break;
      case 'Open Drawer':
        showMarketNotice(
          context,
          title: 'Cash Drawer',
          message: 'Cash drawer opened successfully.',
        );
        break;
      case 'View Reports':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const ReportsCatalogPage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconBackground = action.iconBackground ?? Colors.white;
    final labelColor = action.foreground ?? ReportsPage._ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(hero ? 20 : 12),
        onTap: () => _handleTap(context),
        child: Container(
          constraints: BoxConstraints(minHeight: hero ? 118 : 108),
          padding: EdgeInsets.symmetric(
            horizontal: hero ? 14 : 10,
            vertical: hero ? 14 : 12,
          ),
          decoration: BoxDecoration(
            gradient: action.background,
            color: action.background == null ? Colors.white : null,
            borderRadius: BorderRadius.circular(hero ? 20 : 12),
            border: action.background == null
                ? Border.all(color: ReportsPage._border)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: hero ? 42 : 40,
                height: hero ? 42 : 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(hero ? 10 : 8),
                ),
                child: Icon(action.icon,
                    color: action.iconColor, size: hero ? 22 : 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hero ? 'Run Checkout' : action.label,
                    style: TextStyle(
                      color: hero ? const Color(0xFFBFD4FF) : labelColor,
                      fontSize: hero ? 10 : 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: hero ? 0.2 : -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.label,
                    style: TextStyle(
                      color: action.foreground ?? ReportsPage._ink,
                      fontSize: hero ? 15 : 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumQuickActionsRow extends StatelessWidget {
  const _PremiumQuickActionsRow({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columnWidth = (constraints.maxWidth - (gap * 3)) / 4;
        final heroWidth = (columnWidth * 2) + gap;

        return Row(
          children: [
            SizedBox(
              width: heroWidth,
              child: _QuickActionCard(
                action: actions[0],
                hero: true,
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(action: actions[1]),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _QuickActionCard(action: actions[2]),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.summary,
    required this.orders,
  });

  final _DashboardSummaryData summary;
  final List<CompletedOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OverviewStatsGrid(summary: summary),
        const SizedBox(height: 12),
        const _InsightsPromoCard(),
        const SizedBox(height: 12),
        _LiveGrowthOverviewCard(summary: summary, orders: orders),
      ],
    );
  }
}

enum _LiveGrowthPeriod { today, week, month, all }

extension _LiveGrowthPeriodLabel on _LiveGrowthPeriod {
  String get label {
    switch (this) {
      case _LiveGrowthPeriod.today:
        return 'Today';
      case _LiveGrowthPeriod.week:
        return 'This Week';
      case _LiveGrowthPeriod.month:
        return 'This Month';
      case _LiveGrowthPeriod.all:
        return 'All Time';
    }
  }
}

class _LiveGrowthOverviewCard extends StatefulWidget {
  const _LiveGrowthOverviewCard({
    required this.summary,
    required this.orders,
  });

  final _DashboardSummaryData summary;
  final List<CompletedOrder> orders;

  @override
  State<_LiveGrowthOverviewCard> createState() =>
      _LiveGrowthOverviewCardState();
}

class _LiveGrowthOverviewCardState extends State<_LiveGrowthOverviewCard> {
  _LiveGrowthPeriod _selectedPeriod = _LiveGrowthPeriod.week;

  DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _startOfWeek(DateTime value) {
    final start = value.subtract(Duration(days: value.weekday - 1));
    return _startOfDay(start);
  }

  DateTime _startOfMonth(DateTime value) =>
      DateTime(value.year, value.month, 1);

  DateTime _periodStart(_LiveGrowthPeriod period, DateTime now) {
    switch (period) {
      case _LiveGrowthPeriod.today:
        return _startOfDay(now);
      case _LiveGrowthPeriod.week:
        return _startOfWeek(now);
      case _LiveGrowthPeriod.month:
        return _startOfMonth(now);
      case _LiveGrowthPeriod.all:
        final orderDates = widget.orders
            .map((order) => DateTime.tryParse(order.dateTime))
            .whereType<DateTime>()
            .toList()
          ..sort();
        return orderDates.isEmpty ? _startOfDay(now) : orderDates.first;
    }
  }

  List<CompletedOrder> _ordersInRange(DateTime start, DateTime end) {
    return widget.orders.where((order) {
      final parsed = DateTime.tryParse(order.dateTime);
      return parsed != null && !parsed.isBefore(start) && !parsed.isAfter(end);
    }).toList();
  }

  List<double> _buildSeries(
    List<CompletedOrder> orders,
    DateTime start,
    DateTime end,
  ) {
    final spanSeconds = end.difference(start).inSeconds;
    final safeSpan = spanSeconds <= 0 ? 1 : spanSeconds;
    final buckets = List<double>.filled(7, 0);
    for (final order in orders) {
      final parsed = DateTime.tryParse(order.dateTime);
      if (parsed == null) continue;
      final offset = parsed.difference(start).inSeconds.clamp(0, safeSpan);
      final index = ((offset / safeSpan) * 6).floor().clamp(0, 6);
      buckets[index] += order.total;
    }
    return buckets;
  }

  List<String> _buildLabels(
    DateTime start,
    DateTime end,
    _LiveGrowthPeriod period,
  ) {
    final spanSeconds = end.difference(start).inSeconds;
    final safeSpan = spanSeconds <= 0 ? 1 : spanSeconds;
    const weekdayNames = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return List<String>.generate(7, (index) {
      final point =
          start.add(Duration(seconds: ((safeSpan / 6) * index).round()));
      switch (period) {
        case _LiveGrowthPeriod.today:
          final hour = point.hour % 12 == 0 ? 12 : point.hour % 12;
          final amPm = point.hour >= 12 ? 'PM' : 'AM';
          return '$hour$amPm';
        case _LiveGrowthPeriod.week:
          return weekdayNames[point.weekday - 1];
        case _LiveGrowthPeriod.month:
        case _LiveGrowthPeriod.all:
          return '${point.month}/${point.day}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = _eastAfricaNow();
    final start = _periodStart(_selectedPeriod, now);
    final end = now;
    final selectedOrders = _ordersInRange(start, end);
    final previousStart = start.subtract(end.difference(start));
    final previousOrders = _ordersInRange(previousStart, start);
    final currentRevenue =
        selectedOrders.fold<double>(0, (sum, order) => sum + order.total);
    final previousRevenue =
        previousOrders.fold<double>(0, (sum, order) => sum + order.total);
    final delta = previousRevenue <= 0
        ? null
        : ((currentRevenue - previousRevenue) / previousRevenue) * 100;
    final series = _buildSeries(selectedOrders, start, end);
    final labels = _buildLabels(start, end, _selectedPeriod);
    final chartMaxValue = series.isEmpty
        ? 1.0
        : series
            .fold<double>(0, (max, value) => value > max ? value : max)
            .clamp(1.0, double.infinity);
    final normalized = series.map((value) => value / chartMaxValue).toList();

    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: const Color(0xFFE7EAF0),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sales Growth Overview',
                  style: TextStyle(
                    color: ReportsPage._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE7EAF0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_LiveGrowthPeriod>(
                    value: _selectedPeriod,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF7A859C),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF3E4758),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _LiveGrowthPeriod.values
                        .map(
                          (period) => DropdownMenuItem<_LiveGrowthPeriod>(
                            value: period,
                            child: Text(period.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedPeriod = value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TSH ${currentRevenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: ReportsPage._ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  delta == null
                      ? _selectedPeriod.label
                      : '${delta >= 0 ? '+' : '-'}${delta.abs().toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF2FA24A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 12,
                  color: Color(0xFF2FA24A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'total revenue • ${_selectedPeriod.label}',
            style: const TextStyle(
              color: ReportsPage._muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 166,
            child: _OverviewChart(
              values: normalized,
              rawValues: series,
              scaleMax: chartMaxValue,
              labels: labels,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatsGrid extends StatelessWidget {
  const _OverviewStatsGrid({required this.summary});

  final _DashboardSummaryData summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final itemWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: _OverviewStatCard(
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF6BA5FF),
                iconBackground: const Color(0xFFF4F8FF),
                title: 'Today Revenue',
                value: 'TSH ${summary.today.toStringAsFixed(0)}',
                footer: summary.deltaText ?? 'Updated just now',
                footerColor: summary.deltaIsPositive == false
                    ? const Color(0xFFD65555)
                    : const Color(0xFF2FA24A),
                showTrend: true,
                trendUp: summary.deltaIsPositive ?? true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _OverviewStatCard(
                icon: Icons.shopping_bag_outlined,
                iconColor: const Color(0xFFF6B34A),
                iconBackground: const Color(0xFFFFF7ED),
                title: 'Yesterday Sales',
                value: 'TSH ${summary.yesterdaySales.toStringAsFixed(0)}',
                footer: 'Compared to today',
                footerColor: const Color(0xFF7A859C),
                showTrend: true,
                trendUp: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _OverviewStatCard(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFFEF6A7A),
                iconBackground: const Color(0xFFFFEEF1),
                title: 'Today Orders',
                value: summary.todayOrdersCount.toString(),
                footer: 'Updated today',
                footerColor: const Color(0xFF7A859C),
                showTrend: true,
                trendUp: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _OverviewStatCard(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBackground: const Color(0xFFF5F1FF),
                title: 'Today Expenses',
                value: 'TSH ${summary.todayExpenses.toStringAsFixed(0)}',
                footer: 'Updated today',
                footerColor: const Color(0xFF7A859C),
                showTrend: true,
                trendUp: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.footer,
    this.footerColor,
    this.showTrend = false,
    this.trendUp = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final String footer;
  final Color? footerColor;
  final bool showTrend;
  final bool trendUp;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(12),
      borderColor: const Color(0xFFE7EAF0),
      radius: 12,
      child: SizedBox(
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, size: 10, color: iconColor),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF7A859C),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: ReportsPage._ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (showTrend) ...[
                  Icon(
                    trendUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: footerColor,
                  ),
                  const SizedBox(width: 3),
                ],
                Text(
                  footer,
                  style: TextStyle(
                    color: footerColor ?? const Color(0xFF7A859C),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Last 30 days',
                  style: TextStyle(
                    color: Color(0xFF8A93A7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsPromoCard extends StatelessWidget {
  const _InsightsPromoCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 152,
      child: Stack(
        children: [
          const MarketSurfaceCard(
            borderColor: Color(0xFFE7EAF0),
            radius: 14,
            child: SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6E8F0)),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF5B8CFF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unlock Smart Sales Insights',
                        style: TextStyle(
                          color: ReportsPage._ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Advanced reports, forecasting tools, and team performance tracking in one place.',
                        style: TextStyle(
                          color: ReportsPage._muted,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        const ExpensesTrackingPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5B8CFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'Record My Expenses',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) => const ReportHubPage(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ReportsPage._ink,
                                side:
                                    const BorderSide(color: Color(0xFFE1E6EE)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'See My Store Reports',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.radius,
    required this.color,
  });

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    const dashWidth = 6.0;
    const dashGap = 5.0;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}

class _GrowthOverviewCard extends StatelessWidget {
  const _GrowthOverviewCard({required this.summary});

  final _DashboardSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final chartMaxValue = summary.recentRevenueValues.isEmpty
        ? 1.0
        : summary.recentRevenueValues
            .fold<double>(0, (max, value) => value > max ? value : max)
            .clamp(1.0, double.infinity);
    final normalized = summary.recentRevenueValues
        .map((value) => value / chartMaxValue)
        .toList();
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: const Color(0xFFE7EAF0),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sales Growth Overview',
                  style: TextStyle(
                    color: ReportsPage._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE7EAF0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summary.recentRevenueLabel,
                      style: const TextStyle(
                        color: Color(0xFF3E4758),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF7A859C),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TSH ${summary.revenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: ReportsPage._ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  summary.deltaText == null
                      ? 'Today'
                      : '${summary.deltaIsPositive == false ? '-' : '+'}${summary.deltaText}',
                  style: const TextStyle(
                    color: Color(0xFF2FA24A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 12,
                  color: Color(0xFF2FA24A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'total revenue • ${summary.recentRevenueLabel}',
            style: const TextStyle(
              color: ReportsPage._muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 166,
            child: _OverviewChart(
              values: normalized,
              rawValues: summary.recentRevenueValues,
              scaleMax: chartMaxValue,
              labels: labels,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewChart extends StatelessWidget {
  const _OverviewChart({
    required this.values,
    required this.rawValues,
    required this.scaleMax,
    required this.labels,
  });

  final List<double> values;
  final List<double> rawValues;
  final double scaleMax;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final yLabels = List<String>.generate(5, (index) {
      final ratio = 1 - (index / 4);
      return _compactTsh(scaleMax * ratio);
    });

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: yLabels
                      .map(
                        (label) => Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF9AA3B2),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CustomPaint(
                  painter: _OverviewChartPainter(
                    values: values,
                    rawValues: rawValues,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              labels.length,
              (index) => Text(
                labels[index],
                style: const TextStyle(
                  color: Color(0xFF9AA3B2),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewChartPainter extends CustomPainter {
  const _OverviewChartPainter({
    required this.values,
    required this.rawValues,
  });

  final List<double> values;
  final List<double> rawValues;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final bgPaint = Paint()
      ..color = const Color(0xFFEEF4FF)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF5B8CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5B8CFF).withValues(alpha: 0.28),
          const Color(0xFF5B8CFF).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF3)
      ..strokeWidth = 1;

    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 8.0;
    const bottomPad = 22.0;
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    for (var i = 0; i < 5; i++) {
      final y = topPad + (chartHeight / 4) * i;
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = leftPad + (chartWidth / (values.length - 1)) * i;
      final y = topPad + (1 - values[i].clamp(0.0, 1.0)) * chartHeight;
      points.add(Offset(x, y));
    }

    const highlightIndex = 3;
    final highlightPoint = points[highlightIndex];
    final highlightRect = Rect.fromCenter(
      center: Offset(highlightPoint.dx, (topPad + chartHeight * 0.47)),
      width: chartWidth / values.length,
      height: chartHeight * 0.92,
    );
    canvas.drawRect(highlightRect,
        Paint()..color = const Color(0xFF5B8CFF).withValues(alpha: 0.12));

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final cp1 = Offset(prev.dx + ((current.dx - prev.dx) / 2), prev.dy);
      final cp2 = Offset(prev.dx + ((current.dx - prev.dx) / 2), current.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, current.dx, current.dy);
    }

    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, size.height - bottomPad + 6)
      ..lineTo(points.first.dx, size.height - bottomPad + 6)
      ..close();

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = const Color(0xFF5B8CFF);
    final hollowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFF5B8CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      if (i == highlightIndex) {
        canvas.drawCircle(point, 14, bgPaint);
      }
      canvas.drawCircle(point, 4.5, pointPaint);
      if (i == highlightIndex) {
        canvas.drawCircle(point, 4.5, hollowPaint);
        canvas.drawCircle(point, 4.5, outlinePaint);

        final bubble = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(point.dx - 18, point.dy - 36),
              width: 66,
              height: 30),
          const Radius.circular(8),
        );
        final bubblePaint = Paint()..color = const Color(0xFF5B8CFF);
        canvas.drawRRect(bubble, bubblePaint);
        final tp = TextPainter(
          text: TextSpan(
            text: _compactTsh(
              rawValues.length > highlightIndex ? rawValues[highlightIndex] : 0,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(bubble.left + 8, bubble.top + 7));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OverviewChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.rawValues != rawValues;
  }
}

String _compactTsh(double value) {
  if (value >= 1000000) {
    return 'TSh ${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (value >= 1000) {
    return 'TSh ${(value / 1000).toStringAsFixed(1)}K';
  }
  return 'TSh ${value.toStringAsFixed(0)}';
}

class _EmptySummary extends StatelessWidget {
  const _EmptySummary({required this.summary});

  final _DashboardSummaryData summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Operations",
              style: TextStyle(
                color: Color(0xFF7A859C),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFCE1B4)),
              ),
              child: const Text(
                'No active sales',
                style: TextStyle(
                  color: Color(0xFFC77817),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'TSH 0',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ReportsPage._ink,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ready for your first checkout of the day',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8A93A7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: _MiniSummaryStat(title: 'Orders', value: '0')),
            SizedBox(width: 10),
            Expanded(
              child: _MiniSummaryStat(title: 'Avg. Basket', value: 'TSH 0'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniSummaryStat(title: 'Vs Yesterday', value: '100%'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActiveSummary extends StatelessWidget {
  const _ActiveSummary({required this.summary});

  final _DashboardSummaryData summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Performance",
              style: TextStyle(
                color: Color(0xFF7A859C),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8EE),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD5F1DE)),
              ),
              child: const Text(
                'Live updates',
                style: TextStyle(
                  color: Color(0xFF1D8B48),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Gross Revenue',
                value: 'TSH ${summary.revenue.toStringAsFixed(0)}',
                footer: summary.deltaText ?? 'Updated just now',
                accent: summary.deltaIsPositive == false
                    ? const Color(0xFFC65B4A)
                    : const Color(0xFF1D8B48),
                showDelta: summary.deltaText != null,
                deltaIsPositive: summary.deltaIsPositive,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Total Orders',
                value: summary.orders.toString(),
                footer: 'Updated just now',
                accent: const Color(0xFF2E6EE8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Average Ticket',
                value: 'TSH ${summary.averageOrder.toStringAsFixed(0)}',
                footer: 'Per order',
                accent: const Color(0xFF9747FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: "Today's Top Seller",
                value: summary.bestSeller,
                footer: summary.bestSellerCount == null
                    ? 'Nothing sold yet'
                    : '${summary.bestSellerCount} sold today',
                accent: const Color(0xFFC38A13),
                highlightValue: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.footer,
    required this.accent,
    this.showDelta = false,
    this.deltaIsPositive,
    this.highlightValue = false,
  });

  final String title;
  final String value;
  final String footer;
  final Color accent;
  final bool showDelta;
  final bool? deltaIsPositive;
  final bool highlightValue;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE7EAF0),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7A859C),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: highlightValue ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ReportsPage._ink,
              fontSize: highlightValue ? 14 : 18,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          if (showDelta && deltaIsPositive != null) ...[
            Row(
              children: [
                Icon(
                  deltaIsPositive!
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: accent,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  footer,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              footer,
              style: const TextStyle(
                color: Color(0xFF8A93A7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniSummaryStat extends StatelessWidget {
  const _MiniSummaryStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      backgroundColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE7EAF0),
      radius: 14,
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A93A7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestActivityHeader extends StatelessWidget {
  const _LatestActivityHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return MarketSectionHeader(
      title: 'Latest activity',
      titleSize: 15,
      titleWeight: FontWeight.w700,
      trailing: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSeeAll,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Text(
                'See all',
                style: TextStyle(
                  color: ReportsPage._blue,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                color: ReportsPage._blue,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumRecentActivityCard extends StatelessWidget {
  const _PremiumRecentActivityCard({required this.items});

  final List<_ActivityItemData> items;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      borderColor: const Color(0xFFE7EAF0),
      radius: 22,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                _ActivityTile(item: item),
                if (index != items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE9ECF2),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader();

  void _openAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _RecentActivityPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: MarketSectionHeader(
        title: 'Latest activity',
        titleSize: 15,
        titleWeight: FontWeight.w700,
        trailing: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openAll(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    color: ReportsPage._blue,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ReportsPage._blue,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<_ActivityItemData> items;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 2),
      backgroundColor: Colors.white.withValues(alpha: 0.94),
      borderColor: ReportsPage._border,
      radius: 4,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              _ActivityTile(item: item),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE9ECF2),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final _ActivityItemData item;

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ActivityDetailPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 9, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: ReportsPage._ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: ReportsPage._muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.amount != null)
                    Text(
                      item.amount!,
                      style: const TextStyle(
                        color: ReportsPage._ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (item.amount != null) const SizedBox(height: 2),
                  Text(
                    item.time,
                    style: const TextStyle(
                      color: ReportsPage._muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7F889D),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewDetailPage extends StatelessWidget {
  const _OverviewDetailPage({required this.card});

  final _OverviewCardData card;

  String get _insight {
    switch (card.title) {
      case 'Sales today':
        return 'This shows how much came in today compared with yesterday. It is a quick read on how the day is going.';
      case 'Orders today':
        return 'This is the number of orders completed today. It helps you see if foot traffic is picking up.';
      case 'Average order':
        return 'A higher average order usually means people are adding more items or choosing higher-value products.';
      case 'Best seller':
        return 'This is the item moving fastest today. It is a good one to keep stocked and visible.';
      default:
        return 'This metric is ready if you want a closer look.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: ReportsPage._ink,
        title: Text(card.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ReportsPage._border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: card.iconBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(card.icon, color: card.iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.value,
                          style: const TextStyle(
                            color: ReportsPage._ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.footer,
                          style: const TextStyle(
                            color: ReportsPage._muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'What this means',
              style: TextStyle(
                color: ReportsPage._ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _insight,
              style: const TextStyle(
                color: ReportsPage._muted,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (card.delta != null) ...[
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: card.deltaIsPositive == false
                          ? const Color(0xFFC65B4A)
                          : ReportsPage._green,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      card.deltaIsPositive == false
                          ? '${card.delta} down from yesterday'
                          : '${card.delta} up from yesterday',
                      style: TextStyle(
                        color: card.deltaIsPositive == false
                            ? const Color(0xFFC65B4A)
                            : ReportsPage._green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentActivityPage extends StatelessWidget {
  const _RecentActivityPage();

  @override
  Widget build(BuildContext context) {
    final items = ReportsPage._buildActivityItems(
      context.watch<PosLocalStore>().orders,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: ReportsPage._ink,
        title: const Text('Latest activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        children: [
          _RecentActivityCard(items: items),
        ],
      ),
    );
  }
}

class _ActivityDetailPage extends StatelessWidget {
  const _ActivityDetailPage({required this.item});

  final _ActivityItemData item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: ReportsPage._ink,
        title: Text(item.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ReportsPage._border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: ReportsPage._muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Time: ${item.time}',
                style: const TextStyle(
                  color: ReportsPage._ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.amount != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Amount: ${item.amount}',
                  style: const TextStyle(
                    color: ReportsPage._ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.footer,
    this.delta,
    this.deltaIsPositive,
    this.highlightValue = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final String footer;
  final String? delta;
  final bool? deltaIsPositive;
  final bool highlightValue;
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.background,
    this.foreground,
    this.iconBackground,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Gradient? background;
  final Color? foreground;
  final Color? iconBackground;
}

class _ActivityItemData {
  const _ActivityItemData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.time,
    this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String time;
  final String? amount;
}
