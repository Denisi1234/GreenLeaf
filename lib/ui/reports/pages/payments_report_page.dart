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
      _buildCollectionEfficiencyCard(context, table),
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
      title: context.tr('Collected by Payment Method'),
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: context.tr('Collected'),
        color: Color(0xFF111111),
      ),
    );
  }

  Widget _buildCollectionEfficiencyCard(BuildContext context, ReportTable table) {
    final totalCollected = table.rows
        .fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final totalCredit = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final totalSales = totalCollected + totalCredit;
    final collectionRate =
        totalSales > 0 ? (totalCollected / totalSales) * 100 : 100.0;

    return SectionCard(
      title: context.tr('Collection Efficiency'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Collection Rate'),
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
                          ? context.tr('Excellent collection rate')
                          : collectionRate >= 70
                              ? context.tr('Moderate - monitor credit customers')
                              : context.tr('Low - immediate action needed'),
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
                  label: context.tr('Collected'),
                  value: 'TSh ${NumberFormat('#,##0').format(totalCollected)}',
                  color: Color(0xFF111111),
                ),
              ),
              Expanded(
                child: _PaymentStat(
                  label: context.tr('On Credit'),
                  value: 'TSh ${NumberFormat('#,##0').format(totalCredit)}',
                  color: AppColors.ink,
                ),
              ),
              Expanded(
                child: _PaymentStat(
                  label: context.tr('Total Sales'),
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
      title: context.tr('Preferred Payment Method'),
      description:
          context.tr('{p0} accounts for {p1}% of collections (TSh {p2})', args: {'p0': topMethodName, 'p1': topMethodShare.toStringAsFixed(1), 'p2': NumberFormat('#,##0').format(topMethodCollected)}),
      icon: Icons.payment,
      color: Color(0xFF166534),
      severity: InsightSeverity.info,
    ));

    final totalCredit = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    if (totalCredit > totalCollected) {
      insights.add(InsightCard(
        title: context.tr('Credit Exceeds Collections'),
        description:
            context.tr('Credit sales (TSh {p0}) exceed collected payments (TSh {p1}). Review credit policies.', args: {'p0': NumberFormat('#,##0').format(totalCredit), 'p1': NumberFormat('#,##0').format(totalCollected)}),
        icon: Icons.warning,
        color: Colors.red,
        severity: InsightSeverity.critical,
        actionLabel: 'View Credit Sales',
        onAction: () =>
            Navigator.of(context).pushNamed('/reports/credit_sales'),
      ));
    }

    return SectionCard(
      title: context.tr('Insights'),
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
          context.tr(label),
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
