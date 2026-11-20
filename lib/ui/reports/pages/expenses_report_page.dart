import 'package:track_mauzo/l10n/app_localization.dart';
import '../../widgets/app_design.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../service/expense_model.dart';
import '../../../service/pos_order_models.dart';
import '../enhanced_report_page.dart';
import '../models/report_models.dart';
import '../pos_report_catalog.dart';
import '../pos_report_data.dart';
import '../widgets/section_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/insight_card.dart';

class ExpensesReportPage extends StatelessWidget {
  const ExpensesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Expenses by Category',
        ReportGroup.summary,
        ReportData.expenses,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalExpenses = table.rows
        .fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final totalEntries =
        table.rows.fold<int>(0, (sum, row) => sum + (row[1] as int));
    final avgExpense = totalEntries > 0 ? totalExpenses / totalEntries : 0.0;
    final categories = table.rows.length;

    return [
      MetricData(
        title: 'Total Expenses',
        value: 'TSH ${NumberFormat('#,##0.##').format(totalExpenses)}',
        icon: Icons.receipt_long_outlined,
        iconColor: AppColors.danger,
        tint: AppColors.dangerLight,
        valueColor: AppColors.danger,
      ),
      MetricData(
        title: 'Expense Entries',
        value: NumberFormat('#,###').format(totalEntries),
        icon: Icons.list_alt_outlined,
        iconColor: AppColors.ink,
        tint: const Color(0xFFF3F4F6),
        valueColor: AppColors.ink,
      ),
      MetricData(
        title: 'Avg per Entry',
        value: 'TSH ${NumberFormat('#,##0.##').format(avgExpense)}',
        icon: Icons.analytics_outlined,
        iconColor: AppColors.textMuted,
        tint: const Color(0xFFF3F4F6),
        valueColor: AppColors.textMuted,
      ),
      MetricData(
        title: 'Categories',
        value: NumberFormat('#,###').format(categories),
        icon: Icons.category,
        iconColor: AppColors.ink,
        tint: const Color(0xFFF3F4F6),
        valueColor: AppColors.ink,
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
    final expenses = _getExpensesInRange(store, range);
    final totalSales = _getSalesInRange(store.orders, range?.start, range?.end)
        .fold(0.0, (sum, s) => sum + s.order.total);
    final totalExpenses = table.rows
        .fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final expenseRatio =
        totalSales > 0 ? (totalExpenses / totalSales) * 100 : 0.0;

    return [
      _buildExpenseTrendCard(context, expenses),
      _buildExpenseRatioCard(context, expenseRatio),
      _buildInsightsCard(context, table, expenseRatio),
    ];
  }

  Widget _buildExpenseTrendCard(BuildContext context, List<Expense> expenses) {
    final dailyExpenses = <DateTime, double>{};
    for (final expense in expenses) {
      final day =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyExpenses[day] = (dailyExpenses[day] ?? 0.0) + expense.amount;
    }

    final sortedDays = dailyExpenses.keys.toList()..sort();
    final trendPoints = sortedDays
        .map((day) => TrendPoint(
              label: DateFormat('MMM d').format(day),
              value: dailyExpenses[day]!,
              displayValue:
                  'TSH ${NumberFormat('#,##0').format(dailyExpenses[day]!)}',
            ))
        .toList();
    final maxValue = trendPoints.isEmpty
        ? 0.0
        : trendPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      title: context.tr('Daily Expense Trend'),
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: context.tr('Expenses'),
        color: AppColors.danger,
      ),
    );
  }

  Widget _buildExpenseRatioCard(BuildContext context, double expenseRatio) {
    return SectionCard(
      title: context.tr('Expense to Sales Ratio'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Expenses as % of Sales'),
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${expenseRatio.toStringAsFixed(1)}%',
                      style: GoogleFonts.manrope(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: expenseRatio > 30
                            ? Colors.red
                            : expenseRatio > 15
                                ? AppColors.ink
                                : Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expenseRatio > 30
                          ? context.tr('High expense ratio - review cost structure')
                          : expenseRatio > 15
                              ? context.tr('Moderate expense ratio - monitor closely')
                              : context.tr('Healthy expense ratio'),
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
                value: (expenseRatio / 50).clamp(0.0, 1.0),
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  expenseRatio > 30
                      ? Colors.red
                      : expenseRatio > 15
                          ? AppColors.ink
                          : Color(0xFF111111),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(
      BuildContext context, ReportTable table, double expenseRatio) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final insights = <InsightCard>[];

    final topCategory = table.rows.first;
    final topCategoryName = topCategory[0].toString();
    final topCategoryAmount = (topCategory[2] as num).toDouble();
    final totalExpenses = table.rows
        .fold<double>(0, (sum, row) => sum + (row[2] as num).toDouble());
    final topCategoryShare =
        totalExpenses > 0 ? (topCategoryAmount / totalExpenses) * 100 : 0.0;

    insights.add(InsightCard(
      title: context.tr('Largest Expense Category'),
      description:
          context.tr('"{p0}" accounts for {p1}% of total expenses (TSH {p2})', args: {'p0': topCategoryName, 'p1': topCategoryShare.toStringAsFixed(1), 'p2': NumberFormat('#,##0').format(topCategoryAmount)}),
      icon: Icons.category_outlined,
      color: AppColors.ink,
      severity: InsightSeverity.info,
    ));

    if (expenseRatio > 30) {
      insights.add(InsightCard(
        title: context.tr('High Expense Ratio'),
        description:
            context.tr('Expenses exceed 30% of sales. Consider cost reduction measures or revenue growth strategies.'),
        icon: Icons.warning,
        color: Colors.red,
        severity: InsightSeverity.critical,
        actionLabel: 'View Profit & Loss',
        onAction: () => Navigator.of(context).pushNamed('/reports/profit_loss'),
      ));
    }

    return SectionCard(
      title: context.tr('Insights'),
      child: Column(children: insights),
    );
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

  bool get isCredit => order.paymentMethod.trim().toLowerCase() == 'credit';
}

List<_Sale> _getSalesInRange(
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
