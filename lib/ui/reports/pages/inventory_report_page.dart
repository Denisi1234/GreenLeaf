import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../ui/products/inventory_product_item.dart';
import '../enhanced_report_page.dart';
import '../models/report_models.dart';
import '../pos_report_catalog.dart';
import '../pos_report_data.dart'
    show PosReportData, InventoryProductItem, ReportColumn, ReportTable;
import '../services/report_data_service.dart';
import '../widgets/section_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/comparison_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/stock_alert_card.dart';

class InventoryReportPage extends StatelessWidget {
  const InventoryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedReportPage(
      report: const PosReport(
        'Inventory Summary',
        ReportGroup.inventory,
        ReportData.inventory,
      ),
      additionalMetricsBuilder: _buildMetrics,
      additionalSectionsBuilder: _buildSections,
    );
  }

  List<MetricData> _buildMetrics(ReportTable table, PosReportData data) {
    final totalProducts = table.rows.length;
    final totalUnits =
        table.rows.fold<int>(0, (sum, row) => sum + (row[3] as int));
    final totalCostValue = table.rows
        .fold<double>(0, (sum, row) => sum + (row[6] as num).toDouble());
    final totalRetailValue = table.rows.fold<double>(
        0, (sum, row) => sum + (row[5] as num).toDouble() * (row[3] as int));
    final lowStockCount = data.inventory
        .where((item) => item.stockState != InventoryStockState.inStock)
        .length;

    return [
      MetricData(
        title: 'Total Products',
        value: NumberFormat('#,###').format(totalProducts),
        icon: Icons.inventory_2,
        iconColor: Color(0xFF166534),
        tint: Color(0xFF166534).withValues(alpha: 0.1),
        valueColor: Color(0xFF166534),
      ),
      MetricData(
        title: 'Total Units in Stock',
        value: NumberFormat('#,###').format(totalUnits),
        icon: Icons.production_quantity_limits,
        iconColor: Color(0xFF15803D),
        tint: Color(0xFF15803D).withValues(alpha: 0.1),
        valueColor: Color(0xFF15803D),
      ),
      MetricData(
        title: 'Inventory Cost Value',
        value: 'TSh ${NumberFormat('#,##0.##').format(totalCostValue)}',
        icon: Icons.attach_money,
        iconColor: Color(0xFF111111),
        tint: Color(0xFF111111).withValues(alpha: 0.1),
        valueColor: Color(0xFF111111),
      ),
      MetricData(
        title: 'Low Stock Alerts',
        value: NumberFormat('#,###').format(lowStockCount),
        icon: Icons.warning,
        iconColor: lowStockCount > 0 ? Colors.red : Color(0xFF111111),
        tint: (lowStockCount > 0 ? Colors.red : Color(0xFF111111))
            .withValues(alpha: 0.1),
        valueColor: lowStockCount > 0 ? Colors.red : Color(0xFF111111),
      ),
    ];
  }

  List<Widget> _buildSections(
    BuildContext context,
    ReportTable table,
    PosReportData data,
    DateTimeRange? range,
  ) {
    final lowStockItems = ReportDataService.lowStockItemsFromData(data);

    return [
      _buildStockAlertCard(lowStockItems),
      _buildStockValueCard(table),
      _buildCategoryBreakdownCard(context, table),
      _buildInsightsCard(context, table, lowStockItems),
    ];
  }

  Widget _buildStockAlertCard(List<StockAlertItem> lowStockItems) {
    return SectionCard(
      title: 'Stock Alerts',
      child: StockAlertCard(items: lowStockItems),
    );
  }

  Widget _buildStockValueCard(ReportTable table) {
    final totalCostValue = table.rows
        .fold<double>(0, (sum, row) => sum + (row[6] as num).toDouble());
    final totalRetailValue = table.rows.fold<double>(
        0, (sum, row) => sum + (row[5] as num).toDouble() * (row[3] as int));
    final potentialProfit = totalRetailValue - totalCostValue;
    final markupPercent =
        totalCostValue > 0 ? (potentialProfit / totalCostValue) * 100 : 0.0;

    return SectionCard(
      title: 'Inventory Valuation',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ValuationStat(
                  label: 'Cost Value',
                  value: 'TSh ${NumberFormat('#,##0').format(totalCostValue)}',
                  color: Color(0xFF15803D),
                ),
              ),
              Expanded(
                child: _ValuationStat(
                  label: 'Retail Value',
                  value: 'TSh ${NumberFormat('#,##0').format(totalRetailValue)}',
                  color: Color(0xFF111111),
                ),
              ),
              Expanded(
                child: _ValuationStat(
                  label: 'Potential Profit',
                  value: 'TSh ${NumberFormat('#,##0').format(potentialProfit)}',
                  color: Color(0xFF15803D),
                ),
              ),
              Expanded(
                child: _ValuationStat(
                  label: 'Markup',
                  value: '${markupPercent.toStringAsFixed(1)}%',
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(BuildContext context, ReportTable table) {
    // Group by category
    final categoryMap = <String, Map<String, dynamic>>{};
    for (final row in table.rows) {
      final category = row[2].toString();
      final cost = (row[6] as num).toDouble();
      final units = (row[3] as int);
      final retail = (row[5] as num).toDouble() * units;

      categoryMap.putIfAbsent(
          category,
          () => {
                'cost': 0.0,
                'retail': 0.0,
                'units': 0,
                'products': 0,
              });
      final cat = categoryMap[category]!;
      cat['cost'] = (cat['cost'] as double) + cost;
      cat['retail'] = (cat['retail'] as double) + retail;
      cat['units'] = (cat['units'] as int) + units;
      cat['products'] = (cat['products'] as int) + 1;
    }

    final trendPoints = categoryMap.entries
        .map((e) => TrendPoint(
              label: e.key,
              value: (e.value['retail'] as double),
              displayValue:
                  'TSh ${NumberFormat('#,##0').format(e.value['retail'] as double)}',
            ))
        .toList();
    final maxValue = trendPoints.isEmpty
        ? 0.0
        : trendPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      title: 'Stock Value by Category',
      child: TrendChart(
        points: trendPoints,
        maxValue: maxValue,
        label: 'Retail Value',
        color: Color(0xFF166534),
      ),
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    ReportTable table,
    List<StockAlertItem> lowStockItems,
  ) {
    final insights = <InsightCard>[];
    final totalCostValue = table.rows
        .fold<double>(0, (sum, row) => sum + (row[6] as num).toDouble());

    if (lowStockItems.isNotEmpty) {
      final outOfStock = lowStockItems.where((i) => i.stockCount <= 0).length;
      final lowStock = lowStockItems
          .where((i) => i.stockCount > 0 && i.stockCount <= 10)
          .length;

      insights.add(InsightCard(
        title: 'Stock Replenishment Needed',
        description:
            '$outOfStock items out of stock, $lowStock items below threshold. Immediate reorder recommended.',
        icon: Icons.inventory,
        color: Colors.red,
        severity:
            outOfStock > 0 ? InsightSeverity.critical : InsightSeverity.warning,
        actionLabel: 'Create Purchase Order',
        onAction: () {},
      ));
    }

    final deadStock = table.rows.where((row) {
      final units = row[3] as int;
      return units == 0;
    }).length;

    if (deadStock > 0) {
      insights.add(InsightCard(
        title: 'Dead Stock Identified',
        description:
            '$deadStock products have zero stock. Consider discontinuing or promoting.',
        icon: Icons.delete_outline,
        color: Colors.grey,
        severity: InsightSeverity.info,
      ));
    }

    final highValueItems = table.rows
        .where((row) => (row[6] as num).toDouble() > totalCostValue * 0.1)
        .length;
    if (highValueItems > 0) {
      insights.add(InsightCard(
        title: 'High-Value Inventory Concentration',
        description:
            '$highValueItems items represent >10% of inventory value each. Diversify stock to reduce risk.',
        icon: Icons.warning_amber,
        color: Color(0xFF15803D),
        severity: InsightSeverity.info,
      ));
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Insights',
      child: Column(children: insights),
    );
  }
}

class _ValuationStat extends StatelessWidget {
  const _ValuationStat({
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
