import 'package:track_mauzo/l10n/app_localization.dart';
import '../../widgets/app_design.dart';
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

class CategoriesReportPage extends StatelessWidget {
  const CategoriesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Categories Summary',
        ReportGroup.summary,
        ReportData.categories,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalUnits =
        table.rows.fold<int>(0, (sum, row) => sum + (row[2] as int));
    final totalNetSales = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final totalCost = table.rows.fold<double>(0, (sum, row) {
      final c = row[4];
      return sum + (c is num ? c.toDouble() : 0.0);
    });
    final totalProfit = totalCost > 0 ? totalNetSales - totalCost : null;
    final uniqueCategories = table.rows.length;

    return [
      MetricData(
        title: 'Active Categories',
        value: NumberFormat('#,###').format(uniqueCategories),
        icon: Icons.category,
        iconColor: Color(0xFF166534),
        tint: Color(0xFF166534).withValues(alpha: 0.1),
        valueColor: Color(0xFF166534),
      ),
      MetricData(
        title: 'Total Units',
        value: NumberFormat('#,###').format(totalUnits),
        icon: Icons.inventory,
        iconColor: Color(0xFF15803D),
        tint: Color(0xFF15803D).withValues(alpha: 0.1),
        valueColor: Color(0xFF15803D),
      ),
      MetricData(
        title: 'Category Revenue',
        value: 'TSh ${NumberFormat('#,##0.##').format(totalNetSales)}',
        icon: Icons.attach_money,
        iconColor: Color(0xFF111111),
        tint: Color(0xFF111111).withValues(alpha: 0.1),
        valueColor: Color(0xFF111111),
      ),
      MetricData(
        title: 'Gross Profit',
        value: totalProfit != null
            ? 'TSh ${NumberFormat('#,##0.##').format(totalProfit)}'
            : '—',
        icon: Icons.trending_up,
        iconColor: totalProfit != null && totalProfit < 0
            ? AppColors.danger
            : AppColors.ink,
        tint: (totalProfit != null && totalProfit < 0
                ? AppColors.danger
                : AppColors.ink)
            .withValues(alpha: 0.1),
        valueColor: totalProfit != null && totalProfit < 0
            ? AppColors.danger
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
    return [
      _buildCategoryPerformanceCard(context, table),
      _buildInsightsCard(context, table),
    ];
  }

  Widget _buildCategoryPerformanceCard(
      BuildContext context, ReportTable table) {
    final trendPoints = table.rows
        .map((row) => TrendPoint(
              label: row[0].toString(),
              value: (row[3] as num).toDouble(),
              displayValue:
                  'TSh ${NumberFormat('#,##0').format((row[3] as num).toDouble())}',
            ))
        .toList();
    final maxValue = trendPoints.isEmpty
        ? 0.0
        : trendPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      title: context.tr('Revenue by Category'),
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: context.tr('Revenue'),
        color: Color(0xFF166534),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, ReportTable table) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final insights = <InsightCard>[];

    final topCategory = table.rows.first;
    final topCategoryName = topCategory[0].toString();
    final topCategoryRevenue = (topCategory[3] as num).toDouble();
    final totalRevenue = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final topCategoryShare =
        totalRevenue > 0 ? (topCategoryRevenue / totalRevenue) * 100 : 0.0;

    insights.add(InsightCard(
      title: context.tr('Leading Category'),
      description:
          context.tr('"{p0}" contributes {p1}% of total revenue (TSh {p2})', args: {'p0': topCategoryName, 'p1': topCategoryShare.toStringAsFixed(1), 'p2': NumberFormat('#,##0').format(topCategoryRevenue)}),
      icon: Icons.category,
      color: Color(0xFF166534),
      severity: InsightSeverity.success,
    ));

    final lowPerformers = table.rows.where((row) {
      final revenue = (row[3] as num).toDouble();
      return revenue < (totalRevenue / table.rows.length) * 0.1;
    }).length;

    if (lowPerformers > 0 && table.rows.length > 3) {
      insights.add(InsightCard(
        title: context.tr('Underperforming Categories'),
        description:
            context.tr('{p0} categories generate less than 10% of average revenue. Consider promotions or reassortment.', args: {'p0': lowPerformers}),
        icon: Icons.trending_down,
        color: AppColors.ink,
        severity: InsightSeverity.warning,
      ));
    }

    return SectionCard(
      title: context.tr('Insights'),
      child: Column(children: insights),
    );
  }
}
