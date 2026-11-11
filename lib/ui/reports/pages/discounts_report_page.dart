import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../enhanced_report_page.dart';
import '../models/report_models.dart';
import '../pos_report_catalog.dart';
import '../pos_report_data.dart';
import '../widgets/section_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/insight_card.dart';

class DiscountsReportPage extends StatelessWidget {
  const DiscountsReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Discounts Summary',
        ReportGroup.summary,
        ReportData.discounts,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalDiscounts = table.rows.fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final totalSales = table.rows.fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final totalDiscountedSales = table.rows.fold<int>(0, (sum, row) => sum + (row[1] as int));
    final discountRate = totalSales > 0 ? (totalDiscounts / totalSales) * 100 : 0.0;
    final discountTypes = table.rows.length;

    return [
      MetricData(
        title: 'Total Discounts Given',
        value: '₹${NumberFormat('#,##0.##').format(totalDiscounts)}',
        icon: Icons.local_offer,
        iconColor: Colors.orange,
        tint: Colors.orange.withValues(alpha: 0.1),
        valueColor: Colors.orange,
      ),
      MetricData(
        title: 'Discount Rate',
        value: '${discountRate.toStringAsFixed(1)}%',
        icon: Icons.percent,
        iconColor: discountRate > 15 ? Colors.red : Colors.green,
        tint: (discountRate > 15 ? Colors.red : Colors.green).withValues(alpha: 0.1),
        valueColor: discountRate > 15 ? Colors.red : Colors.green,
      ),
      MetricData(
        title: 'Discounted Transactions',
        value: NumberFormat('#,###').format(totalDiscountedSales),
        icon: Icons.receipt,
        iconColor: Colors.blue,
        tint: Colors.blue.withValues(alpha: 0.1),
        valueColor: Colors.blue,
      ),
      MetricData(
        title: 'Discount Types Used',
        value: NumberFormat('#,###').format(discountTypes),
        icon: Icons.category,
        iconColor: Colors.indigo,
        tint: Colors.indigo.withValues(alpha: 0.1),
        valueColor: Colors.indigo,
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
      _buildDiscountBreakdownCard(context, table),
      _buildDiscountImpactCard(table),
      _buildInsightsCard(context, table),
    ];
  }

  Widget _buildDiscountBreakdownCard(BuildContext context, ReportTable table) {
    final trendPoints = table.rows
        .map((row) => TrendPoint(
              label: row[0].toString(),
              value: (row[2] as num).toDouble(),
              displayValue: '₹${NumberFormat('#,##0').format((row[2] as num).toDouble())}',
            ))
        .toList();
    final maxValue = trendPoints.isEmpty ? 0.0 : trendPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      title: 'Discounts by Type',
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: 'Discount Amount',
        color: Colors.orange,
      ),
    );
  }

  Widget _buildDiscountImpactCard(ReportTable table) {
    final totalDiscounts = table.rows.fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final totalSales = table.rows.fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final avgDiscountPerSale = table.rows.isNotEmpty
        ? totalDiscounts / table.rows.fold<int>(0, (sum, row) => sum + (row[1] as int))
        : 0.0;

    return SectionCard(
      title: 'Discount Impact Analysis',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DiscountStat(
                  label: 'Total Discount Value',
                  value: '₹${NumberFormat('#,##0').format(totalDiscounts)}',
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _DiscountStat(
                  label: 'Discount Rate',
                  value: totalSales > 0
                      ? '${((totalDiscounts / totalSales) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  color: totalSales > 0 && (totalDiscounts / totalSales) > 0.15
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              Expanded(
                child: _DiscountStat(
                  label: 'Avg Discount/Sale',
                  value: '₹${NumberFormat('#,##0.##').format(avgDiscountPerSale)}',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (totalDiscounts > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Discounts reduce gross margin. Track discount effectiveness by comparing '
                      'discounted vs non-discounted sales conversion.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, ReportTable table) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final insights = <InsightCard>[];

    final topDiscount = table.rows.first;
    final topDiscountName = topDiscount[0].toString();
    final topDiscountAmount = (topDiscount[2] as num).toDouble();
    final totalDiscounts = table.rows.fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final topDiscountShare = totalDiscounts > 0 ? (topDiscountAmount / totalDiscounts) * 100 : 0.0;

    insights.add(InsightCard(
      title: 'Most Used Discount',
      description: '"$topDiscountName" represents ${topDiscountShare.toStringAsFixed(1)}% of all discounts (₹${NumberFormat('#,##0').format(topDiscountAmount)})',
      icon: Icons.local_offer,
      color: Colors.orange,
      severity: InsightSeverity.info,
    ));

    final totalSales = table.rows.fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final discountRate = totalSales > 0 ? (totalDiscounts / totalSales) * 100 : 0.0;

    if (discountRate > 20) {
      insights.add(InsightCard(
        title: 'High Discount Rate',
        description: 'Discounts exceed 20% of sales. Evaluate if discounts are driving volume or eroding margins.',
        icon: Icons.trending_down,
        color: Colors.red,
        severity: InsightSeverity.warning,
      ));
    }

    return SectionCard(
      title: 'Insights',
      child: Column(children: insights),
    );
  }
}

class _DiscountStat extends StatelessWidget {
  const _DiscountStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}