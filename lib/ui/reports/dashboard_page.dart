import 'package:intl/intl.dart';
import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../../utils/currency_formatter.dart';
import '../more/add_expense_page.dart';
import '../sales/order_history_page.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';
import 'enhanced_report_page.dart';
import 'pos_report_catalog.dart';
import 'reports_catalog_page.dart';
import 'widgets/dashboard_cards.dart';

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
  String _formatPrice(double value, String? currency) {
    return formatMoney(value, currency);
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

  bool _isActiveSale(CompletedOrder order) {
    final status = order.status.trim().toLowerCase();
    return status != 'voided' &&
        status != 'returned' &&
        status != 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final orders = store.orders;
    final activeOrders = orders.where(_isActiveSale).toList();
    final expenses = store.expenses;
    final canViewReports = store.hasPermission('View Reports');
    final canManagePayments = store.hasPermission('Manage Payments');

    final now = DateTime.now();

    // 1. Calculate Today's Sales (excluding voided/returned/cancelled orders)
    final todayOrders = activeOrders.where((o) {
      final d = DateTime.tryParse(o.dateTime);
      return d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();

    final todaySales = todayOrders.fold<double>(0.0, (sum, o) => sum + o.total);

    // Yesterday sales for real comparison
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayOrders = activeOrders.where((o) {
      final d = DateTime.tryParse(o.dateTime);
      return d != null &&
          d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day;
    }).toList();
    final yesterdaySales =
        yesterdayOrders.fold<double>(0.0, (sum, o) => sum + o.total);

    // Today's expenses
    final todayExpenses = expenses.where((e) {
      final d = e.date.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).fold<double>(0.0, (sum, e) => sum + e.amount);

    final m3Date = DateTime(now.year, now.month);
    final m2Date = DateTime(now.year, now.month - 1);
    final m1Date = DateTime(now.year, now.month - 2);
    final monthFormat = DateFormat('MMM', context.strings.languageCode);

    double salesForMonth(DateTime target) {
      return activeOrders.where((o) {
        final d = DateTime.tryParse(o.dateTime);
        return d != null && d.year == target.year && d.month == target.month;
      }).fold<double>(0.0, (sum, o) => sum + o.total);
    }

    final s1 = salesForMonth(m1Date);
    final s2 = salesForMonth(m2Date);
    final s3 = salesForMonth(m3Date);

    // Growth percentage calculation
    final hasGrowth = yesterdaySales <= 0 ? (todaySales > 0) : (todaySales >= yesterdaySales);
    final growthText = yesterdaySales <= 0
        ? (todaySales > 0 ? context.tr('100% Growth Today') : context.tr('No sales recorded yet today'))
        : context.tr('{p0}% {p1} Today', args: {'p0': (((todaySales - yesterdaySales) / yesterdaySales) * 100).abs().toStringAsFixed(0), 'p1': context.tr(hasGrowth ? 'Growth' : 'Dip')});

    return Scaffold(
      backgroundColor: AppThemePalette.of(context).pageBackground,
      drawer: widget.useSharedShell ? null : const MarketAppDrawer(selectedItem: 'Dashboard'),
      body: SafeArea(
        top: !widget.useSharedShell,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
          children: [
            if (!canViewReports)
              _CashierShiftOverviewCard(
                storeName: store.activeStoreName,
                cashierName: store.currentUser?.name ?? '',
                openShiftName: store.openShift?.register,
                todayOrderCount: todayOrders.length,
                onOpenOrders: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const OrderHistoryPage(),
                    ),
                  );
                },
              )
            else ...[
              // Card 1: Today's Sale Overview
              TodaySaleOverviewCard(
                formattedSale: _formatPrice(todaySales, store.profile.currency),
                growthText: growthText,
                hasGrowth: hasGrowth,
                s1: s1,
                s2: s2,
                s3: s3,
                m1Label: monthFormat.format(m1Date),
                m2Label: monthFormat.format(m2Date),
                m3Label: monthFormat.format(m3Date),
              ),
              const SizedBox(height: 12),

              // Card 2: Expenses (Today)
              ExpensesSummaryCard(
                formattedAmount:
                    _formatPrice(todayExpenses, store.profile.currency),
                onAddExpense: canManagePayments
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const AddExpensePage(),
                          ),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 12),

              // Card 3: Most Used Reports
              MostUsedReportsCard(
                onSalesTap: () => _openReport(context, ReportData.sales),
                onPurchasesTap: () =>
                    _openReport(context, ReportData.receivings),
                onBalSheetTap: () =>
                    _openReport(context, ReportData.balanceSheet),
                onProfitLossTap: () =>
                    _openReport(context, ReportData.profitLoss),
                onSeeAllTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const ReportsCatalogPage(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CashierShiftOverviewCard extends StatelessWidget {
  const _CashierShiftOverviewCard({
    required this.storeName,
    required this.cashierName,
    required this.openShiftName,
    required this.todayOrderCount,
    required this.onOpenOrders,
  });

  final String storeName;
  final String cashierName;
  final String? openShiftName;
  final int todayOrderCount;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final shiftOpen = openShiftName != null && openShiftName!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  storeName.trim().isEmpty
                      ? context.tr('Register overview')
                      : storeName,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: shiftOpen
                      ? AppColors.successLight
                      : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sharp),
                ),
                child: Text(
                  shiftOpen
                      ? openShiftName!
                      : context.tr('No active shift'),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        shiftOpen ? AppColors.successDeep : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (cashierName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cashierName,
              style: AppTypography.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            context.tr('Today\'s completed orders: {p0}',
                args: {'p0': todayOrderCount}),
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onOpenOrders,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: Text(context.tr('View order history')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 1: Today's Sale Overview
// ---------------------------------------------------------------------------
