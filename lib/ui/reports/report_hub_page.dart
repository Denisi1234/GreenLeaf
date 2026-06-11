import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../business_category_config.dart';
import '../models/customer_data.dart';
import '../../service/expense_model.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../models/product_item.dart';
import '../products/inventory_product_item.dart';
import '../widgets/market_shared_widgets.dart';

// ignore_for_file: unused_element

enum _ReportPeriod { today, week, month, allTime }

extension _ReportPeriodLabel on _ReportPeriod {
  String get label {
    switch (this) {
      case _ReportPeriod.today:
        return 'Today';
      case _ReportPeriod.week:
        return 'This Week';
      case _ReportPeriod.month:
        return 'This Month';
      case _ReportPeriod.allTime:
        return 'All Time';
    }
  }

  String get shortLabel {
    switch (this) {
      case _ReportPeriod.today:
        return 'Today';
      case _ReportPeriod.week:
        return 'Week';
      case _ReportPeriod.month:
        return 'Month';
      case _ReportPeriod.allTime:
        return 'All';
    }
  }
}

String _kLabel(num value) {
  if (value <= 0) return '0K';
  final thousands = value.toDouble() / 1000;
  return '${thousands.round()}K';
}

class ReportHubPage extends StatefulWidget {
  const ReportHubPage({super.key});

  static const MethodChannel _shareChannel =
      MethodChannel('trackmauzo/report_share');

  static const Color _bg = Color(0xFFF6F8FC);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFE6EBF2);
  static const Color _blue = Color(0xFF1E67E8);

  @override
  State<ReportHubPage> createState() => _ReportHubPageState();
}

class _ReportHubPageState extends State<ReportHubPage> {
  bool _isDownloading = false;
  _ReportPeriod _selectedPeriod = _ReportPeriod.month;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final report =
        _buildReportSnapshot(store, _selectedPeriod, config.category);
    final baseTheme = Theme.of(context);
    final theme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: ReportHubPage._bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: _ReportControlsBar(
                  dateRange: report.dateRangeLabel,
                  periodLabel: _selectedPeriod.shortLabel,
                  isDownloading: _isDownloading,
                  onPeriodSelected: (period) {
                    setState(() => _selectedPeriod = period);
                  },
                  onDownloadTap: () => _downloadReport(context),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 18),
                            _ExecutiveSummaryCard(
                              title: _reportOverviewTitle(config.category),
                              summary: _buildExecutiveSummary(
                                report,
                                store.profile,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _MetricGrid(metrics: report.metrics),
                            const SizedBox(height: 18),
                            _SectionCard(
                              title: 'Top Selling Products',
                              trailing: _LinkAction(
                                label: 'View All',
                                onTap: () =>
                                    _showTopSellingProducts(context, report),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: _TopSellingProductsList(
                                  products: report.allProducts.take(5).toList(),
                                  emptyMessage:
                                      'No completed sales in this period.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildExecutiveSummary(
    _ReportSnapshot report,
    AppProfileData profile,
  ) {
    final revenue = _metricByTitle(report.metrics, 'Total Revenue') ??
        const _MetricData(
          title: 'Total Revenue',
          value: '0',
          icon: Icons.payments_outlined,
          iconColor: ReportHubPage._blue,
          tint: ReportHubPage._bg,
          valueColor: ReportHubPage._ink,
          deltaText: null,
          deltaLabel: '',
          deltaIsPositive: null,
        );
    final orders = _metricByTitle(report.metrics, 'Total Orders') ??
        const _MetricData(
          title: 'Total Orders',
          value: '0',
          icon: Icons.shopping_bag_outlined,
          iconColor: ReportHubPage._blue,
          tint: ReportHubPage._bg,
          valueColor: ReportHubPage._ink,
          deltaText: null,
          deltaLabel: '',
          deltaIsPositive: null,
        );
    final customers = _metricByTitle(report.metrics, 'New Customers') ??
        const _MetricData(
          title: 'New Customers',
          value: '0',
          icon: Icons.people_alt_outlined,
          iconColor: ReportHubPage._blue,
          tint: ReportHubPage._bg,
          valueColor: ReportHubPage._ink,
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
        'Your store performed well this ${_selectedPeriod.shortLabel.toLowerCase()}! '
        'Revenue $revenueVerb by $revenueChange compared to last ${_selectedPeriod.shortLabel.toLowerCase()}. '
        'You received ${customers.value} new customers, a $customerChange $customerVerb. '
        'Total orders reached ${orders.value}.';
  }

  _MetricData? _metricByTitle(List<_MetricData> metrics, String title) {
    for (final metric in metrics) {
      if (metric.title == title) return metric;
    }
    return null;
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<_StockAlertItem> _lowStockItems(PosLocalStore store) {
    final items = store.inventory
        .where((item) => item.stockCount <= 20)
        .map(
          (item) => _StockAlertItem(
            name: item.name,
            category: item.category,
            stockCount: item.stockCount,
            statusLabel: item.stockCount <= 0
                ? 'Out of stock'
                : '${item.stockCount} left',
            severity: item.stockCount <= 5
                ? _StockAlertSeverity.high
                : _StockAlertSeverity.medium,
          ),
        )
        .toList()
      ..sort((left, right) => left.stockCount.compareTo(right.stockCount));

    return items.take(4).toList();
  }

  List<_TrendPoint> _buildProfitTrendPoints({
    required Map<DateTime, double> dailyRevenue,
    required Map<DateTime, double> dailyExpenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    if (totalDays <= 0) {
      return <_TrendPoint>[
        _TrendPoint(
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
        return _TrendPoint(
          label: _trendLabel(day),
          value: value,
          displayValue: _moneyLabelSigned(value),
        );
      });
    }

    const bucketCount = 6;
    final bucketSize = (totalDays / bucketCount).ceil();
    final points = <_TrendPoint>[];

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
        _TrendPoint(
          label: _trendBucketLabel(bucketStart, bucketEnd),
          value: value,
          displayValue: _moneyLabelSigned(value),
        ),
      );
    }

    return points.isEmpty
        ? <_TrendPoint>[
            _TrendPoint(
              label: _trendLabel(startDate),
              value: 0,
              displayValue: _compactAmount(0),
            ),
          ]
        : points;
  }

  String _moneyLabelSigned(double amount) {
    final formatted = _formatWithCommas(amount.abs());
    if (amount < 0) return '-TSH $formatted';
    return 'TSH $formatted';
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    Uint8List? pdfBytes;
    final fileName = _reportFileName();
    final store = context.read<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final report = _buildReportSnapshot(
      store,
      _selectedPeriod,
      config.category,
    );
    try {
      pdfBytes = await _buildSalesReportPdfBytes(
        store,
        report,
        store.profile,
      );
      final shared = await _shareReportPdf(pdfBytes, fileName);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shared
                ? 'Share sheet opened for $fileName'
                : 'Share dialog unavailable on this device.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share report: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showTopSellingProducts(
    BuildContext context,
    _ReportSnapshot report,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: MarketSurfaceCard(
              borderColor: ReportHubPage._border,
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarketSectionHeader(
                      title: 'Top Selling Products',
                      trailing: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: ReportHubPage._muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: report.allProducts.isEmpty
                          ? const Center(
                              child: Text(
                                'No completed sales in this period.',
                                style: TextStyle(
                                  color: ReportHubPage._muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: report.allProducts.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: ReportHubPage._border,
                              ),
                              itemBuilder: (context, index) {
                                return _ProductRow(
                                  data: report.allProducts[index],
                                  rank: index + 1,
                                  highlightTop: index == 0,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _ReportSnapshot _buildReportSnapshot(
    PosLocalStore store,
    _ReportPeriod period,
    BusinessCategory category,
  ) {
    final orders = store.orders;
    final range = _resolveReportRange(orders, period);

    final ordersInRange = orders.where((order) {
      final orderDate = DateTime.tryParse(order.dateTime);
      if (orderDate == null) return false;
      final day = DateTime(orderDate.year, orderDate.month, orderDate.day);
      return !day.isBefore(range.start) && !day.isAfter(range.end);
    }).toList();

    final dailyRevenue = <DateTime, double>{};
    final dailyExpenses = <DateTime, double>{};
    final productTally = <String, _ProductTally>{};

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
          () => _ProductTally(
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

    final currentStats = _buildPdfStats(
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
    final previousStats = _buildPdfStats(
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
    final inventoryUnits =
        store.inventory.fold<int>(0, (sum, item) => sum + item.stockCount);
    final lowStockCount =
        store.inventory.where((item) => item.stockCount <= 20).length;
    final expiringSoonCount = _expiringSoonCount(store.inventory);
    final prescriptionCount = _metadataValueCount(
      store.inventory,
      'prescription_flag',
      expectedValue: 'yes',
    );
    final warrantyTrackedCount = _metadataNonEmptyCount(
      store.inventory,
      ['serial_number', 'warranty_months'],
    );
    final barcodeReadyCount =
        _metadataNonEmptyCount(store.inventory, ['barcode']);
    final locationBinsCount =
        _metadataDistinctCount(store.inventory, ['location_bin']);
    final topBrandLabel =
        _topMetadataLabel(store.inventory, ['brand']) ?? 'No brand data';
    final peakHourLabel = _peakHourLabel(ordersInRange);
    final categoryMixLabel = _categoryMixLabel(store.inventory);
    final highValueOrdersCount =
        ordersInRange.where((order) => order.total >= averageOrderValue).length;
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
          (product) => _ProductData(
            title: product.title,
            orders: '${product.quantity} sold',
            amount: _moneyLabel(product.revenue),
            icon: product.icon,
            colors: product.colors,
          ),
        )
        .toList();

    return _ReportSnapshot(
      category: category,
      periodLabel: period.label,
      dateRangeLabel: range.label,
      startDate: range.start,
      endDate: range.end,
      metrics: _buildCategoryMetrics(
        category: category,
        period: period,
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        totalExpenses: totalExpenses,
        totalProfit: totalProfit,
        averageOrderValue: averageOrderValue,
        lowStockCount: lowStockCount,
        inventoryUnits: inventoryUnits,
        expiringSoonCount: expiringSoonCount,
        prescriptionCount: prescriptionCount,
        warrantyTrackedCount: warrantyTrackedCount,
        barcodeReadyCount: barcodeReadyCount,
        locationBinsCount: locationBinsCount,
        topBrandLabel: topBrandLabel,
        peakHourLabel: peakHourLabel,
        categoryMixLabel: categoryMixLabel,
        highValueOrdersCount: highValueOrdersCount,
        topProductLabel: topProductLabel,
        inventoryItems: store.inventory,
        currentStats: currentStats,
        previousStats: previousStats,
      ),
      trendPoints: trendPoints,
      profitTrendPoints: profitTrendPoints,
      products: productData,
      allProducts: topProducts
          .map(
            (product) => _ProductData(
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

  String _comparisonPeriodLabel(_ReportPeriod period) {
    switch (period) {
      case _ReportPeriod.today:
        return 'vs yesterday';
      case _ReportPeriod.week:
        return 'vs last week';
      case _ReportPeriod.month:
        return 'vs last month';
      case _ReportPeriod.allTime:
        return 'vs previous period';
    }
  }

  String? _comparisonPercentLabel(num current, num previous) {
    if (previous == 0) {
      if (current == 0) return null;
      return '+100%';
    }

    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '-';
    final rounded = change.abs().toStringAsFixed(change.abs() >= 10 ? 0 : 1);
    return '$sign$rounded%';
  }

  String _reportOverviewTitle(BusinessCategory category) {
    return switch (category) {
      BusinessCategory.pharmacy => 'Pharmacy Intelligence',
      BusinessCategory.electronics => 'Electronics Intelligence',
      BusinessCategory.retail => 'Retail Operations Intelligence',
    };
  }

  String _categoryFocusSentence(BusinessCategory category) {
    return switch (category) {
      BusinessCategory.pharmacy =>
        'This report emphasizes expiry control, prescription demand, and margin protection for medicine sales.',
      BusinessCategory.electronics =>
        'This report emphasizes high-value devices, warranty readiness, and brand performance across the catalog.',
      BusinessCategory.retail =>
        'This report emphasizes basket size, fast-moving stock, markdown pressure, and reorder timing for store-floor decisions.',
    };
  }

  String _forecastCategoryHint(BusinessCategory category) {
    return switch (category) {
      BusinessCategory.pharmacy =>
        'Expiry and prescription demand are the main near-term forecast risks.',
      BusinessCategory.electronics =>
        'Warranty registration and premium device mix drive the forecast band.',
      BusinessCategory.retail =>
        'Demand should stay anchored around basket size, fast movers, and markdown activity.',
    };
  }

  List<_MetricData> _buildCategoryMetrics({
    required BusinessCategory category,
    required _ReportPeriod period,
    required double totalRevenue,
    required int totalOrders,
    required double totalExpenses,
    required double totalProfit,
    required double averageOrderValue,
    required int lowStockCount,
    required int inventoryUnits,
    required int expiringSoonCount,
    required int prescriptionCount,
    required int warrantyTrackedCount,
    required int barcodeReadyCount,
    required int locationBinsCount,
    required String topBrandLabel,
    required String peakHourLabel,
    required String categoryMixLabel,
    required int highValueOrdersCount,
    required String topProductLabel,
    required List<InventoryProductItem> inventoryItems,
    required _PdfReportStats currentStats,
    required _PdfReportStats previousStats,
  }) {
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
    final marginDelta = _comparisonPercentLabel(
      totalProfit,
      previousStats.revenue - previousStats.totalExpenses,
    );

    List<_MetricData> withColors(List<_MetricData> items) {
      return items
          .map(
            (item) => _MetricData(
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

    return switch (category) {
      BusinessCategory.pharmacy => withColors([
          _MetricData(
            title: 'Revenue',
            value: _moneyLabel(totalRevenue),
            icon: Icons.trending_up_rounded,
            iconColor: primaryColor,
            tint: primaryTint,
            valueColor: primaryColor,
            deltaText: revenueDelta,
            deltaLabel: comparisonLabel,
            deltaIsPositive: currentStats.revenue >= previousStats.revenue,
          ),
          _MetricData(
            title: 'Expiring Soon',
            value: expiringSoonCount.toString(),
            icon: Icons.event_busy_rounded,
            iconColor: secondaryColor,
            tint: config.surfaceTintColor,
            valueColor: secondaryColor,
            deltaText: null,
            deltaLabel: '30-day watchlist',
            deltaIsPositive: null,
          ),
          _MetricData(
            title: 'Prescription Items',
            value: prescriptionCount.toString(),
            icon: Icons.medication_liquid_outlined,
            iconColor: primaryColor,
            tint: primaryTint,
            valueColor: primaryColor,
            deltaText: null,
            deltaLabel: 'Medicines flagged',
            deltaIsPositive: null,
          ),
          _MetricData(
            title: 'Margin',
            value: _moneyLabelSigned(totalProfit),
            icon: Icons.account_balance_wallet_outlined,
            iconColor:
                totalProfit >= 0 ? primaryColor : const Color(0xFFDC2626),
            tint: totalProfit >= 0 ? primaryTint : const Color(0xFFFDECEC),
            valueColor:
                totalProfit >= 0 ? primaryColor : const Color(0xFFDC2626),
            deltaText: marginDelta,
            deltaLabel: comparisonLabel,
            deltaIsPositive: totalProfit >=
                (previousStats.revenue - previousStats.totalExpenses),
          ),
        ]),
      BusinessCategory.electronics => withColors([
          _MetricData(
            title: 'Revenue',
            value: _moneyLabel(totalRevenue),
            icon: Icons.trending_up_rounded,
            iconColor: primaryColor,
            tint: primaryTint,
            valueColor: primaryColor,
            deltaText: revenueDelta,
            deltaLabel: comparisonLabel,
            deltaIsPositive: currentStats.revenue >= previousStats.revenue,
          ),
          _MetricData(
            title: 'Warranty Items',
            value: warrantyTrackedCount.toString(),
            icon: Icons.verified_user_outlined,
            iconColor: secondaryColor,
            tint: config.surfaceTintColor,
            valueColor: secondaryColor,
            deltaText: null,
            deltaLabel: 'Tracked devices',
            deltaIsPositive: null,
          ),
          _MetricData(
            title: 'High-Ticket Orders',
            value: highValueOrdersCount.toString(),
            icon: Icons.payments_outlined,
            iconColor: primaryColor,
            tint: primaryTint,
            valueColor: primaryColor,
            deltaText: orderDelta,
            deltaLabel: comparisonLabel,
            deltaIsPositive:
                currentStats.orderCount >= previousStats.orderCount,
          ),
          _MetricData(
            title: 'Top Brand',
            value: topBrandLabel,
            icon: Icons.branding_watermark_outlined,
            iconColor: secondaryColor,
            tint: config.surfaceTintColor,
            valueColor: primaryColor,
            deltaText: null,
            deltaLabel: 'Brand mix',
            deltaIsPositive: null,
          ),
          _MetricData(
            title: 'Category Mix',
            value: categoryMixLabel,
            icon: Icons.grid_view_rounded,
            iconColor: secondaryColor,
            tint: config.surfaceTintColor,
            valueColor: primaryColor,
            deltaText: null,
            deltaLabel: 'Shelf spread',
            deltaIsPositive: null,
          ),
        ]),
      BusinessCategory.retail => withColors([
          _MetricData(
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
          _MetricData(
            title: 'Transactions',
            value: totalOrders.toString(),
            icon: Icons.shopping_bag_rounded,
            iconColor: secondaryColor,
            tint: config.surfaceTintColor,
            valueColor: secondaryColor,
            deltaText: orderDelta,
            deltaLabel: comparisonLabel,
            deltaIsPositive:
                currentStats.orderCount >= previousStats.orderCount,
          ),
          _MetricData(
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
          _MetricData(
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
        ]),
    };
  }

  String _averagePrepLabel(List<InventoryProductItem> items) {
    final minutes = <int>[];
    for (final item in items) {
      final raw = item.categoryData['prep_time_minutes']?.toString().trim();
      final parsed = int.tryParse(raw ?? '');
      if (parsed != null && parsed > 0) {
        minutes.add(parsed);
      }
    }
    if (minutes.isEmpty) return 'Prep data';
    final average = minutes.reduce((a, b) => a + b) / minutes.length;
    return '${average.round()} mins';
  }

  int _expiringSoonCount(List<InventoryProductItem> items) {
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

  int _metadataValueCount(
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

  int _metadataNonEmptyCount(
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

  int _metadataDistinctCount(
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

  String? _topMetadataLabel(
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

  String _peakHourLabel(List<CompletedOrder> orders) {
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

  String _formatHour(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12 $suffix';
  }

  String _categoryMixLabel(List<InventoryProductItem> items) {
    final categories = items
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet();
    if (categories.isEmpty) return 'No mix data';
    return '${categories.length} categories';
  }

  DateTime? _parseDateMetadata(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString().trim());
  }

  Future<Uint8List> _buildSalesReportPdfBytes(
    PosLocalStore store,
    _ReportSnapshot report,
    AppProfileData profile,
  ) async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final logoImage = await _loadPdfLogoImage(profile);
    final generatedAt = DateTime.now();

    final currentOrders =
        _ordersWithinRange(store.orders, report.startDate, report.endDate);
    final previousRange =
        _previousComparableRange(report.startDate, report.endDate);
    final previousOrders = _ordersWithinRange(
      store.orders,
      previousRange.start,
      previousRange.end,
    );
    final currentExpenses = _expensesWithinRange(
      store.expenses,
      report.startDate,
      report.endDate,
    );
    final previousExpenses = _expensesWithinRange(
      store.expenses,
      previousRange.start,
      previousRange.end,
    );
    final currentStats = _buildPdfStats(
      orders: currentOrders,
      customers: store.customers,
      expenses: currentExpenses,
      startDate: report.startDate,
      endDate: report.endDate,
    );
    final previousStats = _buildPdfStats(
      orders: previousOrders,
      customers: store.customers,
      expenses: previousExpenses,
      startDate: previousRange.start,
      endDate: previousRange.end,
    );
    final reportTitle = _reportTitleFor(report);
    final executiveSummary = _buildPdfExecutiveSummary(
      report: report,
      stats: currentStats,
      previousStats: previousStats,
      profile: profile,
      lowStockCount: _lowStockItems(store).length,
    );
    final forecast = _buildForecastSnapshot(
      report: report,
      currentStats: currentStats,
      previousStats: previousStats,
      store: store,
    );
    final conclusion = _buildPdfConclusion(
      report,
      currentStats,
      _lowStockItems(store).length,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 26),
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: _pdfReportHeader(
                  reportTitle: reportTitle,
                  report: report,
                  profile: profile,
                  logoImage: logoImage,
                ),
              )
            : pw.SizedBox(height: 0),
        build: (context) => [
          _pdfIntroSection(
            executiveSummary,
            report,
            currentStats,
            previousStats,
          ),
          pw.SizedBox(height: 12),
          _pdfHighlightsSection(report, currentStats, previousStats, store),
          pw.SizedBox(height: 12),
          _pdfSectionDivider(),
          _pdfSectionTitle('1. Key Performance Indicators'),
          pw.SizedBox(height: 8),
          _pdfKpiTable(currentStats, previousStats),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('2. Sales Trends'),
          pw.SizedBox(height: 8),
          _pdfSalesTrendSection(report, currentStats),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('3. Top Selling Products'),
          pw.SizedBox(height: 8),
          _pdfProductTable(report.products),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('4. Customer Insights'),
          pw.SizedBox(height: 8),
          _pdfCustomerInsightsSection(currentOrders, store, currentStats),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('5. Expense Analysis'),
          pw.SizedBox(height: 8),
          _pdfExpenseAnalysisSection(currentExpenses),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('6. Forecast & Planning Outlook'),
          pw.SizedBox(height: 8),
          _pdfForecastSection(forecast),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('7. Conclusion'),
          pw.SizedBox(height: 8),
          _pdfConclusionSection(conclusion),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('8. References'),
          pw.SizedBox(height: 8),
          _pdfReferencesSection(report),
        ],
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _formatPdfDateTime(generatedAt),
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                '${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  Future<pw.ImageProvider?> _loadPdfLogoImage(AppProfileData profile) async {
    final path = profile.logoPath?.trim();
    if (path == null || path.isEmpty) return null;

    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _shareReportPdf(Uint8List bytes, String fileName) async {
    if (Platform.isAndroid) {
      final result = await ReportHubPage._shareChannel.invokeMethod<bool>(
        'sharePdfFromBytes',
        <String, Object?>{
          'fileName': fileName,
          'bytes': bytes,
          'subject': 'Store Report',
          'text': 'Store report attached',
        },
      );
      return result ?? false;
    }

    await Printing.sharePdf(bytes: bytes, filename: fileName);
    return true;
  }

  pw.Widget _pdfReportHeader({
    required String reportTitle,
    required _ReportSnapshot report,
    required AppProfileData profile,
    required pw.ImageProvider? logoImage,
  }) {
    final storeName =
        profile.storeName.trim().isEmpty ? 'Store report' : profile.storeName;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromHex('#DDE4EE'),
          width: 0.8,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logoImage != null) ...[
            pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F3F6FB'),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 12,
                verticalRadius: 12,
                child: pw.Image(logoImage, fit: pw.BoxFit.cover),
              ),
            ),
            pw.SizedBox(width: 12),
          ] else ...[
            pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EAF1FF'),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Center(
                child: pw.Text(
                  storeName.isNotEmpty ? storeName[0].toUpperCase() : 'R',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#1E67E8'),
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  storeName,
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0F172A'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1E67E8'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  report.dateRangeLabel,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Prepared for management review',
                  style: const pw.TextStyle(
                    fontSize: 8.8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  report.periodLabel,
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#334155'),
                    fontSize: 10.2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${report.category.displayName} intelligence brief',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfIntroSection(
    String executiveSummary,
    _ReportSnapshot report,
    _PdfReportStats currentStats,
    _PdfReportStats previousStats,
  ) {
    final revenueDelta =
        _changeLabel(currentStats.revenue, previousStats.revenue);
    final orderDelta =
        _changeLabel(currentStats.orderCount, previousStats.orderCount);
    final margin = currentStats.revenue - currentStats.totalExpenses;
    final marginLabel =
        margin >= 0 ? _moneyLabel(margin) : '-${_moneyLabel(margin.abs())}';
    final marginTone = margin >= 0 ? 'Healthy' : 'Under pressure';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${report.category.displayName} management summary',
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            executiveSummary,
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfIntroStat(
                  'Revenue shift',
                  revenueDelta,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _pdfIntroStat(
                  'Orders',
                  orderDelta,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _pdfIntroStat(
                  'Margin',
                  '$marginTone $marginLabel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfIntroStat(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7.8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13.5,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#0F172A'),
      ),
    );
  }

  pw.Widget _pdfSectionDivider() {
    return pw.Container(
      height: 1,
      margin: const pw.EdgeInsets.only(top: 2),
      color: PdfColor.fromHex('#EEF3F8'),
    );
  }

  pw.Widget _pdfKpiTable(
    _PdfReportStats currentStats,
    _PdfReportStats previousStats,
  ) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          _pdfTableCell('Metric', bold: true),
          _pdfTableCell('Value', bold: true),
          _pdfTableCell('Change from Previous', bold: true),
        ],
      ),
      _pdfKpiRow(
        'Total Revenue',
        _moneyLabel(currentStats.revenue),
        _changeLabel(currentStats.revenue, previousStats.revenue),
      ),
      _pdfKpiRow(
        'Total Orders',
        currentStats.orderCount.toString(),
        _changeLabel(currentStats.orderCount, previousStats.orderCount),
      ),
      _pdfKpiRow(
        'Average Order Value',
        _moneyLabel(currentStats.averageOrderValue),
        _changeLabel(
          currentStats.averageOrderValue,
          previousStats.averageOrderValue,
        ),
      ),
      _pdfKpiRow(
        'New Customers',
        currentStats.newCustomers.toString(),
        _changeLabel(currentStats.newCustomers, previousStats.newCustomers),
      ),
      _pdfKpiRow(
        'Returning Customers',
        currentStats.returningCustomers.toString(),
        _changeLabel(
          currentStats.returningCustomers,
          previousStats.returningCustomers,
        ),
      ),
    ];

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('#EDF2F7'),
        width: 0.35,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2.2),
      },
      children: rows,
    );
  }

  pw.TableRow _pdfKpiRow(
    String label,
    String value,
    String change,
  ) {
    return pw.TableRow(
      children: [
        _pdfTableCell(label),
        _pdfTableCell(value),
        _pdfTableCell(change),
      ],
    );
  }

  pw.Widget _pdfSalesTrendSection(
    _ReportSnapshot report,
    _PdfReportStats stats,
  ) {
    final firstPoint =
        report.trendPoints.isNotEmpty ? report.trendPoints.first : null;
    final lastPoint =
        report.trendPoints.isNotEmpty ? report.trendPoints.last : null;
    final peakPoint = report.trendPoints.isEmpty
        ? null
        : report.trendPoints.reduce(
            (a, b) => a.value >= b.value ? a : b,
          );
    final averageTrend = report.trendPoints.isEmpty
        ? 0.0
        : report.trendPoints.fold<double>(
              0,
              (sum, point) => sum + point.value,
            ) /
            report.trendPoints.length;
    final direction = firstPoint == null || lastPoint == null
        ? 'The period does not have enough sales activity for a directional trend.'
        : lastPoint.value >= firstPoint.value
            ? 'Revenue closed stronger than it started, which suggests sales momentum improved over the selected period.'
            : 'Revenue ended below its starting point, suggesting a softer close to the selected period.';

    final peakText = peakPoint == null
        ? 'No completed sales were recorded in the period.'
        : 'The highest revenue day was ${peakPoint.label} at ${peakPoint.displayValue}.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Sales revenue showed ${_trendDirectionWord(firstPoint, lastPoint)} across the selected period. $peakText',
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Average daily revenue: ${_moneyLabel(averageTrend)}',
            style: const pw.TextStyle(
              fontSize: 9.8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            direction,
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#EDF2F7'),
              width: 0.35,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  _pdfTableCell('Date', bold: true),
                  _pdfTableCell('Revenue', bold: true),
                ],
              ),
              ...report.trendPoints.map(
                (point) => pw.TableRow(
                  children: [
                    _pdfTableCell(point.label),
                    _pdfTableCell(point.displayValue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfCustomerInsightsSection(
    List<CompletedOrder> orders,
    PosLocalStore store,
    _PdfReportStats stats,
  ) {
    final activeCustomerNames = orders
        .map((order) => order.customerName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet();
    final activeCustomers = activeCustomerNames.length;
    final repeatCustomers = orders
        .where((order) => (order.customerName ?? '').trim().isNotEmpty)
        .fold<Map<String, int>>({}, (map, order) {
          final name = order.customerName!.trim();
          map[name] = (map[name] ?? 0) + 1;
          return map;
        })
        .values
        .where((count) => count > 1)
        .length;
    final customerStats = store.customerStats();
    final topCustomerName = customerStats['topName'] as String?;
    final topCustomerValue =
        (customerStats['topValue'] as num?)?.toDouble() ?? 0.0;
    final createdThisPeriod = store.customers
        .where((customer) =>
            !customer.createdAt.isBefore(stats.startDate) &&
            !customer.createdAt
                .isAfter(stats.endDate.add(const Duration(days: 1))))
        .length;

    final insight = topCustomerName == null || topCustomerName.trim().isEmpty
        ? 'Customer records are present, but there is no clear top customer yet.'
        : '$topCustomerName generated ${_moneyLabel(topCustomerValue)} in lifetime sales, which makes them a valuable repeat-buyer to keep engaged.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer activity remained at $activeCustomers active customer${activeCustomers == 1 ? '' : 's'} in this period, with $repeatCustomers repeat buyer${repeatCustomers == 1 ? '' : 's'} and $createdThisPeriod newly registered customer${createdThisPeriod == 1 ? '' : 's'}.',
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            insight,
            style: const pw.TextStyle(
              fontSize: 10.0,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#EDF2F7'),
              width: 0.35,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.7),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  _pdfTableCell('Customer insight', bold: true),
                  _pdfTableCell('Value', bold: true),
                ],
              ),
              _pdfTableRow(
                  'Registered customers', store.customers.length.toString()),
              _pdfTableRow('Active customers', activeCustomers.toString()),
              _pdfTableRow('Returning customers', repeatCustomers.toString()),
              _pdfTableRow(
                'Top customer',
                topCustomerName == null || topCustomerName.trim().isEmpty
                    ? 'Not available'
                    : '$topCustomerName (${_moneyLabel(topCustomerValue)})',
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Customer loyalty continues to matter because repeat buyers reduce acquisition pressure and usually respond well to small reminders, bundles, or limited-time offers.',
            style: const pw.TextStyle(
              fontSize: 10.0,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        _pdfTableCell(label),
        _pdfTableCell(value),
      ],
    );
  }

  pw.Widget _pdfExpenseAnalysisSection(List<Expense> expenses) {
    final total =
        expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final categories = <String, double>{};
    for (final expense in expenses) {
      categories[expense.category] =
          (categories[expense.category] ?? 0) + expense.amount;
    }
    final topCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topExpense = topCategories.isEmpty ? null : topCategories.first;

    final expenseSummary = total <= 0
        ? 'No expenses were recorded in the selected period.'
        : 'Total expenses for the selected period were ${_moneyLabel(total)}. Inventory, rent, and utilities should be monitored closely because they usually take the largest share of operating cost.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            expenseSummary,
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#E3EAF2'),
              width: 0.45,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.4),
              1: pw.FlexColumnWidth(1.6),
              2: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                children: [
                  _pdfTableCell('Category', bold: true),
                  _pdfTableCell('Amount', bold: true),
                  _pdfTableCell('% of total', bold: true),
                ],
              ),
              ...topCategories.map(
                (entry) => pw.TableRow(
                  children: [
                    _pdfTableCell(entry.key),
                    _pdfTableCell(_moneyLabel(entry.value)),
                    _pdfTableCell(
                      total <= 0
                          ? '0%'
                          : '${((entry.value / total) * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
              pw.TableRow(
                children: [
                  _pdfTableCell('Total expenses', bold: true),
                  _pdfTableCell(_moneyLabel(total), bold: true),
                  _pdfTableCell('100%', bold: true),
                ],
              ),
            ],
          ),
          if (topExpense != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Largest category: ${topExpense.key} at ${_moneyLabel(topExpense.value)}.',
              style: const pw.TextStyle(
                fontSize: 10.0,
                color: PdfColors.grey800,
                lineSpacing: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfConclusionSection(String conclusion) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Text(
        conclusion,
        style: const pw.TextStyle(
          fontSize: 10.2,
          color: PdfColors.grey800,
          lineSpacing: 4,
        ),
      ),
    );
  }

  pw.Widget _pdfReferencesSection(_ReportSnapshot report) {
    final reportLabel = report.dateRangeLabel;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pdfBullet('Internal POS Sales Data - $reportLabel'),
          pw.SizedBox(height: 4),
          _pdfBullet('Internal Customer Database - $reportLabel'),
          pw.SizedBox(height: 4),
          _pdfBullet('Internal Expense Records - $reportLabel'),
          pw.SizedBox(height: 4),
          _pdfBullet('Store profile and branding settings inside the app'),
        ],
      ),
    );
  }

  String _trendDirectionWord(_TrendPoint? firstPoint, _TrendPoint? lastPoint) {
    if (firstPoint == null || lastPoint == null) {
      return 'limited movement';
    }
    if (lastPoint.value > firstPoint.value) return 'a positive momentum';
    if (lastPoint.value < firstPoint.value) return 'a softer finish';
    return 'steady movement';
  }

  String _reportTitleFor(_ReportSnapshot report) {
    if (report.periodLabel == 'This Month') {
      return '${report.category.displayName} Intelligence Report - ${_monthYearLabel(report.endDate)}';
    }
    if (report.periodLabel == 'Today') {
      return '${report.category.displayName} Intelligence Report - ${_dateLabel(report.endDate)}';
    }
    if (report.periodLabel == 'This Week') {
      return '${report.category.displayName} Intelligence Report - ${_dateLabel(report.startDate)} - ${_dateLabel(report.endDate)}';
    }
    return '${report.category.displayName} Intelligence Report - ${report.dateRangeLabel}';
  }

  String _buildPdfExecutiveSummary({
    required _ReportSnapshot report,
    required _PdfReportStats stats,
    required _PdfReportStats previousStats,
    required AppProfileData profile,
    required int lowStockCount,
  }) {
    final storeName = profile.storeName.trim().isEmpty
        ? 'The store'
        : profile.storeName.trim();
    final focus = _categoryFocusSentence(report.category);
    final revenueChange = _changeLabel(stats.revenue, previousStats.revenue);
    final orderChange =
        _changeLabel(stats.orderCount, previousStats.orderCount);
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

  String _buildPdfConclusion(
    _ReportSnapshot report,
    _PdfReportStats stats,
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

  _ForecastSnapshot _buildForecastSnapshot({
    required _ReportSnapshot report,
    required _PdfReportStats currentStats,
    required _PdfReportStats previousStats,
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
    final lowStockCount = _lowStockItems(store).length;
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

    return _ForecastSnapshot(
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

  double _trendBias(List<_TrendPoint> points) {
    if (points.length < 2) return 0.0;
    final first = points.first.value;
    final last = points.last.value;
    if (first <= 0) {
      return last > 0 ? 0.12 : 0.0;
    }
    return ((last - first) / first).clamp(-0.25, 0.25).toDouble();
  }

  _PdfReportStats _buildPdfStats({
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

    return _PdfReportStats(
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

  String _changeLabel(num current, num previous) {
    if (previous == 0) {
      if (current == 0) return '0%';
      return '+100% vs previous';
    }
    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.abs().toStringAsFixed(change.abs() >= 10 ? 0 : 1)}% vs previous';
  }

  String _monthYearLabel(DateTime date) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
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

  _ReportRange _previousComparableRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    final previousEnd = start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: days - 1));
    return _ReportRange(
      start: previousStart,
      end: previousEnd,
      label: '${_dateLabel(previousStart)} - ${_dateLabel(previousEnd)}',
    );
  }

  pw.Widget _pdfHeader(
    _ReportSnapshot report,
    AppProfileData profile,
    pw.ImageProvider? logoImage,
  ) {
    final storeName =
        profile.storeName.trim().isEmpty ? 'Store report' : profile.storeName;
    final ownerName =
        profile.ownerName.trim().isEmpty ? 'Owner not set' : profile.ownerName;
    final contact = profile.contactNumber.trim().isEmpty
        ? 'Contact not set'
        : profile.contactNumber;
    final email = profile.emailAddress.trim().isEmpty
        ? 'Email not set'
        : profile.emailAddress;
    final address = profile.physicalAddress.trim().isEmpty
        ? 'Address not set'
        : profile.physicalAddress;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logoImage != null) ...[
          pw.Container(
            width: 52,
            height: 52,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F3F6FB'),
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 14,
              verticalRadius: 14,
              child: pw.Image(
                logoImage,
                fit: pw.BoxFit.cover,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
        ] else ...[
          pw.Container(
            width: 52,
            height: 52,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EAF1FF'),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Center(
              child: pw.Text(
                storeName.isNotEmpty ? storeName[0].toUpperCase() : 'R',
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#1E67E8'),
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                storeName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0F172A'),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Store Report',
                style: pw.TextStyle(
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                report.dateRangeLabel,
                style: const pw.TextStyle(
                  fontSize: 10.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '$ownerName | $contact | $email',
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                address,
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
          ),
          child: pw.Text(
            report.periodLabel,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#0F172A'),
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfMetricRow(List<_MetricData> metrics) {
    return pw.Row(
      children: metrics
          .map((metric) => pw.Expanded(child: _pdfMetricCard(metric)))
          .toList(),
    );
  }

  pw.Widget _pdfMetricCard(_MetricData metric) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 4),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 28,
            height: 28,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex(_hexForMetric(metric.tint)),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                _metricGlyph(metric.icon),
                style: pw.TextStyle(
                  color: PdfColor.fromHex(_hexForMetric(metric.iconColor)),
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            metric.title,
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            metric.value,
            style: pw.TextStyle(
              fontSize: 14.5,
              color: PdfColor.fromHex(_hexForMetric(metric.valueColor)),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfStoreDetails(AppProfileData profile) {
    final lines = <pw.Widget>[
      pw.Text(
        'Store information',
        style: pw.TextStyle(
          fontSize: 13.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#0F172A'),
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pdfInfoLine(
              'Store name',
              profile.storeName.trim().isEmpty ? 'Not set' : profile.storeName,
            ),
            pw.SizedBox(height: 6),
            _pdfInfoLine(
              'Owner',
              profile.ownerName.trim().isEmpty ? 'Not set' : profile.ownerName,
            ),
            pw.SizedBox(height: 6),
            _pdfInfoLine(
              'Contact',
              profile.contactNumber.trim().isEmpty
                  ? 'Not set'
                  : profile.contactNumber,
            ),
            pw.SizedBox(height: 6),
            _pdfInfoLine(
              'Email',
              profile.emailAddress.trim().isEmpty
                  ? 'Not set'
                  : profile.emailAddress,
            ),
            pw.SizedBox(height: 6),
            _pdfInfoLine(
              'Address',
              profile.physicalAddress.trim().isEmpty
                  ? 'Not set'
                  : profile.physicalAddress,
            ),
          ],
        ),
      ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines,
    );
  }

  pw.Widget _pdfHighlightsSection(
    _ReportSnapshot report,
    _PdfReportStats currentStats,
    _PdfReportStats previousStats,
    PosLocalStore store,
  ) {
    final topProduct =
        report.products.isNotEmpty ? report.products.first : null;
    final revenueChange =
        _changeLabel(currentStats.revenue, previousStats.revenue);
    final average = _moneyLabel(currentStats.averageOrderValue);
    final margin = currentStats.revenue - currentStats.totalExpenses;
    final expenseRatio = currentStats.revenue <= 0
        ? 0.0
        : (currentStats.totalExpenses / currentStats.revenue) * 100;
    final lowStockCount = _lowStockItems(store).length;
    final topProductText = topProduct == null
        ? 'No completed sales were recorded in this period.'
        : '${topProduct.title} led the period with ${topProduct.orders} and ${topProduct.amount} revenue, which suggests a clear demand concentration.';
    final expenseText = currentStats.totalExpenses <= 0
        ? 'No expenses were recorded during this period.'
        : 'Expenses used ${expenseRatio.toStringAsFixed(0)}% of revenue, leaving a ${margin >= 0 ? 'positive' : 'negative'} margin of ${_moneyLabel(margin.abs())}.';
    final stockText = lowStockCount == 0
        ? 'No items are in the low-stock watchlist right now.'
        : '$lowStockCount item${lowStockCount == 1 ? '' : 's'} need restocking attention before the next sales push.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${report.category.displayName} intelligence signals',
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),
          _pdfBullet(
            'Revenue changed by $revenueChange across ${currentStats.orderCount} completed orders, with an average order value of $average.',
          ),
          pw.SizedBox(height: 5),
          _pdfBullet(topProductText),
          pw.SizedBox(height: 5),
          _pdfBullet(
            expenseText,
          ),
          pw.SizedBox(height: 5),
          _pdfBullet(
            stockText,
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfBullet(String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 5,
          height: 5,
          margin: const pw.EdgeInsets.only(top: 5.5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1E67E8'),
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfForecastSection(_ForecastSnapshot forecast) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Forecast outlook',
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Projection assumes the current sales pattern, pricing, and stock availability remain broadly consistent.',
            style: const pw.TextStyle(
              fontSize: 9.8,
              color: PdfColors.grey700,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfForecastCard(
                  title: 'Next 7 days',
                  amount: forecast.nextWeekBase,
                  low: forecast.nextWeekLow,
                  high: forecast.nextWeekHigh,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _pdfForecastCard(
                  title: 'Next 30 days',
                  amount: forecast.nextMonthBase,
                  low: forecast.nextMonthLow,
                  high: forecast.nextMonthHigh,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          _pdfBullet(
            'Direction signal: ${forecast.directionTone}. Confidence: ${forecast.confidenceLabel}.',
          ),
          pw.SizedBox(height: 5),
          _pdfBullet(
            'Risk watch: ${forecast.riskNote}.',
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfForecastCard({
    required String title,
    required double amount,
    required double low,
    required double high,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _moneyLabel(amount),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Range: ${_moneyLabel(low)} - ${_moneyLabel(high)}',
            style: const pw.TextStyle(
              fontSize: 9.4,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfInfoLine(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 72,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#0F172A'),
        ),
      ),
    );
  }

  pw.Widget _pdfTrendSummary(List<_TrendPoint> points) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2')),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: points
                  .map(
                    (point) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        '${point.label}  •  ${point.displayValue}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTrendSummaryClean(List<_TrendPoint> points) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FBFCFE'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trend breakdown',
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),
          ...points.map(
            (point) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2')),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      point.label,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.Text(
                    point.displayValue,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1E67E8'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfProductTable(List<_ProductData> products) {
    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: pw.BorderSide(color: PdfColor.fromHex('#E6EBF2'), width: 0.7),
        outside: pw.BorderSide(color: PdfColor.fromHex('#E6EBF2'), width: 0.7),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8F9FB')),
          children: [
            _pdfTableCell('Product', bold: true),
            _pdfTableCell('Sold', bold: true),
            _pdfTableCell('Revenue', bold: true),
          ],
        ),
        ...products.map(
          (product) => pw.TableRow(
            children: [
              _pdfTableCell(product.title),
              _pdfTableCell(product.orders),
              _pdfTableCell(product.amount),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _reportFileName() {
    return 'store_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  String _formatPdfDateTime(DateTime dateTime) {
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
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} '
        '$hour:$minute $amPm';
  }

  String _hexForMetric(Color color) {
    final red = (color.r * 255.0).round().clamp(0, 255).toInt();
    final green = (color.g * 255.0).round().clamp(0, 255).toInt();
    final blue = (color.b * 255.0).round().clamp(0, 255).toInt();
    return '#'
        '${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
  }

  String _metricGlyph(IconData icon) {
    if (icon == Icons.trending_up_rounded) return 'R';
    if (icon == Icons.shopping_bag_rounded) return 'O';
    if (icon == Icons.account_balance_wallet_rounded) return 'A';
    return '-';
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

  String _trendLabel(DateTime date) {
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

  String _moneyLabel(double amount) {
    return 'TSH ${_formatWithCommas(amount)}';
  }

  String _compactAmount(double value) {
    return _kLabel(value);
  }

  String _formatWithCommas(num value) {
    final fixed = value.toStringAsFixed(0);
    return fixed.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  double _resolveChartMax(List<_TrendPoint> points) {
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

  double _resolveProfitChartMax(List<_TrendPoint> points) {
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

  IconData _iconForLine(OrderLine line) {
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

  List<Color> _colorsForLine(OrderLine line) {
    switch (line.artType) {
      case ProductArtType.aquafina:
        return const [Color(0xFF1E67E8), Color(0xFF69A6FF)];
      case ProductArtType.coke:
        return const [Color(0xFFD12D2D), Color(0xFFFF7A7A)];
      case ProductArtType.lays:
        return const [Color(0xFFD97706), Color(0xFFF7C35F)];
      case ProductArtType.galaxy:
        return const [Color(0xFF8E3ED8), Color(0xFFC58BFF)];
      case ProductArtType.kelloggs:
        return const [Color(0xFFB45309), Color(0xFFF2B46D)];
      case ProductArtType.dove:
        return const [Color(0xFF0F9D8C), Color(0xFF76D6CA)];
      case ProductArtType.colgate:
        return const [Color(0xFF1D4ED8), Color(0xFF6EA8FF)];
      case ProductArtType.dettol:
        return const [Color(0xFF169B4A), Color(0xFF7EDDA2)];
      case ProductArtType.tide:
        return const [Color(0xFF9A3412), Color(0xFFF59E0B)];
    }
  }

  _ReportRange _resolveReportRange(
    List<CompletedOrder> orders,
    _ReportPeriod period,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (period) {
      case _ReportPeriod.today:
        return _ReportRange(
          start: todayStart,
          end: todayStart,
          label: _dateLabel(todayStart),
        );
      case _ReportPeriod.week:
        final weekStart =
            todayStart.subtract(Duration(days: todayStart.weekday - 1));
        return _ReportRange(
          start: weekStart,
          end: todayStart,
          label: '${_dateLabel(weekStart)} - ${_dateLabel(todayStart)}',
        );
      case _ReportPeriod.month:
        final monthStart = DateTime(now.year, now.month, 1);
        return _ReportRange(
          start: monthStart,
          end: todayStart,
          label: '${_dateLabel(monthStart)} - ${_dateLabel(todayStart)}',
        );
      case _ReportPeriod.allTime:
        final orderDates = orders
            .map((order) => DateTime.tryParse(order.dateTime))
            .whereType<DateTime>()
            .toList()
          ..sort();
        if (orderDates.isEmpty) {
          return _ReportRange(
            start: todayStart,
            end: todayStart,
            label: 'All Time',
          );
        }
        final start = DateTime(
          orderDates.first.year,
          orderDates.first.month,
          orderDates.first.day,
        );
        final end = DateTime(
          orderDates.last.year,
          orderDates.last.month,
          orderDates.last.day,
        );
        return _ReportRange(start: start, end: end, label: 'All Time');
    }
  }

  List<_TrendPoint> _buildTrendPoints({
    required Map<DateTime, double> dailyRevenue,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    if (totalDays <= 0) {
      return <_TrendPoint>[
        _TrendPoint(
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
        return _TrendPoint(
          label: _trendLabel(day),
          value: value,
          displayValue: _compactAmount(value),
        );
      });
    }

    const bucketCount = 6;
    final bucketSize = (totalDays / bucketCount).ceil();
    final points = <_TrendPoint>[];

    for (var index = 0; index < bucketCount; index++) {
      final bucketStart = startDate.add(Duration(days: index * bucketSize));
      if (bucketStart.isAfter(endDate)) break;

      var bucketEnd = bucketStart.add(Duration(days: bucketSize - 1));
      if (bucketEnd.isAfter(endDate)) {
        bucketEnd = endDate;
      }

      final value = _sumRevenueForRange(
        dailyRevenue: dailyRevenue,
        startDate: bucketStart,
        endDate: bucketEnd,
      );

      points.add(
        _TrendPoint(
          label: _trendBucketLabel(bucketStart, bucketEnd),
          value: value,
          displayValue: _compactAmount(value),
        ),
      );
    }

    return points.isEmpty
        ? <_TrendPoint>[
            _TrendPoint(
              label: _trendLabel(startDate),
              value: 0,
              displayValue: _compactAmount(0),
            ),
          ]
        : points;
  }

  double _sumRevenueForRange({
    required Map<DateTime, double> dailyRevenue,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    var total = 0.0;
    var current = startDate;
    while (!current.isAfter(endDate)) {
      total += dailyRevenue[current] ?? 0;
      current = current.add(const Duration(days: 1));
    }
    return total;
  }

  String _trendBucketLabel(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return _trendLabel(startDate);
    }
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${_monthName(startDate.month)} ${startDate.day}-${endDate.day}';
    }
    return '${_monthName(startDate.month)} ${startDate.day}-${_monthName(endDate.month)} ${endDate.day}';
  }

  String _monthName(int month) {
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
    return monthNames[month - 1];
  }
}

class _ReportSnapshot {
  const _ReportSnapshot({
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
  final List<_MetricData> metrics;
  final List<_TrendPoint> trendPoints;
  final List<_TrendPoint> profitTrendPoints;
  final List<_ProductData> products;
  final List<_ProductData> allProducts;
  final double chartMaxValue;
  final double profitChartMaxValue;
}

class _PdfReportStats {
  const _PdfReportStats({
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

class _ReportRange {
  const _ReportRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

class _ProductTally {
  _ProductTally({
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

class _ReportControlsBar extends StatelessWidget {
  const _ReportControlsBar({
    required this.dateRange,
    required this.periodLabel,
    required this.isDownloading,
    required this.onPeriodSelected,
    required this.onDownloadTap,
  });

  final String dateRange;
  final String periodLabel;
  final bool isDownloading;
  final ValueChanged<_ReportPeriod> onPeriodSelected;
  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReportHubPage._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: ReportHubPage._blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          color: ReportHubPage._muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ReportHubPage._ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<_ReportPeriod>(
            onSelected: onPeriodSelected,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            itemBuilder: (context) => _ReportPeriod.values
                .map(
                  (period) => PopupMenuItem<_ReportPeriod>(
                    value: period,
                    child: Text(period.label),
                  ),
                )
                .toList(),
            child: _ActionChip(
              icon: Icons.tune_rounded,
              label: periodLabel,
            ),
          ),
          const SizedBox(width: 8),
          _ActionChipButton(
            icon: Icons.ios_share_rounded,
            loading: isDownloading,
            onTap: onDownloadTap,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ReportHubPage._blue, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: ReportHubPage._blue,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F8FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loading
                ? const SizedBox(
                    key: ValueKey('download-loading'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Icon(
                    icon,
                    key: const ValueKey('download-icon'),
                    color: ReportHubPage._blue,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ExecutiveSummaryCard extends StatelessWidget {
  const _ExecutiveSummaryCard({
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: ReportHubPage._border,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ReportHubPage._ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              color: ReportHubPage._muted,
              fontSize: 15,
              height: 1.68,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertCard extends StatelessWidget {
  const _StockAlertCard({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_StockAlertItem> items;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderColor: ReportHubPage._border,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F4FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: ReportHubPage._blue,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: ReportHubPage._ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: ReportHubPage._muted,
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7EBF2)),
              ),
              child: const Text(
                'Hakuna bidhaa zilizo chini ya kiwango cha tahadhari.',
                style: TextStyle(
                  color: ReportHubPage._muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              children: [
                for (int index = 0; index < items.length; index++) ...[
                  _StockAlertRow(item: items[index]),
                  if (index != items.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: ReportHubPage._border,
                      ),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _StockAlertRow extends StatelessWidget {
  const _StockAlertRow({required this.item});

  final _StockAlertItem item;

  @override
  Widget build(BuildContext context) {
    final badgeColor = item.severity == _StockAlertSeverity.high
        ? const Color(0xFFDC2626)
        : const Color(0xFFB45309);
    final badgeBackground = item.severity == _StockAlertSeverity.high
        ? const Color(0xFFFDECEC)
        : const Color(0xFFFEF3DC);

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: badgeBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: badgeColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: ReportHubPage._ink,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.category,
                style: const TextStyle(
                  color: ReportHubPage._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.statusLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.stockCount} left',
              style: const TextStyle(
                color: ReportHubPage._muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StockAlertItem {
  const _StockAlertItem({
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
  final _StockAlertSeverity severity;
}

enum _StockAlertSeverity { medium, high }

class _TrendMetricChip extends StatelessWidget {
  const _TrendMetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF1FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? const Color(0xFFD0DEF7) : const Color(0xFFE1E6F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? ReportHubPage._blue : ReportHubPage._muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.periodLabel,
    required this.onPeriodSelected,
  });

  final String periodLabel;
  final ValueChanged<_ReportPeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<_ReportPeriod>(
        onSelected: onPeriodSelected,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        offset: const Offset(0, 10),
        itemBuilder: (context) => _ReportPeriod.values
            .map(
              (period) => PopupMenuItem<_ReportPeriod>(
                value: period,
                child: Text(period.label),
              ),
            )
            .toList(),
        child: _PillButton(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          borderColor: const Color(0xFFD9E2F2),
          backgroundColor: const Color(0xFFF4F8FF),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                color: ReportHubPage._blue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                periodLabel,
                style: const TextStyle(
                  color: ReportHubPage._blue,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : 4;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _MetricCard(data: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(10),
      borderColor: ReportHubPage._border,
      radius: 18,
      child: SizedBox(
        height: 158,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: data.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                color: data.iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ReportHubPage._muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                data.value,
                style: TextStyle(
                  color: data.valueColor,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (data.deltaText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: data.deltaIsPositive == false
                          ? const Color(0xFFFDECEC)
                          : data.tint.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.deltaIsPositive == false
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          size: 13,
                          color: data.deltaIsPositive == false
                              ? const Color(0xFFDC2626)
                              : data.iconColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          data.deltaText!,
                          style: TextStyle(
                            color: data.deltaIsPositive == false
                                ? const Color(0xFFDC2626)
                                : data.iconColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.deltaLabel,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ReportHubPage._muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      borderColor: ReportHubPage._border,
      radius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ReportHubPage._ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _LinkAction extends StatelessWidget {
  const _LinkAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: onTap == null
                ? ReportHubPage._blue.withValues(alpha: 0.55)
                : ReportHubPage._blue,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.chevron_right_rounded,
          color: ReportHubPage._blue,
          size: 16,
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: content,
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2F2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: ReportHubPage._blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: ReportHubPage._blue,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ReportHubPage._blue,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.child,
    required this.padding,
    required this.borderColor,
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _InsightsList extends StatelessWidget {
  const _InsightsList({required this.insights});

  final List<_InsightData> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < insights.length; index++) ...[
          _InsightTile(data: insights[index]),
          if (index != insights.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                thickness: 1,
                color: ReportHubPage._border,
              ),
            ),
        ],
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.data});

  final _InsightData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              data.icon,
              color: data.iconColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: ReportHubPage._ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.description,
                  style: const TextStyle(
                    color: ReportHubPage._muted,
                    fontSize: 12.5,
                    height: 1.42,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: data.impactBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data.impactLabel,
                  style: TextStyle(
                    color: data.impactColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8A94A6),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightData {
  const _InsightData({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.description,
    required this.impactLabel,
    required this.impactColor,
    required this.impactBackground,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final String description;
  final String impactLabel;
  final Color impactColor;
  final Color impactBackground;
}

class _TopSellingProductsList extends StatelessWidget {
  const _TopSellingProductsList({
    required this.products,
    required this.emptyMessage,
  });

  final List<_ProductData> products;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          emptyMessage,
          style: const TextStyle(
            color: ReportHubPage._muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < products.length; index++) ...[
          _ProductRow(
            data: products[index],
            rank: index + 1,
            highlightTop: index == 0,
          ),
          if (index != products.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Divider(
                height: 1,
                thickness: 1,
                color: ReportHubPage._border,
              ),
            ),
        ],
      ],
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({
    required this.points,
    required this.maxValue,
  });

  final List<_TrendPoint> points;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SalesTrendPainter(
        points: points,
        maxValue: maxValue,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SalesTrendPainter extends CustomPainter {
  _SalesTrendPainter({
    required this.points,
    required this.maxValue,
  });

  final List<_TrendPoint> points;
  final double maxValue;

  static const TextStyle _axisStyle = TextStyle(
    color: Color(0xFF5B6270),
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.15,
  );
  static const TextStyle _valueStyle = TextStyle(
    color: Color(0xFF101828),
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 62.0;
    const rightPad = 24.0;
    const topPad = 16.0;
    const bottomPad = 22.0;
    const labelBandHeight = 20.0;
    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad - labelBandHeight,
    );
    const lineColor = ReportHubPage._blue;

    final showEveryNth = points.length > 5 ? 2 : 1;
    bool shouldDrawLabel(int i) =>
        i == 0 || i == points.length - 1 || i % showEveryNth == 0;

    final gridPaint = Paint()
      ..color = const Color(0xFFD8DFEA)
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = const Color(0x1A1E67E8)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointOuterPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final pointInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final chartMaxValue = maxValue <= 0 ? 1.0 : maxValue;
    final minSeriesValue = points.isEmpty
        ? 0.0
        : points.fold<double>(
            points.first.value,
            (minValue, point) => math.min(minValue, point.value),
          );
    final maxSeriesValue = points.isEmpty
        ? chartMaxValue
        : points.fold<double>(
            points.first.value,
            (maxValue, point) => math.max(maxValue, point.value),
          );
    final minY = math.min(0, minSeriesValue);
    final maxY = math.max(chartMaxValue, maxSeriesValue);
    final range = (maxY - minY).abs() < 0.0001 ? 1.0 : (maxY - minY);
    final gridValues = List<double>.generate(
      6,
      (index) => minY + (range * index / 5),
    );

    final stepX =
        points.length == 1 ? 0.0 : chartRect.width / (points.length - 1);
    final offsets = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final x = chartRect.left + (stepX * index);
      final normalized = (points[index].value - minY) / range;
      final y = chartRect.bottom - normalized * chartRect.height;
      offsets.add(Offset(x, y));
    }

    final zeroY = minY < 0 && maxY > 0
        ? chartRect.bottom - ((0 - minY) / range) * chartRect.height
        : chartRect.bottom;

    for (final gridValue in gridValues) {
      final gridY =
          chartRect.bottom - ((gridValue - minY) / range) * chartRect.height;
      _drawDashedLine(
        canvas,
        Offset(chartRect.left, gridY),
        Offset(chartRect.right, gridY),
        gridPaint,
      );
      if ((gridValue - 0).abs() < 0.0001) {
        canvas.drawLine(
          Offset(chartRect.left, gridY),
          Offset(chartRect.right, gridY),
          Paint()
            ..color = const Color(0xFFB9C4D6)
            ..strokeWidth = 1.4,
        );
      }
      _paintText(
        canvas,
        _gridLabel(gridValue),
        _axisStyle,
        Offset(0, gridY - 8),
        width: 40,
        align: TextAlign.right,
      );
    }

    if (offsets.isEmpty) return;

    final areaPath = Path()
      ..moveTo(offsets.first.dx, zeroY)
      ..lineTo(offsets.first.dx, offsets.first.dy);
    for (var index = 1; index < offsets.length; index++) {
      areaPath.lineTo(offsets[index].dx, offsets[index].dy);
    }
    areaPath
      ..lineTo(offsets.last.dx, zeroY)
      ..close();
    canvas.drawPath(areaPath, fillPaint);

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var index = 1; index < offsets.length; index++) {
      linePath.lineTo(offsets[index].dx, offsets[index].dy);
    }
    canvas.drawPath(linePath, strokePaint);

    for (var index = 0; index < offsets.length; index++) {
      final offset = offsets[index];
      canvas.drawCircle(offset, 8, pointOuterPaint);
      canvas.drawCircle(offset, 5.2, pointInnerPaint);

      if (shouldDrawLabel(index)) {
        _paintText(
          canvas,
          points[index].displayValue,
          _valueStyle,
          Offset(offset.dx, offset.dy - 34),
          width: 48,
          align: TextAlign.center,
        );
        _paintText(
          canvas,
          points[index].label,
          _axisStyle,
          Offset(offset.dx, chartRect.bottom + 6),
          width: 48,
          align: TextAlign.center,
        );
      }
    }
  }

  static String _gridLabel(double value) {
    if (value == 0) return '0';
    final prefix = value < 0 ? '-' : '';
    return '$prefix${_kLabel(value.abs())}';
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 4.0;
    const dashGap = 6.0;
    var currentX = start.dx;

    while (currentX < end.dx) {
      final nextX =
          (currentX + dashWidth) > end.dx ? end.dx : currentX + dashWidth;
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(nextX, end.dy),
        paint,
      );
      currentX += dashWidth + dashGap;
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset offset, {
    required double width,
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: width);

    final dx = switch (align) {
      TextAlign.right => offset.dx + width - painter.width,
      TextAlign.center => offset.dx + (width - painter.width) / 2,
      _ => offset.dx,
    };

    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.maxValue != maxValue;
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.data,
    required this.rank,
    required this.highlightTop,
  });

  final _ProductData data;
  final int rank;
  final bool highlightTop;

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        highlightTop ? const Color(0xFF1E67E8) : const Color(0xFF8A94A6);
    final badgeBg =
        highlightTop ? const Color(0xFFEAF1FF) : const Color(0xFFF4F6FA);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ProductThumb(data: data),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ReportHubPage._ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                    if (highlightTop)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8EE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Top',
                          style: TextStyle(
                            color: Color(0xFF169B4A),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.orders} sold',
                  style: const TextStyle(
                    color: ReportHubPage._muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.amount,
                style: const TextStyle(
                  color: ReportHubPage._blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Revenue',
                style: TextStyle(
                  color: ReportHubPage._muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF8A94A6),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.data});

  final _ProductData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: data.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          data.icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.valueColor,
    required this.deltaText,
    required this.deltaLabel,
    required this.deltaIsPositive,
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

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.value,
    required this.displayValue,
  });

  final String label;
  final double value;
  final String displayValue;
}

class _ProductData {
  const _ProductData({
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

class _ForecastSnapshot {
  const _ForecastSnapshot({
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
