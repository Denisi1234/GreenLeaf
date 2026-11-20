import 'package:track_mauzo/l10n/app_localization.dart';
import '../../widgets/app_design.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../service/pos_order_models.dart';
import '../enhanced_report_page.dart';
import '../models/report_models.dart';
import '../pos_report_catalog.dart';
import '../pos_report_data.dart';
import '../services/report_data_service.dart';
import '../widgets/section_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/comparison_card.dart';
import '../widgets/insight_card.dart';

class SalesReportPage extends StatelessWidget {
  const SalesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Sales Summary',
        ReportGroup.summary,
        ReportData.sales,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalSales = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final totalOrders =
        table.rows.fold<int>(0, (sum, row) => sum + (row[1] as int));
    final totalUnits =
        table.rows.fold<int>(0, (sum, row) => sum + (row[2] as int));
    final avgOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;

    final cost = table.rows.fold<double>(0, (sum, row) {
      final c = row[4];
      return sum + (c is num ? c.toDouble() : 0.0);
    });
    final grossProfit = cost > 0 ? totalSales - cost : null;
    final grossMargin = grossProfit != null && totalSales > 0
        ? (grossProfit / totalSales) * 100
        : null;

    return [
      MetricData(
        title: 'Total Sales',
        value: 'TSh ${NumberFormat('#,##0.##').format(totalSales)}',
        icon: Icons.attach_money,
        iconColor: Color(0xFF166534),
        tint: Color(0xFF166534).withValues(alpha: 0.1),
        valueColor: Color(0xFF166534),
      ),
      MetricData(
        title: 'Total Orders',
        value: NumberFormat('#,###').format(totalOrders),
        icon: Icons.receipt_long,
        iconColor: Color(0xFF15803D),
        tint: Color(0xFF15803D).withValues(alpha: 0.1),
        valueColor: Color(0xFF15803D),
      ),
      MetricData(
        title: 'Avg Order Value',
        value: 'TSh ${NumberFormat('#,##0.##').format(avgOrderValue)}',
        icon: Icons.shopping_cart,
        iconColor: Color(0xFF15803D),
        tint: Color(0xFF15803D).withValues(alpha: 0.1),
        valueColor: Color(0xFF15803D),
      ),
      MetricData(
        title: 'Gross Margin',
        value: grossMargin != null ? '${grossMargin.toStringAsFixed(1)}%' : '—',
        icon: Icons.trending_up,
        iconColor: grossMargin != null && grossMargin > 20
            ? Color(0xFF111111)
            : AppColors.ink,
        tint: (grossMargin != null && grossMargin > 20
                ? Color(0xFF111111)
                : AppColors.ink)
            .withValues(alpha: 0.1),
        valueColor: grossMargin != null && grossMargin > 20
            ? Color(0xFF111111)
            : AppColors.ink,
      ),
    ];
  }

  List<Widget> _buildSections(
    BuildContext context,
    ReportTable table,
    PosReportData data,
    DateTimeRange? range,
  ) {
    final store = context.read<PosLocalStore>();
    final sales = _getSalesInRange(store, range);

    return [
      _buildSalesTrendCard(context, sales, range),
      _buildInsightsCard(context, sales, table),
    ];
  }

  Widget _buildSalesTrendCard(
    BuildContext context,
    List<_Sale> sales,
    DateTimeRange? range,
  ) {
    final dailySales = _groupByDay(sales);
    final trendPoints = dailySales.entries
        .map((e) => TrendPoint(
              label: DateFormat('MMM d').format(e.key),
              value: e.value.fold(0.0, (sum, s) => sum + s.order.total),
              displayValue:
                  'TSh ${NumberFormat('#,##0').format(e.value.fold(0.0, (sum, s) => sum + s.order.total))}',
            ))
        .toList();
    final maxValue = trendPoints.isEmpty
        ? 0.0
        : trendPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      title: context.tr('Daily Sales Trend'),
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: context.tr('Sales'),
        color: Color(0xFF166534),
      ),
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    List<_Sale> sales,
    ReportTable table,
  ) {
    if (sales.isEmpty) return const SizedBox.shrink();

    final insights = <InsightCard>[];

    final totalSales = sales.fold(0.0, (sum, s) => sum + s.order.total);
    final avgOrder = totalSales / sales.length;
    final creditSales = sales.where((s) => s.isCredit).length;
    final creditRatio = sales.isEmpty ? 0.0 : creditSales / sales.length;

    final topDay = _groupByDay(sales).entries.reduce(
          (a, b) => a.value.fold(0.0, (sum, s) => sum + s.order.total) >
                  b.value.fold(0.0, (sum, s) => sum + s.order.total)
              ? a
              : b,
        );

    insights.add(InsightCard(
      title: context.tr('Peak Sales Day'),
      description:
          context.tr('Highest sales on {p0} with TSh {p1}', args: {'p0': DateFormat('EEEE, MMM d').format(topDay.key), 'p1': NumberFormat('#,##0').format(topDay.value.fold(0.0, (sum, s) => sum + s.order.total))}),
      icon: Icons.calendar_today,
      color: Color(0xFF166534),
      severity: InsightSeverity.info,
    ));

    if (creditRatio > 0.3) {
      insights.add(InsightCard(
        title: context.tr('High Credit Sales'),
        description:
            context.tr('{p0}% of sales are on credit. Consider follow-up on outstanding balances.', args: {'p0': (creditRatio * 100).toStringAsFixed(1)}),
        icon: Icons.credit_card,
        color: Color(0xFF15803D),
        severity: InsightSeverity.warning,
        actionLabel: 'View Balances',
        onAction: () => Navigator.of(context).pushNamed('/reports/balances'),
      ));
    }

    if (avgOrder < 500) {
      insights.add(InsightCard(
        title: context.tr('Low Average Order Value'),
        description:
            context.tr('Average order is TSh {p0}. Consider upselling or bundle offers.', args: {'p0': NumberFormat('#,##0').format(avgOrder)}),
        icon: Icons.shopping_bag,
        color: Color(0xFF15803D),
        severity: InsightSeverity.info,
        actionLabel: 'View Items Report',
        onAction: () => Navigator.of(context).pushNamed('/reports/items'),
      ));
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: context.tr('Insights'),
      child: Column(children: insights),
    );
  }

  List<_Sale> _getSalesInRange(PosLocalStore store, DateTimeRange? range) {
    return _salesInRange(store.orders, range?.start, range?.end);
  }
}

class _Sale {
  _Sale(this.order, this.date)
      : gross =
            order.lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  final CompletedOrder order;
  final DateTime date;
  final double gross;

  String get customer => _label(order.customerName, 'Unrecorded customer');
  String get discountLabel =>
      _label(order.discountLabel, 'Unlabelled discount');
  double get discount =>
      order.discountAmount ??
      (gross - order.total).clamp(0.0, double.infinity).toDouble();
  bool get isCredit => order.paymentMethod.trim().toLowerCase() == 'credit';
  int get quantity => order.lines.fold(0, (sum, line) => sum + line.quantity);
}

String _label(String? value, String fallback) {
  final label = value?.trim();
  return label == null || label.isEmpty ? fallback : label;
}

Map<DateTime, List<_Sale>> _groupByDay(Iterable<_Sale> sales) {
  final groups = <DateTime, List<_Sale>>{};
  for (final sale in sales) {
    final day = DateTime(sale.date.year, sale.date.month, sale.date.day);
    groups.putIfAbsent(day, () => []).add(sale);
  }
  return groups;
}

List<_Sale> _salesInRange(
  List<CompletedOrder> orders,
  DateTime? start,
  DateTime? end,
) {
  final sales = <_Sale>[];
  for (final order in orders) {
    if (order.status.trim().toLowerCase() != 'completed') continue;
    final date = DateTime.tryParse(order.dateTime)?.toLocal();
    if (date != null && _inRange(date, start, end)) {
      sales.add(_Sale(order, date));
    }
  }
  return sales;
}

bool _inRange(DateTime date, DateTime? start, DateTime? end) {
  final day = DateTime(date.year, date.month, date.day);
  return (start == null || !day.isBefore(start)) &&
      (end == null || !day.isAfter(end));
}
