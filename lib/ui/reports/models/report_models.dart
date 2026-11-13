import 'package:flutter/material.dart';

import '../../business_category_config.dart';

enum ReportPeriod { today, week, month, allTime }

extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.week:
        return 'This Week';
      case ReportPeriod.month:
        return 'This Month';
      case ReportPeriod.allTime:
        return 'All Time';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.week:
        return 'Week';
      case ReportPeriod.month:
        return 'Month';
      case ReportPeriod.allTime:
        return 'All';
    }
  }
}

class MetricData {
  const MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.valueColor,
    this.deltaText,
    this.deltaLabel = '',
    this.deltaIsPositive,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final Color valueColor;
  final String? deltaText;
  final String deltaLabel;
  final bool? deltaIsPositive;
}

class StockAlertItem {
  const StockAlertItem({
    required this.name,
    required this.category,
    required this.stockCount,
    required this.statusLabel,
    required this.severity,
  });

  final String name;
  final String category;
  final int stockCount;
  final String statusLabel;
  final StockAlertSeverity severity;
}

enum StockAlertSeverity { high, medium }

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.value,
    required this.displayValue,
  });

  final String label;
  final double value;
  final String displayValue;
}

class ProductTally {
  ProductTally({
    required this.title,
    required this.quantity,
    required this.revenue,
    required this.icon,
    required this.colors,
  });

  final String title;
  int quantity;
  double revenue;
  final IconData icon;
  final List<Color> colors;
}

class ProductData {
  const ProductData({
    required this.title,
    required this.orders,
    required this.amount,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String orders;
  final String amount;
  final IconData icon;
  final List<Color> colors;
}

class ReportRange {
  const ReportRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.category,
    required this.periodLabel,
    required this.dateRangeLabel,
    required this.startDate,
    required this.endDate,
    required this.metrics,
    required this.trendPoints,
    required this.profitTrendPoints,
    required this.products,
    required this.allProducts,
    required this.chartMaxValue,
    required this.profitChartMaxValue,
  });

  final BusinessCategory category;
  final String periodLabel;
  final String dateRangeLabel;
  final DateTime startDate;
  final DateTime endDate;
  final List<MetricData> metrics;
  final List<TrendPoint> trendPoints;
  final List<TrendPoint> profitTrendPoints;
  final List<ProductData> products;
  final List<ProductData> allProducts;
  final double chartMaxValue;
  final double profitChartMaxValue;
}

class PdfReportStats {
  const PdfReportStats({
    required this.revenue,
    required this.orderCount,
    required this.averageOrderValue,
    required this.totalExpenses,
    required this.activeCustomers,
    required this.returningCustomers,
    required this.newCustomers,
    required this.topCustomerName,
    required this.topCustomerValue,
    required this.peakOrderId,
    required this.revenueTrend,
    required this.startDate,
    required this.endDate,
  });

  final double revenue;
  final int orderCount;
  final double averageOrderValue;
  final double totalExpenses;
  final int activeCustomers;
  final int returningCustomers;
  final int newCustomers;
  final String? topCustomerName;
  final double topCustomerValue;
  final String? peakOrderId;
  final double revenueTrend;
  final DateTime startDate;
  final DateTime endDate;
}

class ForecastSnapshot {
  const ForecastSnapshot({
    required this.nextWeekBase,
    required this.nextWeekLow,
    required this.nextWeekHigh,
    required this.nextMonthBase,
    required this.nextMonthLow,
    required this.nextMonthHigh,
    required this.directionTone,
    required this.confidenceLabel,
    required this.riskNote,
  });

  final double nextWeekBase;
  final double nextWeekLow;
  final double nextWeekHigh;
  final double nextMonthBase;
  final double nextMonthLow;
  final double nextMonthHigh;
  final String directionTone;
  final String confidenceLabel;
  final String riskNote;
}
