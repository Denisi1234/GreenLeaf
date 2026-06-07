import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/home_page.dart';
import '../more/duka_ai_page.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'report_hub_page.dart';
import 'reports_catalog_page.dart';

// ignore_for_file: unused_element, unused_field

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
  final now = DateTime.now();
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
  const ReportsPage({super.key});

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
      background: LinearGradient(
        colors: [Color(0xFF2F6FDF), Color(0xFF265ECB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foreground: Colors.white,
      emphasized: true,
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

  static const List<_ActivityItemData> _activityItems = [
    _ActivityItemData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF2AA24F),
      iconBackground: Color(0xFFEAF8EE),
      title: 'Order #1038',
      subtitle: '2 items - card payment',
      amount: '\$129.50',
      time: '10:24 AM',
    ),
    _ActivityItemData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF2E6EE8),
      iconBackground: Color(0xFFECF3FF),
      title: 'Order #1037',
      subtitle: '1 item - cash payment',
      amount: '\$45.00',
      time: '10:12 AM',
    ),
    _ActivityItemData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF9747FF),
      iconBackground: Color(0xFFF3EAFE),
      title: 'Order #1036',
      subtitle: '3 items - card payment',
      amount: '\$199.99',
      time: '9:58 AM',
    ),
    _ActivityItemData(
      icon: Icons.point_of_sale_outlined,
      iconColor: Color(0xFFC38A13),
      iconBackground: Color(0xFFFEF5E3),
      title: 'Drawer opened',
      subtitle: 'Sarah Johnson',
      time: '9:45 AM',
    ),
    _ActivityItemData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF2AA24F),
      iconBackground: Color(0xFFEAF8EE),
      title: 'Order #1035',
      subtitle: '1 item - cash payment',
      amount: '\$28.00',
      time: '9:33 AM',
    ),
  ];

  static List<_OverviewCardData> _buildOverviewCards(PosLocalStore store) {
    final today = DateTime.now();
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
        badge: 'Now',
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
      return _ActivityItemData(
        icon: Icons.shopping_cart_outlined,
        iconColor: const Color(0xFF2AA24F),
        iconBackground: const Color(0xFFEAF8EE),
        title: 'Order ${order.id}',
        subtitle:
            '$itemCount item${itemCount == 1 ? '' : 's'} - ${order.paymentMethod.toLowerCase()} payment',
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
    final now = DateTime.now();
    return '${monthNames[now.month - 1]} ${now.day}, ${now.year} (${weekdayNames[now.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _buildDashboardSummary();
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
        drawer: const MarketAppDrawer(selectedItem: 'Dashboard'),
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: BackdropGlow()),
              Column(
                children: [
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
                          _SummaryPanel(summary: summary),
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
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const MarketHomePage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 142,
                child: _DukaAiFloatingButton(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const DukaAiAdvisorPage(),
                      ),
                    );
                  },
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
    required this.monthlySales,
    required this.activeClients,
    required this.conversionRate,
    required this.deltaText,
    required this.deltaIsPositive,
  });

  final double totalRevenue;
  final int monthlySales;
  final int activeClients;
  final double conversionRate;
  final String? deltaText;
  final bool? deltaIsPositive;

  double get revenue => totalRevenue;
  int get orders => monthlySales;
  double get averageOrder =>
      monthlySales == 0 ? 0.0 : totalRevenue / monthlySales;
  String get bestSeller => 'No sales yet';
  int? get bestSellerCount => activeClients;
}

_DashboardSummaryData _buildDashboardSummary() {
  const totalRevenue = 728450.0;
  const monthlySales = 1284;
  const activeClients = 642;
  const conversionRate = 4.8;
  const deltaText = '7.4%';
  return const _DashboardSummaryData(
    totalRevenue: totalRevenue,
    monthlySales: monthlySales,
    activeClients: activeClients,
    conversionRate: conversionRate,
    deltaText: deltaText,
    deltaIsPositive: true,
  );
}

class _PremiumReportsHeader extends StatelessWidget {
  const _PremiumReportsHeader({
    required this.dateLabel,
  });

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return const MarketPageHeader(
      title: 'Dashboard',
      showBackButton: false,
      centerTitle: false,
      titleSize: 22,
      titleWeight: FontWeight.w700,
      leading: _ReportsBrandIcon(),
      actions: [
        _HeaderActionButton(
          icon: Icons.notifications_none_rounded,
          background: Colors.white,
          foreground: ReportsPage._ink,
          borderColor: Color(0xFFE7EAF0),
          showDot: true,
        ),
        SizedBox(width: 8),
        _HeaderActionButton(
          icon: Icons.add_rounded,
          background: Color(0xFF23262D),
          foreground: Colors.white,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        elevation: 18,
        shadowColor: const Color(0x40208F5A),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF28B26D), Color(0xFF18824E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40208F5A),
                  blurRadius: 30,
                  spreadRadius: 1,
                  offset: Offset(0, 16),
                ),
              ],
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
      ),
    );
  }
}

class _DukaAiFloatingButton extends StatelessWidget {
  const _DukaAiFloatingButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        final lift = -14.0 * (1 - value);
        final scale = 0.92 + (0.08 * value);
        final glowOpacity = 0.08 + (0.06 * value);

        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFF2D6CEA).withValues(alpha: glowOpacity),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        elevation: 16,
        shadowColor: const Color(0x332D6CEA),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.96),
                  const Color(0xFFF6F9FE).withValues(alpha: 0.96),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD8E0EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E0F172A),
                  blurRadius: 22,
                  offset: Offset(0, 11),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF2D6CEA).withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAF0FF), Color(0xFFDCE7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: Color(0xFF2D6CEA),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DUKA AI',
                          style: TextStyle(
                            color: ReportsPage._ink,
                            fontSize: 10.8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Ask anything',
                          style: TextStyle(
                            color: ReportsPage._muted.withValues(alpha: 0.82),
                            fontSize: 8.8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 3, top: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6CEA).withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6CEA).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
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
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ReportsPage._border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C0E1726),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
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
                  Row(
                    children: [
                      Text(
                        card.footer,
                        style: const TextStyle(
                          color: ReportsPage._muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (card.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5E6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: Color(0xFFF2B437),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                card.badge!,
                                style: const TextStyle(
                                  color: Color(0xFFC78C17),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const MarketHomePage(),
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
    final iconBackground =
        hero || action.emphasized ? Colors.white : action.iconBackground!;
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
            boxShadow: [
              BoxShadow(
                color: hero ? const Color(0x1F2560D6) : const Color(0x140E1726),
                blurRadius: hero ? 14 : 6,
                offset: const Offset(0, 2),
              ),
            ],
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
  const _SummaryPanel({required this.summary});

  final _DashboardSummaryData summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OverviewStatsGrid(summary: summary),
        const SizedBox(height: 12),
        const _InsightsPromoCard(),
        const SizedBox(height: 12),
        _GrowthOverviewCard(summary: summary),
      ],
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
              child: const _OverviewStatCard(
                icon: Icons.payments_outlined,
                iconColor: Color(0xFF6BA5FF),
                iconBackground: Color(0xFFF4F8FF),
                title: 'Total Revenue',
                value: '\$728,450',
                footer: '+7.4%',
                footerColor: Color(0xFF2FA24A),
                showTrend: true,
                trendUp: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: const _OverviewStatCard(
                icon: Icons.shopping_bag_outlined,
                iconColor: Color(0xFFF6B34A),
                iconBackground: Color(0xFFFFF7ED),
                title: 'Monthly Sales',
                value: '1,284',
                footer: '+5.9%',
                footerColor: Color(0xFF2FA24A),
                showTrend: true,
                trendUp: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: const _OverviewStatCard(
                icon: Icons.groups_rounded,
                iconColor: Color(0xFFEF6A7A),
                iconBackground: Color(0xFFFFEEF1),
                title: 'Active Clients',
                value: '642',
                footer: '+3.2%',
                footerColor: Color(0xFF2FA24A),
                showTrend: true,
                trendUp: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: const _OverviewStatCard(
                icon: Icons.bolt_rounded,
                iconColor: Color(0xFF8B5CF6),
                iconBackground: Color(0xFFF5F1FF),
                title: 'Conversion Rate',
                value: '4.8%',
                footer: '-1.1%',
                footerColor: Color(0xFFD65555),
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
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080E1726),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0E1726),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: _DashedBorderPainter(
                radius: 14,
                color: Color(0xFFDDE3EA),
              ),
            ),
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
                                    builder: (context) => const ReportHubPage(),
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
                                'Upgrade Plan',
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
                                'My Store Reports',
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0E1726),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This year',
                      style: TextStyle(
                        color: Color(0xFF3E4758),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
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
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '701.34K',
                style: TextStyle(
                  color: ReportsPage._ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  '+14.5%',
                  style: TextStyle(
                    color: Color(0xFF2FA24A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
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
          const Text(
            'total revenue',
            style: TextStyle(
              color: ReportsPage._muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(
            height: 166,
            child: _OverviewChart(
              values: [0.32, 0.78, 0.58, 0.44, 0.76, 0.50, 0.29],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewChart extends StatelessWidget {
  const _OverviewChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
    final yLabels = [r'40$', r'30$', r'20$', r'10$', r'0$'];

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
                  painter: _OverviewChartPainter(values: values),
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
  const _OverviewChartPainter({required this.values});

  final List<double> values;

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
      center: Offset(highlightPoint.dx, (topPad + chartHeight * 0.53)),
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
          text: const TextSpan(
            text: '\$37,420',
            style: TextStyle(
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
    return oldDelegate.values != values;
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.showDot = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x100E1726),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, color: foreground, size: 20)),
          if (showDot)
            Positioned(
              right: 11,
              top: 11,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF2B6FF3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _compactMoney(double value) {
  if (value >= 1000000) {
    return 'TSH ${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (value >= 1000) {
    return 'TSH ${(value / 1000).toStringAsFixed(1)}K';
  }
  return 'TSH ${value.toStringAsFixed(0)}';
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
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
    return Row(
      children: [
        const _SectionTitle('Latest activity'),
        const Spacer(),
        InkWell(
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
      ],
    );
  }
}

class _PremiumRecentActivityCard extends StatelessWidget {
  const _PremiumRecentActivityCard({required this.items});

  final List<_ActivityItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100E1726),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
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
      child: Row(
        children: [
          const _SectionTitle('Latest activity'),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(4),
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
                      fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<_ActivityItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ReportsPage._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100E1726),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
        children: const [
          _RecentActivityCard(items: ReportsPage._activityItems),
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
    this.badge,
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
  final String? badge;
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
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Gradient? background;
  final Color? foreground;
  final Color? iconBackground;
  final bool emphasized;
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
