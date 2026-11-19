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

class EmployeesReportPage extends StatelessWidget {
  const EmployeesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Employees Summary',
        ReportGroup.summary,
        ReportData.employees,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalEmployees = table.rows.length;
    final totalSales = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final totalOrders =
        table.rows.fold<int>(0, (sum, row) => sum + (row[1] as int));
    final avgSalesPerEmployee =
        totalEmployees > 0 ? totalSales / totalEmployees : 0.0;
    final avgOrdersPerEmployee =
        totalEmployees > 0 ? totalOrders / totalEmployees : 0.0;

    return [
      MetricData(
        title: 'Active Employees',
        value: NumberFormat('#,###').format(totalEmployees),
        icon: Icons.badge,
        iconColor: Color(0xFF166534),
        tint: Color(0xFF166534).withValues(alpha: 0.1),
        valueColor: Color(0xFF166534),
      ),
      MetricData(
        title: 'Total Sales',
        value: 'TSh ${NumberFormat('#,##0.##').format(totalSales)}',
        icon: Icons.attach_money,
        iconColor: Color(0xFF111111),
        tint: Color(0xFF111111).withValues(alpha: 0.1),
        valueColor: Color(0xFF111111),
      ),
      MetricData(
        title: 'Avg Sales/Employee',
        value: 'TSh ${NumberFormat('#,##0.##').format(avgSalesPerEmployee)}',
        icon: Icons.analytics,
        iconColor: Color(0xFF15803D),
        tint: Color(0xFF15803D).withValues(alpha: 0.1),
        valueColor: Color(0xFF15803D),
      ),
      MetricData(
        title: 'Avg Orders/Employee',
        value: NumberFormat('#,##0.#').format(avgOrdersPerEmployee),
        icon: Icons.receipt_long,
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
    final staffMembers = _getStaffMembers(store);

    return [
      _buildEmployeePerformanceCard(context, table),
      _buildEmployeeShiftCard(staffMembers),
      _buildInsightsCard(context, table),
    ];
  }

  Widget _buildEmployeePerformanceCard(
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
      title: 'Sales by Employee',
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: 'Sales',
        color: Color(0xFF166534),
      ),
    );
  }

  Widget _buildEmployeeShiftCard(List<Map<String, Object?>> staffMembers) {
    if (staffMembers.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Team Overview',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TeamStat(
                  label: 'Total Staff',
                  value: NumberFormat('#,###').format(staffMembers.length),
                  icon: Icons.people,
                  color: Color(0xFF166534),
                ),
              ),
              Expanded(
                child: _TeamStat(
                  label: 'Roles',
                  value: NumberFormat('#,###').format(
                    staffMembers.map((m) => m['role_id']).toSet().length,
                  ),
                  icon: Icons.work_outline,
                  color: Color(0xFF15803D),
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

    final topEmployee = table.rows.first;
    final topEmployeeName = topEmployee[0].toString();
    final topEmployeeSales = (topEmployee[3] as num).toDouble();
    final totalSales = table.rows
        .fold<double>(0, (sum, row) => sum + (row[3] as num).toDouble());
    final topEmployeeShare =
        totalSales > 0 ? (topEmployeeSales / totalSales) * 100 : 0.0;

    insights.add(InsightCard(
      title: 'Top Performer',
      description:
          '$topEmployeeName generates ${topEmployeeShare.toStringAsFixed(1)}% of total sales (TSh ${NumberFormat('#,##0').format(topEmployeeSales)})',
      icon: Icons.emoji_events,
      color: Color(0xFF15803D),
      severity: InsightSeverity.success,
    ));

    final avgSales = totalSales / table.rows.length;
    final lowPerformers = table.rows
        .where((row) => (row[3] as num).toDouble() < avgSales * 0.5)
        .length;

    if (lowPerformers > 0) {
      insights.add(InsightCard(
        title: 'Underperforming Staff',
        description:
            '$lowPerformers employees are below 50% of average sales. Consider training or schedule optimization.',
        icon: Icons.trending_down,
        color: AppColors.ink,
        severity: InsightSeverity.warning,
      ));
    }

    return SectionCard(
      title: 'Insights',
      child: Column(children: insights),
    );
  }

  List<Map<String, Object?>> _getStaffMembers(PosLocalStore store) {
    // This would need to be implemented based on the store's data access
    return <Map<String, Object?>>[];
  }
}

class _TeamStat extends StatelessWidget {
  const _TeamStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
