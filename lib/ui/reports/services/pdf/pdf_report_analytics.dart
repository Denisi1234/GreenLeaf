part of '../pdf_report_service.dart';

String _buildPdfExecutiveSummary({
  required ReportSnapshot report,
  required PdfReportStats stats,
  required PdfReportStats previousStats,
  required AppProfileData profile,
  required int lowStockCount,
}) {
  final storeName =
      profile.storeName.trim().isEmpty ? 'The store' : profile.storeName.trim();
  final focus = _categoryFocusSentence(report.category);
  final revenueChange = _changeLabel(stats.revenue, previousStats.revenue);
  final orderChange = _changeLabel(stats.orderCount, previousStats.orderCount);
  final margin = stats.revenue - stats.totalExpenses;
  final expenseRatio =
      stats.revenue <= 0 ? 0.0 : (stats.totalExpenses / stats.revenue) * 100;
  final topProduct = report.products.isNotEmpty
      ? 'The top selling product was ${report.products.first.title}.'
      : 'No completed sales were recorded in the selected period.';
  final lowStockText = lowStockCount == 0
      ? 'No inventory items are currently in the low-stock watchlist.'
      : '$lowStockCount inventory item${lowStockCount == 1 ? '' : 's'} are now in the low-stock watchlist.';
  final marginText = margin >= 0
      ? 'The period closed with a positive margin of ${_moneyLabel(margin)}.'
      : 'The period closed with a negative margin of ${_moneyLabel(margin.abs())}, which means expenses outpaced revenue.';

  return '$storeName recorded ${_moneyLabel(stats.revenue)} across ${stats.orderCount} completed orders during ${report.dateRangeLabel}. '
      '$focus '
      'Revenue changed by $revenueChange while order volume changed by $orderChange compared with the previous comparable period. '
      'Average order value was ${_moneyLabel(stats.averageOrderValue)}, with ${stats.activeCustomers} active customer${stats.activeCustomers == 1 ? '' : 's'} and ${stats.returningCustomers} repeat buyer${stats.returningCustomers == 1 ? '' : 's'}. '
      '$marginText Expenses consumed ${expenseRatio.toStringAsFixed(0)}% of revenue, which puts the business in ${expenseRatio > 70 ? 'a pressure zone' : 'a manageable zone'}. '
      '$lowStockText $topProduct';
}

String _categoryFocusSentence(BusinessCategory category) {
  return 'This report emphasizes basket size, fast-moving stock, markdown pressure, and reorder timing for store-floor decisions.';
}

String _buildPdfConclusion(
  ReportSnapshot report,
  PdfReportStats stats,
  int lowStockCount,
) {
  final revenue = _moneyLabel(stats.revenue);
  final expenses = _moneyLabel(stats.totalExpenses);
  final margin = stats.revenue - stats.totalExpenses;
  final marginLabel = _moneyLabel(margin.abs());
  final marginText = margin >= 0 ? 'profit cushion' : 'cost pressure';
  final inventoryText = lowStockCount == 0
      ? 'Inventory levels are currently stable across the low-stock watchlist.'
      : '$lowStockCount low-stock item${lowStockCount == 1 ? '' : 's'} deserve immediate restocking attention.';

  return '${report.category.displayName} reporting for ${report.dateRangeLabel} showed a fuller business picture than revenue alone. Revenue closed at $revenue, expenses totaled $expenses, and the net position reflected a $marginText of $marginLabel. '
      '$inventoryText The forecast section below highlights near-term demand momentum, stock pressure, and margin protection opportunities.';
}

ForecastSnapshot _buildForecastSnapshot({
  required ReportSnapshot report,
  required PdfReportStats currentStats,
  required PdfReportStats previousStats,
  required PosLocalStore store,
}) {
  final periodDays = math.max(
    1,
    report.endDate.difference(report.startDate).inDays + 1,
  );
  final averageDailyRevenue = currentStats.revenue / periodDays;
  final revenueChangeRatio = _safeRatio(
    currentStats.revenue,
    previousStats.revenue,
    positiveFallback: 0.12,
  );
  final orderChangeRatio = _safeRatio(
    currentStats.orderCount.toDouble(),
    previousStats.orderCount.toDouble(),
    positiveFallback: 0.08,
  );
  final trendBias = _trendBias(report.trendPoints);
  final momentum = (1 +
          (revenueChangeRatio * 0.35) +
          (orderChangeRatio * 0.15) +
          (trendBias * 0.25))
      .clamp(0.75, 1.35)
      .toDouble();

  final weekBase = averageDailyRevenue * 7 * momentum;
  final monthBase = averageDailyRevenue * 30 * momentum;
  final volatility = math.min(
    0.22,
    0.12 +
        (report.trendPoints.length < 4 ? 0.06 : 0.0) +
        (revenueChangeRatio.abs() * 0.05),
  );
  final monthVolatility = math.min(0.28, volatility + 0.05);
  final lowStockCount = PdfReportService.lowStockItems(store).length;
  final expenseRatio = currentStats.revenue <= 0
      ? 0.0
      : (currentStats.totalExpenses / currentStats.revenue) * 100;

  final directionTone = momentum > 1.08
      ? 'Upward momentum'
      : momentum < 0.94
          ? 'Softening momentum'
          : 'Stable momentum';
  final confidenceLabel = report.trendPoints.length >= 7
      ? 'Moderate confidence'
      : 'Directional estimate';

  final riskParts = <String>[];
  if (lowStockCount > 0) {
    riskParts.add(
      '$lowStockCount low-stock item${lowStockCount == 1 ? '' : 's'} may restrict growth',
    );
  }
  if (expenseRatio > 70) {
    riskParts.add(
      'expenses are taking ${expenseRatio.toStringAsFixed(0)}% of revenue',
    );
  }
  if (riskParts.isEmpty) {
    riskParts.add('operating conditions are relatively balanced');
  }
  riskParts.add(_forecastCategoryHint(report.category));

  return ForecastSnapshot(
    nextWeekBase: weekBase,
    nextWeekLow: weekBase * (1 - volatility),
    nextWeekHigh: weekBase * (1 + volatility),
    nextMonthBase: monthBase,
    nextMonthLow: monthBase * (1 - monthVolatility),
    nextMonthHigh: monthBase * (1 + monthVolatility),
    directionTone: directionTone,
    confidenceLabel: confidenceLabel,
    riskNote: riskParts.join(', '),
  );
}

double _safeRatio(
  double current,
  double previous, {
  required double positiveFallback,
}) {
  if (previous == 0) {
    if (current <= 0) return 0.0;
    return positiveFallback;
  }
  return (current - previous) / previous;
}

double _trendBias(List<TrendPoint> points) {
  if (points.length < 2) return 0.0;
  final first = points.first.value;
  final last = points.last.value;
  if (first <= 0) {
    return last > 0 ? 0.12 : 0.0;
  }
  return ((last - first) / first).clamp(-0.25, 0.25).toDouble();
}

String _forecastCategoryHint(BusinessCategory category) {
  return 'Demand should stay anchored around basket size, fast movers, and markdown activity.';
}

List<CompletedOrder> _ordersWithinRange(
  List<CompletedOrder> orders,
  DateTime start,
  DateTime end,
) {
  return orders.where((order) {
    final orderDate = DateTime.tryParse(order.dateTime);
    if (orderDate == null) return false;
    final day = DateTime(orderDate.year, orderDate.month, orderDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }).toList();
}

List<Expense> _expensesWithinRange(
  List<Expense> expenses,
  DateTime start,
  DateTime end,
) {
  return expenses.where((expense) {
    final day =
        DateTime(expense.date.year, expense.date.month, expense.date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }).toList();
}

ReportRange _previousComparableRange(DateTime start, DateTime end) {
  final days = end.difference(start).inDays + 1;
  final previousEnd = start.subtract(const Duration(days: 1));
  final previousStart = previousEnd.subtract(Duration(days: days - 1));
  return ReportRange(
    start: previousStart,
    end: previousEnd,
    label: '${_dateLabel(previousStart)} - ${_dateLabel(previousEnd)}',
  );
}

String _changeLabel(num current, num previous) {
  if (previous == 0) {
    if (current == 0) return '0%';
    return '+100% vs previous';
  }
  final change = ((current - previous) / previous) * 100;
  final sign = change >= 0 ? '+' : '';
  return '$sign${change.abs().toStringAsFixed(change.abs() >= 10 ? 0 : 1)}% vs previous';
}

String _dateLabel(DateTime date) {
  const monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

String _moneyLabel(double amount) {
  return 'TSH ${_formatWithCommas(amount)}';
}

String _formatWithCommas(num value) {
  final fixed = value.toStringAsFixed(0);
  return fixed.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}
