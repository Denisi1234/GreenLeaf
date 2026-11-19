import '../../widgets/app_design.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../enhanced_report_page.dart';
import '../../../ui/models/customer_data.dart';
import '../models/report_models.dart';
import '../pos_report_catalog.dart';
import '../pos_report_data.dart';
import '../services/report_data_service.dart';
import '../widgets/section_card.dart';
import '../widgets/comparison_card.dart';
import '../widgets/insight_card.dart';

class CustomersReportPage extends StatelessWidget {
  const CustomersReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Customers Summary',
        ReportGroup.summary,
        ReportData.customers,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalCustomers = table.rows.length;
    final totalSales = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final avgPerCustomer =
        totalCustomers > 0 ? totalSales / totalCustomers : 0.0;
    final topCustomerSales =
        table.rows.isNotEmpty ? (table.rows.first[3] as num).toDouble() : 0.0;

    return [
      MetricData(
        title: 'Active Customers',
        value: NumberFormat('#,###').format(totalCustomers),
        icon: Icons.people,
        iconColor: Color(0xFF166534),
        tint: Color(0xFF166534).withValues(alpha: 0.1),
        valueColor: Color(0xFF166534),
      ),
      MetricData(
        title: 'Total Customer Sales',
        value: 'TSh ${NumberFormat('#,##0.##').format(totalSales)}',
        icon: Icons.attach_money,
        iconColor: Color(0xFF111111),
        tint: Color(0xFF111111).withValues(alpha: 0.1),
        valueColor: Color(0xFF111111),
      ),
      MetricData(
        title: 'Avg per Customer',
        value: 'TSh ${NumberFormat('#,##0.##').format(avgPerCustomer)}',
        icon: Icons.analytics,
        iconColor: Color(0xFF15803D),
        tint: Color(0xFF15803D).withValues(alpha: 0.1),
        valueColor: Color(0xFF15803D),
      ),
      MetricData(
        title: 'Top Customer',
        value: 'TSh ${NumberFormat('#,##0.##').format(topCustomerSales)}',
        icon: Icons.star,
        iconColor: Color(0xFF15803D),
        tint: Color(0xFF15803D).withValues(alpha: 0.1),
        valueColor: Color(0xFF15803D),
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
    final customers = store.customers;
    final creditCustomers = customers.where((c) => c.debitBalance > 0).length;
    final totalCreditBalance = customers
        .where((c) => c.debitBalance > 0)
        .fold<double>(0, (sum, c) => sum + c.debitBalance);

    return [
      _buildCustomerSegmentCard(customers, creditCustomers, totalCreditBalance),
      _buildInsightsCard(context, table, creditCustomers, totalCreditBalance),
    ];
  }

  Widget _buildCustomerSegmentCard(
    List<CustomerData> customers,
    int creditCustomers,
    double totalCreditBalance,
  ) {
    final totalCustomers = customers.length;
    final cashCustomers = totalCustomers - creditCustomers;

    return SectionCard(
      title: 'Customer Segments',
      child: Row(
        children: [
          Expanded(
            child: _SegmentStat(
              label: 'Cash Customers',
              value: NumberFormat('#,###').format(cashCustomers),
              percentage: totalCustomers > 0
                  ? (cashCustomers / totalCustomers) * 100
                  : 0,
              color: Color(0xFF111111),
              icon: Icons.payments,
            ),
          ),
          Expanded(
            child: _SegmentStat(
              label: 'Credit Customers',
              value: NumberFormat('#,###').format(creditCustomers),
              percentage: totalCustomers > 0
                  ? (creditCustomers / totalCustomers) * 100
                  : 0,
              color: AppColors.ink,
              icon: Icons.credit_card,
            ),
          ),
          Expanded(
            child: _SegmentStat(
              label: 'Outstanding Credit',
              value: 'TSh ${NumberFormat('#,##0').format(totalCreditBalance)}',
              percentage: 0,
              color: AppColors.ink,
              icon: Icons.account_balance_wallet,
              showPercentage: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    ReportTable table,
    int creditCustomers,
    double totalCreditBalance,
  ) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final insights = <InsightCard>[];

    final topCustomer = table.rows.first;
    final topCustomerName = topCustomer[0].toString();
    final topCustomerSales = (topCustomer[3] as num).toDouble();
    final totalSales = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final topCustomerShare =
        totalSales > 0 ? (topCustomerSales / totalSales) * 100 : 0.0;

    insights.add(InsightCard(
      title: 'Top Customer',
      description:
          '$topCustomerName contributes ${topCustomerShare.toStringAsFixed(1)}% of customer sales (TSh ${NumberFormat('#,##0').format(topCustomerSales)})',
      icon: Icons.person,
      color: Color(0xFF166534),
      severity: InsightSeverity.success,
    ));

    if (creditCustomers > 0) {
      insights.add(InsightCard(
        title: 'Outstanding Receivables',
        description:
            '$creditCustomers customers owe TSh ${NumberFormat('#,##0').format(totalCreditBalance)}. Regular follow-up recommended.',
        icon: Icons.money_off,
        color: Colors.red,
        severity: totalCreditBalance > 10000
            ? InsightSeverity.critical
            : InsightSeverity.warning,
        actionLabel: 'View Balances',
        onAction: () => Navigator.of(context).pushNamed('/reports/balances'),
      ));
    }

    if (table.rows.length < 10) {
      insights.add(InsightCard(
        title: 'Small Customer Base',
        description:
            'Only ${table.rows.length} active customers. Focus on customer acquisition and retention.',
        icon: Icons.group_add,
        color: Color(0xFF15803D),
        severity: InsightSeverity.info,
      ));
    }

    return SectionCard(
      title: 'Insights',
      child: Column(children: insights),
    );
  }
}

class _SegmentStat extends StatelessWidget {
  const _SegmentStat({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
    required this.icon,
    this.showPercentage = true,
  });

  final String label;
  final String value;
  final double percentage;
  final Color color;
  final IconData icon;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 4),
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
