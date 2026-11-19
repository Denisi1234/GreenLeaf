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

class PaymentsReportPage extends StatelessWidget {
  const PaymentsReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Payments Summary',
        ReportGroup.summary,
        ReportData.payments,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalCollected = table.rows
        .fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final totalCredit = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final totalTransactions =
        table.rows.fold<int>(0, (sum, row) => sum + (row[1] as int));
    final paymentMethods = table.rows.length;

    return [
      MetricData(
        title: 'Total Collected',
        value: 'TSh ${NumberFormat('#,##0.##').format(totalCollected)}',
        icon: Icons.attach_money,
        iconColor: Color(0xFF111111),
        tint: Color(0xFF111111).withValues(alpha: 0.1),
        valueColor: Color(0xFF111111),
      ),
      MetricData(
        title: 'Credit Sales',
        value: 'TSh ${NumberFormat('#,##0.##').format(totalCredit)}',
        icon: Icons.credit_card,
        iconColor: AppColors.ink,
        tint: AppColors.ink.withValues(alpha: 0.1),
        valueColor: AppColors.ink,
      ),
      MetricData(
        title: 'Total Transactions',
        value: NumberFormat('#,###').format(totalTransactions),
        icon: Icons.receipt,
        iconColor: Color(0xFF15803D),
        tint: Color(0xFF15803D).withValues(alpha: 0.1),
        valueColor: Color(0xFF15803D),
      ),
      MetricData(
        title: 'Payment Methods',
        value: NumberFormat('#,###').format(paymentMethods),
        icon: Icons.payment,
        iconColor: Color(0xFF166534),
        tint: Color(0xFF166534).withValues(alpha: 0.1),
        valueColor: Color(0xFF166534),
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
      _buildPaymentMethodCard(context, table),
      _buildCollectionEfficiencyCard(table),
      _buildInsightsCard(context, table),
    ];
  }

  Widget _buildPaymentMethodCard(BuildContext context, ReportTable table) {
    final trendPoints = table.rows
        .map((row) => TrendPoint(
              label: row[0].toString(),
              value: (row[2] as num).toDouble(),
              displayValue:
                  'TSh ${NumberFormat('#,##0').format((row[2] as num).toDouble())}',
            ))
        .toList();
    final maxValue = trendPoints.isEmpty
        ? 0.0
        : trendPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      title: 'Collected by Payment Method',
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: 'Collected',
        color: Color(0xFF111111),
      ),
    );
  }

  Widget _buildCollectionEfficiencyCard(ReportTable table) {
    final totalCollected = table.rows
        .fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final totalCredit = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final totalSales = totalCollected + totalCredit;
    final collectionRate =
        totalSales > 0 ? (totalCollected / totalSales) * 100 : 100.0;

    return SectionCard(
      title: 'Collection Efficiency',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection Rate',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${collectionRate.toStringAsFixed(1)}%',
                      style: GoogleFonts.manrope(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: collectionRate >= 90
                            ? Color(0xFF111111)
                            : collectionRate >= 70
                                ? AppColors.ink
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collectionRate >= 90
                          ? 'Excellent collection rate'
                          : collectionRate >= 70
                              ? 'Moderate - monitor credit customers'
                              : 'Low - immediate action needed',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CircularProgressIndicator(
                value: (collectionRate / 100).clamp(0.0, 1.0),
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  collectionRate >= 90
                      ? Color(0xFF111111)
                      : collectionRate >= 70
                          ? AppColors.ink
                          : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PaymentStat(
                  label: 'Collected',
                  value: 'TSh ${NumberFormat('#,##0').format(totalCollected)}',
                  color: Color(0xFF111111),
                ),
              ),
              Expanded(
                child: _PaymentStat(
                  label: 'On Credit',
                  value: 'TSh ${NumberFormat('#,##0').format(totalCredit)}',
                  color: AppColors.ink,
                ),
              ),
              Expanded(
                child: _PaymentStat(
                  label: 'Total Sales',
                  value: 'TSh ${NumberFormat('#,##0').format(totalSales)}',
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, ReportTable table) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final insights = <InsightCard>[];

    final topMethod = table.rows.first;
    final topMethodName = topMethod[0].toString();
    final topMethodCollected = (topMethod[2] as num).toDouble();
    final totalCollected = table.rows
        .fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final topMethodShare =
        totalCollected > 0 ? (topMethodCollected / totalCollected) * 100 : 0.0;

    insights.add(InsightCard(
      title: 'Preferred Payment Method',
      description:
          '$topMethodName accounts for ${topMethodShare.toStringAsFixed(1)}% of collections (TSh ${NumberFormat('#,##0').format(topMethodCollected)})',
      icon: Icons.payment,
      color: Color(0xFF166534),
      severity: InsightSeverity.info,
    ));

    final totalCredit = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    if (totalCredit > totalCollected) {
      insights.add(InsightCard(
        title: 'Credit Exceeds Collections',
        description:
            'Credit sales (TSh ${NumberFormat('#,##0').format(totalCredit)}) exceed collected payments (TSh ${NumberFormat('#,##0').format(totalCollected)}). Review credit policies.',
        icon: Icons.warning,
        color: Colors.red,
        severity: InsightSeverity.critical,
        actionLabel: 'View Credit Sales',
        onAction: () =>
            Navigator.of(context).pushNamed('/reports/credit_sales'),
      ));
    }

    return SectionCard(
      title: 'Insights',
      child: Column(children: insights),
    );
  }
}

class _PaymentStat extends StatelessWidget {
  const _PaymentStat({
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
