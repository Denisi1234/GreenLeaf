import '../../widgets/app_design.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../business_category_config.dart';
import '../../../service/expense_model.dart';
import '../../../service/pos_local_store.dart';
import '../../../service/pos_order_models.dart';
import '../../models/customer_data.dart';
import '../../models/product_item.dart';
import '../../products/inventory_product_item.dart';
import '../models/report_models.dart';
import '../pos_report_data.dart';

class ReportDataService {
  static const Color _blue = AppColors.primary;
  static const Color _bg = Color(0xFFF6F8FC);
  static const Color _ink = Color(0xFF111111);

  static ReportSnapshot buildReportSnapshot({
    required PosLocalStore store,
    required ReportPeriod period,
    required BusinessCategory category,
  }) {
    final orders = store.orders;
    final range = _resolveReportRange(orders, period);

    final ordersInRange = _ordersWithinRange(orders, range.start, range.end);

    final dailyRevenue = <DateTime, double>{};
    final dailyExpenses = <DateTime, double>{};
    final productTally = <String, ProductTally>{};

    for (final order in ordersInRange) {
      final orderDate = DateTime.tryParse(order.dateTime);
      if (orderDate == null) continue;
      final day = DateTime(orderDate.year, orderDate.month, orderDate.day);
      dailyRevenue[day] = (dailyRevenue[day] ?? 0) + order.total;

      for (final line in order.lines) {
        final key = line.itemCode?.trim().isNotEmpty == true
            ? line.itemCode!.trim()
            : line.itemName.trim();
        final current = productTally.putIfAbsent(
          key,
          () => ProductTally(
            title: line.itemName,
            quantity: 0,
            revenue: 0,
            icon: _iconForLine(line),
            colors: _colorsForLine(line),
          ),
        );
        current.quantity += line.quantity;
        current.revenue += line.lineTotal;
      }
    }

    for (final expense in _expensesWithinRange(
      store.expenses,
      range.start,
      range.end,
    )) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      dailyExpenses[day] = (dailyExpenses[day] ?? 0) + expense.amount;
    }

    final currentStats = buildPdfStats(
      orders: ordersInRange,
      customers: store.customers,
      expenses: _expensesWithinRange(
        store.expenses,
        range.start,
        range.end,
      ),
      startDate: range.start,
      endDate: range.end,
    );
    final previousRange = _previousComparableRange(range.start, range.end);
    final previousStats = buildPdfStats(
      orders: _ordersWithinRange(
        orders,
        previousRange.start,
        previousRange.end,
      ),
      customers: store.customers,
      expenses: _expensesWithinRange(
        store.expenses,
        previousRange.start,
        previousRange.end,
      ),
      startDate: previousRange.start,
      endDate: previousRange.end,
    );

    final trendPoints = _buildTrendPoints(
      dailyRevenue: dailyRevenue,
      startDate: range.start,
      endDate: range.end,
    );
    final profitTrendPoints = _buildProfitTrendPoints(
      dailyRevenue: dailyRevenue,
      dailyExpenses: dailyExpenses,
      startDate: range.start,
      endDate: range.end,
    );

    final totalRevenue = ordersInRange.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final totalExpenses = _expensesWithinRange(
      store.expenses,
      range.start,
      range.end,
    ).fold<double>(0, (sum, expense) => sum + expense.amount);
    final totalProfit = totalRevenue - totalExpenses;
    final totalOrders = ordersInRange.length;
    final averageOrderValue =
        totalOrders == 0 ? 0.0 : totalRevenue / totalOrders;
    final topProducts = productTally.values.toList()
      ..sort((left, right) {
        final quantityCompare = right.quantity.compareTo(left.quantity);
        if (quantityCompare != 0) return quantityCompare;
        final revenueCompare = right.revenue.compareTo(left.revenue);
        if (revenueCompare != 0) return revenueCompare;
        return left.title.compareTo(right.title);
      });
    final topProductLabel =
        topProducts.isNotEmpty ? topProducts.first.title : 'No sales yet';

    final productData = topProducts
        .take(3)
        .map(
          (product) => ProductData(
            title: product.title,
            orders: '${product.quantity} sold',
            amount: _moneyLabel(product.revenue),
            icon: product.icon,
            colors: product.colors,
          ),
        )
        .toList();

    final config = BusinessCategoryConfig.forCategory(category);
    final comparisonLabel = _comparisonPeriodLabel(period);
    final revenueDelta = _comparisonPercentLabel(
      currentStats.revenue,
      previousStats.revenue,
    );
    final orderDelta = _comparisonPercentLabel(
      currentStats.orderCount,
      previousStats.orderCount,
    );
    final averageDelta = _comparisonPercentLabel(
      currentStats.averageOrderValue,
      previousStats.averageOrderValue,
    );
    List<MetricData> withColors(List<MetricData> items) {
      return items
          .map(
            (item) => MetricData(
              title: item.title,
              value: item.value,
              icon: item.icon,
              iconColor: item.iconColor,
              tint: item.tint,
              valueColor: item.valueColor,
              deltaText: item.deltaText,
              deltaLabel: item.deltaLabel,
              deltaIsPositive: item.deltaIsPositive,
            ),
          )
          .toList();
    }

    final primaryTint = config.primaryLightColor;
    final primaryColor = config.primaryColor;
    final secondaryColor = config.accentColor;

    final metrics = withColors([
      MetricData(
        title: 'Sales',
        value: _moneyLabel(totalRevenue),
        icon: Icons.trending_up_rounded,
        iconColor: primaryColor,
        tint: primaryTint,
        valueColor: primaryColor,
        deltaText: revenueDelta,
        deltaLabel: comparisonLabel,
        deltaIsPositive: currentStats.revenue >= previousStats.revenue,
      ),
      MetricData(
        title: 'Transactions',
        value: totalOrders.toString(),
        icon: Icons.shopping_bag_rounded,
        iconColor: secondaryColor,
        tint: config.surfaceTintColor,
        valueColor: secondaryColor,
        deltaText: orderDelta,
        deltaLabel: comparisonLabel,
        deltaIsPositive: currentStats.orderCount >= previousStats.orderCount,
      ),
      MetricData(
        title: 'Average Basket',
        value: _moneyLabel(averageOrderValue),
        icon: Icons.receipt_long_rounded,
        iconColor: primaryColor,
        tint: primaryTint,
        valueColor: primaryColor,
        deltaText: averageDelta,
        deltaLabel: comparisonLabel,
        deltaIsPositive: currentStats.averageOrderValue >=
            previousStats.averageOrderValue,
      ),
      MetricData(
        title: 'Fast Mover',
        value: topProductLabel,
        icon: Icons.sell_outlined,
        iconColor: secondaryColor,
        tint: config.surfaceTintColor,
        valueColor: primaryColor,
        deltaText: null,
        deltaLabel: 'Fast mover',
        deltaIsPositive: null,
      ),
    ]);

    return ReportSnapshot(
      category: category,
      periodLabel: period.label,
      dateRangeLabel: range.label,
      startDate: range.start,
      endDate: range.end,
      metrics: metrics,
      trendPoints: trendPoints,
      profitTrendPoints: profitTrendPoints,
      products: productData,
      allProducts: topProducts
          .map(
            (product) => ProductData(
              title: product.title,
              orders: '${product.quantity} sold',
              amount: _moneyLabel(product.revenue),
              icon: product.icon,
              colors: product.colors,
            ),
          )
          .toList(),
      chartMaxValue: _resolveChartMax(trendPoints),
      profitChartMaxValue: _resolveProfitChartMax(profitTrendPoints),
    );
  }

  static List<StockAlertItem> lowStockItems(PosLocalStore store) {
    final items = store.inventory
        .where((item) => item.stockCount <= 20)
        .map(
          (item) => StockAlertItem(
            name: item.name,
            category: item.category,
            stockCount: item.stockCount,
            statusLabel: item.stockCount <= 0
                ? 'Out of stock'
                : '${item.stockCount} left',
            severity: item.stockCount <= 5
                ? StockAlertSeverity.high
                : StockAlertSeverity.medium,
          ),
        )
        .toList()
      ..sort((left, right) => left.stockCount.compareTo(right.stockCount));

    return items.take(4).toList();
  }

  static List<StockAlertItem> lowStockItemsFromData(PosReportData data) {
    final items = data.inventory
        .where((item) => item.stockCount <= 20)
        .map(
          (item) => StockAlertItem(
            name: item.name,
            category: item.category,
            stockCount: item.stockCount,
            statusLabel: item.stockCount <= 0
                ? 'Out of stock'
                : '${item.stockCount} left',
            severity: item.stockCount <= 5
                ? StockAlertSeverity.high
                : StockAlertSeverity.medium,
          ),
        )
        .toList()
      ..sort((left, right) => left.stockCount.compareTo(right.stockCount));

    return items.take(4).toList();
  }

  static String buildExecutiveSummary({
    required ReportSnapshot report,
    required AppProfileData profile,
    required ReportPeriod period,
  }) {
    final revenue = _metricByTitle(report.metrics, 'Total Revenue') ??
        const MetricData(
          title: 'Total Revenue',
          value: '0',
          icon: Icons.payments_outlined,
          iconColor: _blue,
          tint: _bg,
          valueColor: _ink,
          deltaText: null,
          deltaLabel: '',
          deltaIsPositive: null,
        );
    final orders = _metricByTitle(report.metrics, 'Total Orders') ??
        const MetricData(
          title: 'Total Orders',
          value: '0',
          icon: Icons.shopping_bag_outlined,
          iconColor: _blue,
          tint: _bg,
          valueColor: _ink,
          deltaText: null,
          deltaLabel: '',
          deltaIsPositive: null,
        );
    final customers = _metricByTitle(report.metrics, 'New Customers') ??
        const MetricData(
          title: 'New Customers',
          value: '0',
          icon: Icons.people_alt_outlined,
          iconColor: _blue,
          tint: _bg,
          valueColor: _ink,
          deltaText: null,
          deltaLabel: '',
          deltaIsPositive: null,
        );

    final revenueChange = (revenue.deltaText ?? '0%').replaceFirst(
      RegExp(r'^[+-]'),
      '',
    );
    final revenueVerb =
        revenue.deltaIsPositive == false ? 'decreased' : 'increased';
    final customerChange = (customers.deltaText ?? '0%').replaceFirst(
      RegExp(r'^[+-]'),
      '',
    );
    final customerVerb =
        customers.deltaIsPositive == false ? 'decrease' : 'increase';

    final ownerName = profile.ownerName.trim().isEmpty
        ? 'Store owner'
        : profile.ownerName.trim();
    final greeting = _greetingForNow();

    return '$greeting, $ownerName. '
        'Your store performed well this ${period.shortLabel.toLowerCase()}! '
        'Revenue $revenueVerb by $revenueChange compared to last ${period.shortLabel.toLowerCase()}. '
        'You received ${customers.value} new customers, a $customerChange $customerVerb. '
        'Total orders reached ${orders.value}.';
  }

  static MetricData? _metricByTitle(List<MetricData> metrics, String title) {
    for (final metric in metrics) {
      if (metric.title == title) return metric;
    }
    return null;
  }

  static String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static List<TrendPoint> _buildTrendPoints({
    required Map<DateTime, double> dailyRevenue,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    if (totalDays <= 0) {
      return <TrendPoint>[
        TrendPoint(
          label: _trendLabel(startDate),
          value: 0,
          displayValue: _compactAmount(0),
        ),
      ];
    }

    if (totalDays <= 7) {
      return List.generate(totalDays, (index) {
        final day = startDate.add(Duration(days: index));
        final value = dailyRevenue[day] ?? 0;
        return TrendPoint(
          label: _trendLabel(day),
          value: value,
          displayValue: _moneyLabel(value),
        );
      });
    }

    const bucketCount = 6;
    final bucketSize = (totalDays / bucketCount).ceil();
    final points = <TrendPoint>[];

    for (var index = 0; index < bucketCount; index++) {
      final bucketStart = startDate.add(Duration(days: index * bucketSize));
      if (bucketStart.isAfter(endDate)) break;

      var bucketEnd = bucketStart.add(Duration(days: bucketSize - 1));
      if (bucketEnd.isAfter(endDate)) {
        bucketEnd = endDate;
      }

      final revenue = _sumRevenueForRange(
        dailyRevenue: dailyRevenue,
        startDate: bucketStart,
        endDate: bucketEnd,
      );

      points.add(
        TrendPoint(
          label: _trendBucketLabel(bucketStart, bucketEnd),
          value: revenue,
          displayValue: _moneyLabel(revenue),
        ),
      );
    }

    return points.isEmpty
        ? <TrendPoint>[
            TrendPoint(
              label: _trendLabel(startDate),
              value: 0,
              displayValue: _compactAmount(0),
            ),
          ]
        : points;
  }

  static List<TrendPoint> _buildProfitTrendPoints({
    required Map<DateTime, double> dailyRevenue,
    required Map<DateTime, double> dailyExpenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    if (totalDays <= 0) {
      return <TrendPoint>[
        TrendPoint(
          label: _trendLabel(startDate),
          value: 0,
          displayValue: _compactAmount(0),
        ),
      ];
    }

    if (totalDays <= 7) {
      return List.generate(totalDays, (index) {
        final day = startDate.add(Duration(days: index));
        final value = (dailyRevenue[day] ?? 0) - (dailyExpenses[day] ?? 0);
        return TrendPoint(
          label: _trendLabel(day),
          value: value,
          displayValue: _moneyLabelSigned(value),
        );
      });
    }

    const bucketCount = 6;
    final bucketSize = (totalDays / bucketCount).ceil();
    final points = <TrendPoint>[];

    for (var index = 0; index < bucketCount; index++) {
      final bucketStart = startDate.add(Duration(days: index * bucketSize));
      if (bucketStart.isAfter(endDate)) break;

      var bucketEnd = bucketStart.add(Duration(days: bucketSize - 1));
      if (bucketEnd.isAfter(endDate)) {
        bucketEnd = endDate;
      }

      final revenue = _sumRevenueForRange(
        dailyRevenue: dailyRevenue,
        startDate: bucketStart,
        endDate: bucketEnd,
      );
      final expenses = _sumRevenueForRange(
        dailyRevenue: dailyExpenses,
        startDate: bucketStart,
        endDate: bucketEnd,
      );
      final value = revenue - expenses;

      points.add(
        TrendPoint(
          label: _trendBucketLabel(bucketStart, bucketEnd),
          value: value,
          displayValue: _moneyLabelSigned(value),
        ),
      );
    }

    return points.isEmpty
        ? <TrendPoint>[
            TrendPoint(
              label: _trendLabel(startDate),
              value: 0,
              displayValue: _compactAmount(0),
            ),
          ]
        : points;
  }

  static double _sumRevenueForRange({
    required Map<DateTime, double> dailyRevenue,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    double sum = 0;
    for (var day = startDate;
        !day.isAfter(endDate);
        day = day.add(const Duration(days: 1))) {
      sum += dailyRevenue[day] ?? 0;
    }
    return sum;
  }

  static PdfReportStats buildPdfStats({
    required List<CompletedOrder> orders,
    required List<CustomerData> customers,
    required List<Expense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final revenue = orders.fold<double>(0, (sum, order) => sum + order.total);
    final orderCount = orders.length;
    final averageOrderValue = orderCount == 0 ? 0.0 : revenue / orderCount;
    final totalExpenses =
        expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    final activeCustomerNames = orders
        .map((order) => order.customerName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet();
    final activeCustomers = activeCustomerNames.length;
    final returningCustomers = orders
        .where((order) => (order.customerName ?? '').trim().isNotEmpty)
        .fold<Map<String, int>>({}, (map, order) {
          final name = order.customerName!.trim();
          map[name] = (map[name] ?? 0) + 1;
          return map;
        })
        .values
        .where((count) => count > 1)
        .length;
    final newCustomers = customers
        .where((customer) =>
            !customer.createdAt.isBefore(startDate) &&
            !customer.createdAt.isAfter(endDate.add(const Duration(days: 1))))
        .length;
    final topCustomerSpend = <String, double>{};
    for (final order in orders) {
      final customerName = order.customerName?.trim();
      if (customerName == null || customerName.isEmpty) continue;
      topCustomerSpend[customerName] =
          (topCustomerSpend[customerName] ?? 0) + order.total;
    }
    String? topCustomerName;
    double topCustomerValue = 0;
    topCustomerSpend.forEach((name, value) {
      if (value > topCustomerValue) {
        topCustomerValue = value;
        topCustomerName = name;
      }
    });

    final peakOrder = orders.isEmpty
        ? null
        : orders.reduce((a, b) => a.total >= b.total ? a : b);

    return PdfReportStats(
      revenue: revenue,
      orderCount: orderCount,
      averageOrderValue: averageOrderValue,
      totalExpenses: totalExpenses,
      activeCustomers: activeCustomers,
      returningCustomers: returningCustomers,
      newCustomers: newCustomers,
      topCustomerName: topCustomerName,
      topCustomerValue: topCustomerValue,
      peakOrderId: peakOrder?.id,
      revenueTrend: orders.isEmpty ? 0 : orders.last.total - orders.first.total,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static String _comparisonPeriodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return 'vs yesterday';
      case ReportPeriod.week:
        return 'vs last week';
      case ReportPeriod.month:
        return 'vs last month';
      case ReportPeriod.allTime:
        return 'vs previous period';
    }
  }

  static String? _comparisonPercentLabel(num current, num previous) {
    if (previous == 0) {
      if (current == 0) return null;
      return '+100%';
    }

    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '-';
    final rounded = change.abs().toStringAsFixed(change.abs() >= 10 ? 0 : 1);
    return '$sign$rounded%';
  }

  static ReportRange _resolveReportRange(
    List<CompletedOrder> orders,
    ReportPeriod period,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case ReportPeriod.today:
        return ReportRange(
          start: today,
          end: today,
          label: _dateLabel(today),
        );
      case ReportPeriod.week:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return ReportRange(
          start: weekStart,
          end: today,
          label: '${_dateLabel(weekStart)} - ${_dateLabel(today)}',
        );
      case ReportPeriod.month:
        final monthStart = DateTime(today.year, today.month, 1);
        return ReportRange(
          start: monthStart,
          end: today,
          label: '${_dateLabel(monthStart)} - ${_dateLabel(today)}',
        );
      case ReportPeriod.allTime:
        DateTime? earliest;
        for (final order in orders) {
          final orderDate = DateTime.tryParse(order.dateTime);
          if (orderDate != null) {
            final day =
                DateTime(orderDate.year, orderDate.month, orderDate.day);
            if (earliest == null || day.isBefore(earliest)) {
              earliest = day;
            }
          }
        }
        final start = earliest ?? today;
        return ReportRange(
          start: start,
          end: today,
          label: '${_dateLabel(start)} - ${_dateLabel(today)}',
        );
    }
  }

  static ReportRange _previousComparableRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    final previousEnd = start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: days - 1));
    return ReportRange(
      start: previousStart,
      end: previousEnd,
      label: '${_dateLabel(previousStart)} - ${_dateLabel(previousEnd)}',
    );
  }

  static List<CompletedOrder> _ordersWithinRange(
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

  static List<Expense> _expensesWithinRange(
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

  static int _expiringSoonCount(List<InventoryProductItem> items) {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 30));
    var count = 0;
    for (final item in items) {
      final expiry = _parseDateMetadata(item.categoryData['expiry_date']);
      if (expiry == null) continue;
      if (!expiry.isBefore(now) && !expiry.isAfter(threshold)) {
        count += 1;
      }
    }
    return count;
  }

  static int _metadataValueCount(
    List<InventoryProductItem> items,
    String key, {
    required String expectedValue,
  }) {
    final normalizedExpected = expectedValue.trim().toLowerCase();
    return items.where((item) {
      final value = item.categoryData[key];
      return value != null &&
          value.toString().trim().toLowerCase() == normalizedExpected;
    }).length;
  }

  static int _metadataNonEmptyCount(
    List<InventoryProductItem> items,
    List<String> keys,
  ) {
    return items.where((item) {
      for (final key in keys) {
        final value = item.categoryData[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return true;
      }
      return false;
    }).length;
  }

  static int _metadataDistinctCount(
    List<InventoryProductItem> items,
    List<String> keys,
  ) {
    final values = <String>{};
    for (final item in items) {
      for (final key in keys) {
        final value = item.categoryData[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          values.add(value);
        }
      }
    }
    return values.length;
  }

  static String? _topMetadataLabel(
    List<InventoryProductItem> items,
    List<String> keys,
  ) {
    final counts = <String, int>{};
    for (final item in items) {
      for (final key in keys) {
        final value = item.categoryData[key]?.toString().trim() ?? '';
        if (value.isEmpty) continue;
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final topEntry = counts.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    return topEntry.key;
  }

  static String _peakHourLabel(List<CompletedOrder> orders) {
    if (orders.isEmpty) return 'No peak';
    final counts = <int, int>{};
    for (final order in orders) {
      final parsed = DateTime.tryParse(order.dateTime);
      if (parsed == null) continue;
      counts[parsed.hour] = (counts[parsed.hour] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'No peak';
    final topHour = counts.entries
        .reduce(
          (left, right) => left.value >= right.value ? left : right,
        )
        .key;
    return _formatHour(topHour);
  }

  static String _formatHour(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12 $suffix';
  }

  static String _categoryMixLabel(List<InventoryProductItem> items) {
    final categories = items
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet();
    if (categories.isEmpty) return 'No mix data';
    return '${categories.length} categories';
  }

  static DateTime? _parseDateMetadata(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString().trim());
  }

  static String _trendLabel(DateTime date) {
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
    return '${monthNames[date.month - 1]} ${date.day}';
  }

  static String _trendBucketLabel(DateTime start, DateTime end) {
    return '${_trendLabel(start)} - ${_trendLabel(end)}';
  }

  static String _moneyLabel(double amount) {
    return 'TSH ${_formatWithCommas(amount)}';
  }

  static String _moneyLabelSigned(double amount) {
    final formatted = _formatWithCommas(amount.abs());
    if (amount < 0) return '-TSH $formatted';
    return 'TSH $formatted';
  }

  static String _compactAmount(double value) {
    if (value <= 0) return '0K';
    final thousands = value.toDouble() / 1000;
    return '${thousands.round()}K';
  }

  static String _formatWithCommas(num value) {
    final fixed = value.toStringAsFixed(0);
    return fixed.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  static double _resolveChartMax(List<TrendPoint> points) {
    final highestValue = points.fold<double>(
      0,
      (maxValue, point) => math.max(maxValue, point.value),
    );
    if (highestValue <= 0) return 500;
    if (highestValue <= 500) return 500;
    if (highestValue <= 1000) return 1000;
    if (highestValue <= 2500) {
      return (highestValue / 500).ceilToDouble() * 500;
    }
    if (highestValue <= 10000) {
      return (highestValue / 1000).ceilToDouble() * 1000;
    }
    return (highestValue / 5000).ceilToDouble() * 5000;
  }

  static double _resolveProfitChartMax(List<TrendPoint> points) {
    if (points.isEmpty) return 500;
    final highestValue = points.fold<double>(
      0,
      (maxValue, point) => math.max(maxValue, point.value.abs()),
    );
    if (highestValue <= 0) return 500;
    if (highestValue <= 500) return 500;
    if (highestValue <= 1000) return 1000;
    if (highestValue <= 2500) {
      return (highestValue / 500).ceilToDouble() * 500;
    }
    if (highestValue <= 10000) {
      return (highestValue / 1000).ceilToDouble() * 1000;
    }
    return (highestValue / 5000).ceilToDouble() * 5000;
  }

  static IconData _iconForLine(OrderLine line) {
    switch (line.artType) {
      case ProductArtType.aquafina:
        return Icons.water_drop_outlined;
      case ProductArtType.coke:
        return Icons.local_drink_rounded;
      case ProductArtType.lays:
        return Icons.lunch_dining_rounded;
      case ProductArtType.galaxy:
        return Icons.egg_alt_rounded;
      case ProductArtType.kelloggs:
        return Icons.breakfast_dining_rounded;
      case ProductArtType.dove:
        return Icons.spa_outlined;
      case ProductArtType.colgate:
        return Icons.health_and_safety_outlined;
      case ProductArtType.dettol:
        return Icons.cleaning_services_outlined;
      case ProductArtType.tide:
        return Icons.local_laundry_service_outlined;
    }
  }

  static List<Color> _colorsForLine(OrderLine line) {
    switch (line.artType) {
      case ProductArtType.aquafina:
        return const [AppColors.primary, AppColors.primarySoft];
      case ProductArtType.coke:
        return const [AppColors.danger, AppColors.dangerLight];
      case ProductArtType.lays:
        return const [AppColors.ink, AppColors.textLight];
      case ProductArtType.galaxy:
        return const [AppColors.primaryBright, AppColors.primarySoft];
      case ProductArtType.kelloggs:
        return const [AppColors.ink, AppColors.textLight];
      case ProductArtType.dove:
        return const [Color(0xFF111111), Color(0xFF111111)];
      case ProductArtType.colgate:
        return const [AppColors.textBody, AppColors.border];
      case ProductArtType.dettol:
        return const [Color(0xFF111111), Color(0xFF111111)];
      case ProductArtType.tide:
        return const [AppColors.ink, AppColors.textLight];
    }
  }

  static String _dateLabel(DateTime date) {
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
}
