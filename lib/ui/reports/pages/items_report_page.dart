import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../enhanced_report_page.dart';
import '../models/report_models.dart';
import '../pos_report_catalog.dart';
import '../pos_report_data.dart';
import '../services/report_data_service.dart';
import '../widgets/section_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/comparison_card.dart';
import '../widgets/insight_card.dart';

class ItemsReportPage extends StatelessWidget {
  const ItemsReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Items Summary',
        ReportGroup.summary,
        ReportData.items,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalUnits = table.rows.fold<int>(0, (sum, row) => sum + (row[2] as int));
    final totalNetSales = table.rows.fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final totalCost = table.rows.fold<double>(0, (sum, row) {
      final c = row[4];
      return sum + (c is num ? c.toDouble() : 0.0);
    });
    final totalProfit = totalCost > 0 ? totalNetSales - totalCost : null;
    final uniqueItems = table.rows.length;

    return [
      MetricData(
        title: 'Unique Items Sold',
        value: NumberFormat('#,###').format(uniqueItems),
        icon: Icons.inventory_2,
        iconColor: Colors.indigo,
        tint: Colors.indigo.withValues(alpha: 0.1),
        valueColor: Colors.indigo,
      ),
      MetricData(
        title: 'Total Units Sold',
        value: NumberFormat('#,###').format(totalUnits),
        icon: Icons.shopping_basket,
        iconColor: Colors.blue,
        tint: Colors.blue.withValues(alpha: 0.1),
        valueColor: Colors.blue,
      ),
      MetricData(
        title: 'Total Revenue',
        value: '₹${NumberFormat('#,##0.##').format(totalNetSales)}',
        icon: Icons.attach_money,
        iconColor: Colors.green,
        tint: Colors.green.withValues(alpha: 0.1),
        valueColor: Colors.green,
      ),
      MetricData(
        title: 'Gross Profit',
        value: totalProfit != null ? '₹${NumberFormat('#,##0.##').format(totalProfit)}' : '—',
        icon: Icons.trending_up,
        iconColor: totalProfit != null && totalProfit > 0 ? Colors.green : Colors.red,
        tint: (totalProfit != null && totalProfit > 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
        valueColor: totalProfit != null && totalProfit > 0 ? Colors.green : Colors.red,
      ),
    ];
  }

  List<Widget> _buildSections(
    BuildContext context,
    ReportTable table,
    PosReportData data,
    DateTimeRange? range,
  ) {
    return [
      _buildTopProductsCard(context, table),
      _buildInsightsCard(context, table),
    ];
  }

  Widget _buildTopProductsCard(BuildContext context, ReportTable table) {
    final topProducts = table.rows.take(10).toList();
    final trendPoints = topProducts
        .map((row) => TrendPoint(
              label: row[0].toString(),
              value: (row[3] as num).toDouble(),
              displayValue: '₹${NumberFormat('#,##0').format((row[3] as num).toDouble())}',
            ))
        .toList();
    final maxValue = trendPoints.isEmpty ? 0.0 : trendPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      title: 'Top 10 Products by Revenue',
      trailing: TextButton(
        onPressed: () {},
        child: const Text('View All'),
      ),
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: 'Revenue',
        color: Colors.indigo,
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, ReportTable table) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final insights = <InsightCard>[];

    final topProduct = table.rows.first;
    final topProductName = topProduct[0].toString();
    final topProductRevenue = (topProduct[3] as num).toDouble();
    final totalRevenue = table.rows.fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final topProductShare = totalRevenue > 0 ? (topProductRevenue / totalRevenue) * 100 : 0.0;

    insights.add(InsightCard(
      title: 'Top Performer',
      description: '"$topProductName" generates ${topProductShare.toStringAsFixed(1)}% of total revenue (₹${NumberFormat('#,##0').format(topProductRevenue)})',
      icon: Icons.star,
      color: Colors.amber,
      severity: InsightSeverity.success,
    ));

    final lowMarginItems = table.rows.where((row) {
      final cost = row[4];
      final revenue = (row[3] as num).toDouble();
      if (cost is num && cost > 0 && revenue > 0) {
        final margin = ((revenue - cost) / revenue) * 100;
        return margin < 15;
      }
      return false;
    }).length;

    if (lowMarginItems > 0) {
      insights.add(InsightCard(
        title: 'Low Margin Items',
        description: '$lowMarginItems items have gross margin below 15%. Review pricing or supplier costs.',
        icon: Icons.warning_amber,
        color: Colors.red,
        severity: InsightSeverity.warning,
        actionLabel: 'Review Pricing',
        onAction: () {},
      ));
    }

    final zeroCostItems = table.rows.where((row) => row[4] == null).length;
    if (zeroCostItems > 0) {
      insights.add(InsightCard(
        title: 'Missing Cost Data',
        description: '$zeroCostItems items have no unit cost recorded. Profit calculations will be incomplete.',
        icon: Icons.receipt_long,
        color: Colors.blue,
        severity: InsightSeverity.info,
        actionLabel: 'Update Costs',
        onAction: () {},
      ));
    }

    return SectionCard(
      title: 'Insights',
      child: Column(children: insights),
    );
  }
}