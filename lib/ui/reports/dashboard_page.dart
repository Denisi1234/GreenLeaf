import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'enhanced_report_page.dart';
import 'pos_report_catalog.dart';
import 'reports_catalog_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.useSharedShell = false,
  });

  final bool useSharedShell;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _formatPrice(double value) {
    return 'Sh ${formatCurrency(value)}';
  }

  void _openReport(BuildContext context, ReportData data) {
    final report = PosReport(
      _reportTitle(data),
      ReportGroup.summary,
      data,
      chart: true,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EnhancedReportPage(report: report),
      ),
    );
  }

  String _reportTitle(ReportData data) {
    switch (data) {
      case ReportData.sales:
        return 'Sales Report';
      case ReportData.receivings:
        return 'Purchases Report';
      case ReportData.balanceSheet:
        return 'Balance Sheet';
      case ReportData.profitLoss:
        return 'Profit & Loss Statement';
      default:
        return 'Detailed Report';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final orders = store.orders;
    final expenses = store.expenses;
    final inventory = store.inventory;

    final now = DateTime.now();

    // 1. Calculate Today's Sales
    final todayOrders = orders.where((o) {
      final d = DateTime.tryParse(o.dateTime);
      return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    final todaySales = todayOrders.fold<double>(0.0, (sum, o) => sum + o.total);

    // Yesterday sales for real comparison
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayOrders = orders.where((o) {
      final d = DateTime.tryParse(o.dateTime);
      return d != null && d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day;
    }).toList();
    final yesterdaySales = yesterdayOrders.fold<double>(0.0, (sum, o) => sum + o.total);

    // Month expenses
    final monthExpenses = expenses.where((e) {
      final d = e.date;
      return d.year == now.year && d.month == now.month;
    }).fold<double>(0.0, (sum, e) => sum + e.amount);

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final currentMonthName = months[now.month - 1];

    // Compute monthly trends for chart
    final m3 = now.month;
    final m2 = m3 == 1 ? 12 : m3 - 1;
    final m1 = m2 == 1 ? 12 : m2 - 1;

    double salesForMonth(int m) {
      return orders.where((o) {
        final d = DateTime.tryParse(o.dateTime);
        return d != null && d.month == m;
      }).fold<double>(0.0, (sum, o) => sum + o.total);
    }

    final s1 = salesForMonth(m1);
    final s2 = salesForMonth(m2);
    final s3 = salesForMonth(m3);

    // Growth percentage calculation
    final hasGrowth = yesterdaySales <= 0 ? (todaySales > 0) : (todaySales >= yesterdaySales);
    final growthText = yesterdaySales <= 0
        ? (todaySales > 0 ? '100% Growth Today' : 'No sales recorded yet today')
        : '${(((todaySales - yesterdaySales) / yesterdaySales) * 100).abs().toStringAsFixed(0)}% ${hasGrowth ? 'Growth' : 'Dip'} Today';

    return Scaffold(
      backgroundColor: const Color(0xFFEAF2F9), // Soft light-blue grey matching the app theme
      drawer: widget.useSharedShell ? null : const MarketAppDrawer(selectedItem: 'Dashboard'),
      body: SafeArea(
        top: !widget.useSharedShell,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
          children: [
            // Card 1: Today's Sale Overview
            _TodaySaleOverviewCard(
              formattedSale: _formatPrice(todaySales),
              growthText: growthText,
              hasGrowth: hasGrowth,
              s1: s1,
              s2: s2,
              s3: s3,
              m1Label: months[m1 - 1],
              m2Label: months[m2 - 1],
              m3Label: months[m3 - 1],
            ),
            const SizedBox(height: 12),

            // Card 2: Expenses (Nov)
            _ExpensesSummaryCard(
              monthName: currentMonthName,
              formattedAmount: _formatPrice(monthExpenses),
            ),
            const SizedBox(height: 12),

            // Card 3: Most Used Reports
            _MostUsedReportsCard(
              onSalesTap: () => _openReport(context, ReportData.sales),
              onPurchasesTap: () => _openReport(context, ReportData.receivings),
              onBalSheetTap: () => _openReport(context, ReportData.balanceSheet),
              onProfitLossTap: () => _openReport(context, ReportData.profitLoss),
              onSeeAllTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ReportsCatalogPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 1: Today's Sale Overview
// ---------------------------------------------------------------------------
class _TodaySaleOverviewCard extends StatelessWidget {
  const _TodaySaleOverviewCard({
    required this.formattedSale,
    required this.growthText,
    required this.hasGrowth,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.m1Label,
    required this.m2Label,
    required this.m3Label,
  });

  final String formattedSale;
  final String growthText;
  final bool hasGrowth;
  final double s1;
  final double s2;
  final double s3;
  final String m1Label;
  final String m2Label;
  final String m3Label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Sale Overview (Today)',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Text(
                  "Today's Total Sale",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedSale,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: hasGrowth ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasGrowth ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: hasGrowth ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      growthText,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: hasGrowth ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Line Chart
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _SaleOverviewChartPainter(
                values: [s1, s2, math.max(s3, 500.0)],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Month X-Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m1Label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                m2Label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                m3Label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleOverviewChartPainter extends CustomPainter {
  _SaleOverviewChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.reduce(math.max);
    final ceiling = maxVal <= 0 ? 1000.0 : maxVal * 1.25;

    // Dashed base line
    final dashPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height - 4),
        Offset(startX + 4, size.height - 4),
        dashPaint,
      );
      startX += 8;
    }

    // Points
    final p0 = Offset(4, size.height - (values[0] / ceiling) * (size.height - 18) - 10);
    final p1 = Offset(size.width * 0.5, size.height - (values[1] / ceiling) * (size.height - 18) - 10);
    final p2 = Offset(size.width - 4, size.height - (values[2] / ceiling) * (size.height - 18) - 10);

    // Blue Line
    final linePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = const Color(0xFF0284C7);
    final innerWhite = Paint()..color = Colors.white;

    for (final p in [p0, p1, p2]) {
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 2, innerWhite);
    }
  }

  @override
  bool shouldRepaint(covariant _SaleOverviewChartPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Card 2: Expenses (Nov)
// ---------------------------------------------------------------------------
class _ExpensesSummaryCard extends StatelessWidget {
  const _ExpensesSummaryCard({
    required this.monthName,
    required this.formattedAmount,
  });

  final String monthName;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expenses ($monthName)',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedAmount,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 3: Most Used Reports
// ---------------------------------------------------------------------------
class _MostUsedReportsCard extends StatelessWidget {
  const _MostUsedReportsCard({
    required this.onSalesTap,
    required this.onPurchasesTap,
    required this.onBalSheetTap,
    required this.onProfitLossTap,
    required this.onSeeAllTap,
  });

  final VoidCallback onSalesTap;
  final VoidCallback onPurchasesTap;
  final VoidCallback onBalSheetTap;
  final VoidCallback onProfitLossTap;
  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Most Used Reports',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.1,
                ),
              ),
              InkWell(
                onTap: onSeeAllTap,
                child: Text(
                  'See All',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReportIconItem(
                label: 'Sales',
                icon: Icons.receipt_long_rounded,
                badgeSymbol: '%',
                badgeColor: const Color(0xFFF472B6),
                onTap: onSalesTap,
              ),
              _ReportIconItem(
                label: 'Purchases',
                icon: Icons.assignment_outlined,
                badgeSymbol: null,
                onTap: onPurchasesTap,
              ),
              _ReportIconItem(
                label: 'Bal. Sheet',
                icon: Icons.receipt_outlined,
                badgeSymbol: '₹',
                hasCrown: true,
                badgeColor: const Color(0xFFF472B6),
                onTap: onBalSheetTap,
              ),
              _ReportIconItem(
                label: 'Profit & Loss',
                icon: Icons.description_outlined,
                badgeSymbol: '1L',
                badgeColor: const Color(0xFFF472B6),
                onTap: onProfitLossTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportIconItem extends StatelessWidget {
  const _ReportIconItem({
    required this.label,
    required this.icon,
    this.badgeSymbol,
    this.hasCrown = false,
    this.badgeColor = const Color(0xFFF472B6),
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? badgeSymbol;
  final bool hasCrown;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Soft pink background pad
                Container(
                  width: 44,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 24,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (hasCrown)
                  Positioned(
                    top: -6,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA855F7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.star_rounded, size: 9, color: Colors.white),
                    ),
                  ),
                if (badgeSymbol != null)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        badgeSymbol!,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 4: Store Alerts (Always shows all real-time alerts)
// ---------------------------------------------------------------------------
class _StoreAlertsCard extends StatelessWidget {
  const _StoreAlertsCard({
    required this.outOfStockCount,
    required this.lowStockCount,
    required this.pendingCreditCount,
    required this.outOfStockItems,
    required this.lowStockItems,
  });

  final int outOfStockCount;
  final int lowStockCount;
  final int pendingCreditCount;
  final List<dynamic> outOfStockItems;
  final List<dynamic> lowStockItems;

  @override
  Widget build(BuildContext context) {
    final totalAlerts = outOfStockCount + lowStockCount + pendingCreditCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Store Alerts',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: totalAlerts > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  totalAlerts > 0 ? '$totalAlerts Active' : 'All Clear',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: totalAlerts > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Alert 1: Out of Stock
          if (outOfStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AlertRow(
                icon: Icons.cancel_rounded,
                color: const Color(0xFFEF4444),
                bgColor: const Color(0xFFFEE2E2),
                title: '$outOfStockCount items are completely Out of Stock',
                subtitle: outOfStockItems.take(2).map((p) => p.name).join(', '),
              ),
            ),

          // Alert 2: Low Stock Warning
          if (lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AlertRow(
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFEF3C7),
                title: '$lowStockCount items are Low on Stock',
                subtitle: lowStockItems.take(2).map((p) => '${p.name} (${p.stockCount} left)').join(', '),
              ),
            ),

          // Alert 3: Pending Customer Credit
          if (pendingCreditCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _AlertRow(
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                title: '$pendingCreditCount customers have outstanding debt',
                subtitle: 'Tap to review debtor ledger and collect payments',
              ),
            ),

          // When all clear
          if (totalAlerts == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _AlertRow(
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFD1FAE5),
                title: 'All store inventory levels and ledgers healthy',
                subtitle: 'No low stock warnings or urgent pending actions.',
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
