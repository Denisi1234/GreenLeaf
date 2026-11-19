import '../../widgets/app_design.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../service/expense_model.dart';
import '../../../service/pos_order_models.dart';
import '../enhanced_report_page.dart'
    show EnhancedReportPage, MetricData, ExportFormat;
import '../models/report_models.dart';
import '../pos_report_catalog.dart';
import '../pos_report_data.dart' show PosReportData, ReportColumn, ReportTable;
import '../services/report_data_service.dart';
import '../widgets/section_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/comparison_card.dart';
import '../widgets/insight_card.dart';

class ProfitLossReportPage extends StatelessWidget {
  const ProfitLossReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Financial Statement (P&L)',
        ReportGroup.accounting,
        ReportData.profitLoss,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    double revenue = 0,
        cogs = 0,
        grossProfit = 0,
        expenses = 0,
        operatingResult = 0;

    for (final row in table.rows) {
      final label = row[0].toString();
      final amount = (row[1] as num?)?.toDouble() ?? 0;
      switch (label) {
        case 'Net sales':
          revenue = amount;
          break;
        case 'Cost of goods sold':
          cogs = amount;
          break;
        case 'Gross profit':
          grossProfit = amount;
          break;
        case 'Recorded expenses':
          expenses = amount;
          break;
        case 'Operating result':
          operatingResult = amount;
          break;
      }
    }

    final grossMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;
    final operatingMargin =
        revenue > 0 ? (operatingResult / revenue) * 100 : 0.0;
    final expenseRatio = revenue > 0 ? (expenses / revenue) * 100 : 0.0;

    return [
      MetricData(
        title: 'Revenue',
        value: 'TSh ${NumberFormat('#,##0.##').format(revenue)}',
        icon: Icons.attach_money,
        iconColor: Color(0xFF166534),
        tint: Color(0xFF166534).withValues(alpha: 0.1),
        valueColor: Color(0xFF166534),
      ),
      MetricData(
        title: 'Gross Profit',
        value: 'TSh ${NumberFormat('#,##0.##').format(grossProfit)}',
        icon: Icons.trending_up,
        iconColor: grossProfit >= 0 ? Color(0xFF111111) : Colors.red,
        tint: (grossProfit >= 0 ? Color(0xFF111111) : Colors.red)
            .withValues(alpha: 0.1),
        valueColor: grossProfit >= 0 ? Color(0xFF111111) : Colors.red,
      ),
      MetricData(
        title: 'Operating Result',
        value: 'TSh ${NumberFormat('#,##0.##').format(operatingResult)}',
        icon: Icons.account_balance,
        iconColor: operatingResult >= 0 ? Color(0xFF111111) : Colors.red,
        tint: (operatingResult >= 0 ? Color(0xFF111111) : Colors.red)
            .withValues(alpha: 0.1),
        valueColor: operatingResult >= 0 ? Color(0xFF111111) : Colors.red,
      ),
      MetricData(
        title: 'Gross Margin',
        value: '${grossMargin.toStringAsFixed(1)}%',
        icon: Icons.percent,
        iconColor: grossMargin >= 30
            ? Color(0xFF111111)
            : grossMargin >= 15
                ? AppColors.ink
                : AppColors.textMuted,
        tint: (grossMargin >= 30
                ? Color(0xFF111111)
                : grossMargin >= 15
                    ? AppColors.ink
                    : AppColors.textMuted)
            .withValues(alpha: 0.1),
        valueColor: grossMargin >= 30
            ? Color(0xFF111111)
            : grossMargin >= 15
                ? AppColors.ink
                : AppColors.textMuted,
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
    final expenses = _getExpensesInRange(store, range);

    double revenue = 0,
        cogs = 0,
        grossProfit = 0,
        totalExpenses = 0,
        operatingResult = 0;
    for (final row in table.rows) {
      final label = row[0].toString();
      final amount = (row[1] as num?)?.toDouble() ?? 0;
      switch (label) {
        case 'Net sales':
          revenue = amount;
          break;
        case 'Cost of goods sold':
          cogs = amount;
          break;
        case 'Gross profit':
          grossProfit = amount;
          break;
        case 'Recorded expenses':
          totalExpenses = amount;
          break;
        case 'Operating result':
          operatingResult = amount;
          break;
      }
    }

    return [
      _buildPnLStatementCard(table),
      _buildMarginAnalysisCard(
          revenue, cogs, grossProfit, totalExpenses, operatingResult),
      _buildRevenueTrendCard(context, sales),
      _buildExpenseBreakdownCard(context, expenses),
      _buildInsightsCard(
        context,
        revenue,
        cogs,
        grossProfit,
        totalExpenses,
        operatingResult,
      ),
    ];
  }

  Widget _buildPnLStatementCard(ReportTable table) {
    return SectionCard(
      title: 'Profit & Loss Statement',
      child: Column(
        children: [
          for (final row in table.rows) ...[
            _PnLRow(
              label: row[0].toString(),
              value: (row[1] as num?)?.toDouble() ?? 0,
              isTotal: row[0].toString() == 'Gross profit' ||
                  row[0].toString() == 'Operating result',
              isNegative: ((row[1] as num?)?.toDouble() ?? 0) < 0,
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildMarginAnalysisCard(
    double revenue,
    double cogs,
    double grossProfit,
    double expenses,
    double operatingResult,
  ) {
    final grossMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;
    final operatingMargin =
        revenue > 0 ? (operatingResult / revenue) * 100 : 0.0;
    final expenseRatio = revenue > 0 ? (expenses / revenue) * 100 : 0.0;

    return SectionCard(
      title: 'Margin Analysis',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MarginGauge(
                  label: 'Gross Margin',
                  value: grossMargin,
                  benchmark: 30,
                  color: Color(0xFF111111),
                ),
              ),
              Expanded(
                child: _MarginGauge(
                  label: 'Operating Margin',
                  value: operatingMargin,
                  benchmark: 15,
                  color: Color(0xFF15803D),
                ),
              ),
              Expanded(
                child: _MarginGauge(
                  label: 'Expense Ratio',
                  value: expenseRatio,
                  benchmark: 20,
                  color: AppColors.ink,
                  lowerIsBetter: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTrendCard(BuildContext context, List<_Sale> sales) {
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
      title: 'Daily Revenue Trend',
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: 'Revenue',
        color: Color(0xFF166534),
      ),
    );
  }

  Widget _buildExpenseBreakdownCard(
      BuildContext context, List<Expense> expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final expenseByCategory = <String, double>{};
    for (final expense in expenses) {
      expenseByCategory[expense.category] =
          (expenseByCategory[expense.category] ?? 0) + expense.amount;
    }

    final trendPoints = expenseByCategory.entries
        .map((e) => TrendPoint(
              label: e.key,
              value: e.value,
              displayValue: 'TSh ${NumberFormat('#,##0').format(e.value)}',
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = trendPoints.isEmpty ? 0.0 : trendPoints.first.value;

    return SectionCard(
      title: 'Expenses by Category',
      child: TrendChart(
        points: trendPoints.take(8).toList(),
        maxValue: maxValue,
        label: 'Amount',
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    double revenue,
    double cogs,
    double grossProfit,
    double expenses,
    double operatingResult,
  ) {
    final insights = <InsightCard>[];

    final grossMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;
    final operatingMargin =
        revenue > 0 ? (operatingResult / revenue) * 100 : 0.0;

    if (operatingResult < 0) {
      insights.add(InsightCard(
        title: 'Operating Loss',
        description:
            'Business is operating at a loss of TSh ${NumberFormat('#,##0').format(operatingResult.abs())}. Urgent review of pricing, costs, or sales strategy needed.',
        icon: Icons.error_outline,
        color: Colors.red,
        severity: InsightSeverity.critical,
        actionLabel: 'View Expenses',
        onAction: () => Navigator.of(context).pushNamed('/reports/expenses'),
      ));
    } else if (operatingMargin < 10) {
      insights.add(InsightCard(
        title: 'Thin Operating Margin',
        description:
            'Operating margin is ${operatingMargin.toStringAsFixed(1)}%. Focus on cost reduction or price optimization.',
        icon: Icons.warning_amber,
        color: AppColors.ink,
        severity: InsightSeverity.warning,
      ));
    }

    if (grossMargin < 20) {
      insights.add(InsightCard(
        title: 'Low Gross Margin',
        description:
            'Gross margin of ${grossMargin.toStringAsFixed(1)}% is below healthy threshold. Review product pricing and supplier costs.',
        icon: Icons.inventory,
        color: AppColors.ink,
        severity: InsightSeverity.warning,
        actionLabel: 'View Items Report',
        onAction: () => Navigator.of(context).pushNamed('/reports/items'),
      ));
    }

    final expenseRatio = revenue > 0 ? (expenses / revenue) * 100 : 0.0;
    if (expenseRatio > 30) {
      insights.add(InsightCard(
        title: 'High Expense Ratio',
        description:
            'Expenses consume ${expenseRatio.toStringAsFixed(1)}% of revenue. Identify cost savings opportunities.',
        icon: Icons.receipt,
        color: Color(0xFF15803D),
        severity: InsightSeverity.warning,
        actionLabel: 'Analyze Expenses',
        onAction: () => Navigator.of(context).pushNamed('/reports/expenses'),
      ));
    }

    if (cogs == 0 && revenue > 0) {
      insights.add(InsightCard(
        title: 'Missing Cost Data',
        description:
            'Cost of goods sold is not recorded for some sales. Profit calculations may be inaccurate.',
        icon: Icons.info_outline,
        color: Color(0xFF15803D),
        severity: InsightSeverity.info,
        actionLabel: 'Update Product Costs',
        onAction: () {},
      ));
    }

    if (insights.isEmpty && operatingResult > 0) {
      insights.add(InsightCard(
        title: 'Profitable Operations',
        description:
            'Business is profitable with ${operatingMargin.toStringAsFixed(1)}% operating margin. Consider reinvestment or expansion.',
        icon: Icons.check_circle,
        color: Color(0xFF111111),
        severity: InsightSeverity.success,
      ));
    }

    return SectionCard(
      title: 'Financial Insights',
      child: Column(children: insights),
    );
  }

  List<_Sale> _getSalesInRange(PosLocalStore store, DateTimeRange? range) {
    return _salesInRange(store.orders, range?.start, range?.end);
  }

  List<Expense> _getExpensesInRange(PosLocalStore store, DateTimeRange? range) {
    return store.expenses.where((expense) {
      final date = expense.date.toLocal();
      if (range == null) return true;
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList();
  }
}

class _Sale {
  _Sale(this.order, this.date)
      : gross =
            order.lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  final CompletedOrder order;
  final DateTime date;
  final double gross;
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

class _PnLRow extends StatelessWidget {
  const _PnLRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isNegative = false,
  });

  final String label;
  final double value;
  final bool isTotal;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
                color: isTotal ? Colors.grey.shade900 : Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            'TSh ${NumberFormat('#,##0.##').format(value.abs())}',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isNegative && value != 0
                  ? AppColors.textBody
                  : isTotal
                      ? Color(0xFF166534)
                      : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarginGauge extends StatelessWidget {
  const _MarginGauge({
    required this.label,
    required this.value,
    required this.benchmark,
    required this.color,
    this.lowerIsBetter = false,
  });

  final String label;
  final double value;
  final double benchmark;
  final Color color;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final isGood = lowerIsBetter ? value <= benchmark : value >= benchmark;
    final progress = (value / (benchmark * 2)).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGood ? color : AppColors.textMuted,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  '${value.toStringAsFixed(1)}%',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isGood ? color : AppColors.textMuted,
                  ),
                ),
                Text(
                  'Target: ${lowerIsBetter ? "≤" : "≥"}${benchmark.toStringAsFixed(0)}%',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
