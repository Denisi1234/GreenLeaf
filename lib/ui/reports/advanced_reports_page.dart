import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../widgets/app_design.dart';
import '../widgets/common/market_empty_state.dart';
import '../widgets/common/market_page_header.dart';
import '../widgets/common/market_search_field.dart';
import 'enhanced_report_page.dart';
import 'pos_report_catalog.dart';

/// Full-width, sharp, borderless ERP hub for all advanced / specialized reports
/// (Graphical, Detailed, Accounting, Operations, Multi-Store).
class AdvancedReportsPage extends StatefulWidget {
  const AdvancedReportsPage({super.key});

  @override
  State<AdvancedReportsPage> createState() => _AdvancedReportsPageState();
}

class _AdvancedReportsPageState extends State<AdvancedReportsPage> {
  final _searchController = TextEditingController();
  final _queryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

  IconData _iconForReport(PosReport report) {
    switch (report.data) {
      case ReportData.sales:
      case ReportData.multiStoreSales:
        return report.chart
            ? Icons.show_chart_rounded
            : Icons.point_of_sale_outlined;
      case ReportData.categories:
      case ReportData.multiStoreCategories:
        return Icons.category_outlined;
      case ReportData.expenses:
      case ReportData.multiStoreExpenses:
        return Icons.receipt_long_outlined;
      case ReportData.customers:
      case ReportData.multiStoreCustomers:
        return Icons.people_outline_rounded;
      case ReportData.suppliers:
      case ReportData.multiStoreSuppliers:
        return Icons.local_shipping_outlined;
      case ReportData.items:
      case ReportData.multiStoreItems:
        return Icons.shopping_bag_outlined;
      case ReportData.employees:
      case ReportData.multiStoreStaff:
        return Icons.badge_outlined;
      case ReportData.taxes:
      case ReportData.salesTaxes:
      case ReportData.multiStoreTax:
        return Icons.percent_rounded;
      case ReportData.discounts:
      case ReportData.multiStoreDiscounts:
        return Icons.local_offer_outlined;
      case ReportData.payments:
      case ReportData.multiStorePayments:
        return Icons.payments_outlined;
      case ReportData.location:
        return Icons.location_on_outlined;
      case ReportData.salesDetail:
        return Icons.receipt_outlined;
      case ReportData.itemDetail:
        return Icons.inventory_outlined;
      case ReportData.receivings:
      case ReportData.multiStoreReceivings:
        return Icons.move_to_inbox_outlined;
      case ReportData.customerDetail:
        return Icons.person_search_outlined;
      case ReportData.employeeDetail:
        return Icons.assignment_ind_outlined;
      case ReportData.discountDetail:
        return Icons.sell_outlined;
      case ReportData.supplierDetail:
        return Icons.local_mall_outlined;
      case ReportData.inventory:
        return Icons.inventory_2_outlined;
      case ReportData.lowInventory:
      case ReportData.multiStoreLowStock:
        return Icons.warning_amber_rounded;
      case ReportData.profitLoss:
      case ReportData.multiStoreProfit:
        return Icons.trending_up_rounded;
      case ReportData.balanceSheet:
        return Icons.balance_rounded;
      case ReportData.bank:
      case ReportData.multiStoreBank:
        return Icons.account_balance_outlined;
      case ReportData.reconciliation:
        return Icons.fact_check_outlined;
      case ReportData.trialBalance:
        return Icons.calculate_outlined;
      case ReportData.cashFlow:
      case ReportData.multiStoreCashFlow:
        return Icons.currency_exchange_rounded;
      case ReportData.assets:
      case ReportData.multiStoreAssets:
        return Icons.chair_outlined;
      case ReportData.taxCompliance:
        return Icons.gavel_outlined;
      case ReportData.cashUp:
        return Icons.savings_outlined;
      case ReportData.shifts:
        return Icons.work_history_outlined;
      case ReportData.hourly:
        return Icons.schedule_rounded;
      case ReportData.weekdays:
        return Icons.date_range_outlined;
      case ReportData.monthly:
        return Icons.calendar_month_outlined;
      case ReportData.registers:
      case ReportData.multiStoreRegister:
        return Icons.desktop_windows_outlined;
      case ReportData.balances:
        return Icons.account_balance_wallet_outlined;
      case ReportData.expenseDetail:
        return Icons.request_quote_outlined;
      case ReportData.expensePayments:
        return Icons.credit_card_outlined;
      case ReportData.stockByCategory:
        return Icons.widgets_outlined;
      case ReportData.stockValue:
      case ReportData.multiStoreInventoryValue:
        return Icons.monetization_on_outlined;
      case ReportData.outOfStock:
      case ReportData.multiStoreOutOfStock:
        return Icons.remove_shopping_cart_outlined;
      case ReportData.averageBasket:
        return Icons.shopping_cart_checkout_rounded;
      case ReportData.creditSales:
      case ReportData.multiStoreCredit:
        return Icons.credit_score_outlined;
      case ReportData.discountedItems:
        return Icons.discount_outlined;
      case ReportData.newCustomers:
      case ReportData.multiStoreNewCustomers:
        return Icons.person_add_alt_1_outlined;
      case ReportData.multiStoreComparison:
        return Icons.compare_arrows_rounded;
      case ReportData.multiStorePerformance:
        return Icons.leaderboard_outlined;
    }
  }

  (IconData, Color, Color) _groupStyle(ReportGroup group) {
    switch (group) {
      case ReportGroup.graphical:
        return (
          Icons.bar_chart_rounded,
          AppColors.primaryDeep,
          AppColors.primaryLight,
        );
      case ReportGroup.summary:
        return (
          Icons.summarize_outlined,
          AppColors.kpiSuccess,
          AppColors.kpiSuccessBg,
        );
      case ReportGroup.detailed:
        return (
          Icons.receipt_long_outlined,
          AppColors.kpiSky,
          AppColors.kpiSkyBg,
        );
      case ReportGroup.inventory:
        return (
          Icons.inventory_2_outlined,
          AppColors.kpiAmber,
          AppColors.kpiAmberBg,
        );
      case ReportGroup.accounting:
        return (
          Icons.account_balance_outlined,
          AppColors.kpiRose,
          AppColors.kpiRoseBg,
        );
      case ReportGroup.operations:
        return (
          Icons.insights_rounded,
          AppColors.kpiViolet,
          AppColors.kpiVioletBg,
        );
      case ReportGroup.multiStore:
        return (
          Icons.storefront_outlined,
          AppColors.kpiSuccess,
          AppColors.kpiSuccessBg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: context.tr('Advanced reports'),
            subtitle: context.tr(
              'Graphical, detailed, accounting, tax & multi-store reports',
            ),
            showBackButton: true,
            centerTitle: false,
            titleSize: 22,
            titleWeight: FontWeight.w800,
            showBorder: true,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: MarketSearchField(
                controller: _searchController,
                hintText: context.tr('Filter all reports...'),
                onChanged: (v) => _queryNotifier.value = v,
                onClear: () {
                  _searchController.clear();
                  _queryNotifier.value = '';
                },
                height: 48,
                radius: 0,
                backgroundColor: AppColors.surface,
                borderColor: AppColors.border,
                paddingHorizontal: 14,
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _queryNotifier,
                builder: (context, query, _) {
                  final needle = query.trim().toLowerCase();
                  final filtered = posReports.where((report) {
                    if (needle.isEmpty) return true;
                    return '${report.title} ${report.group.label} ${context.tr(report.title)} ${context.tr(report.group.label)}'
                        .toLowerCase()
                        .contains(needle);
                  }).toList();

                  final groups = ReportGroup.values
                      .where((g) => filtered.any((r) => r.group == g))
                      .toList();

                  if (groups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 24,
                      ),
                      child: MarketEmptyState(
                        icon: Icons.search_off_rounded,
                        title: context.tr('No matching reports'),
                        message: context.tr(
                          'Try a different keyword or clear your search to browse all reports.',
                        ),
                        actionLabel: context.tr('Clear search'),
                        actionIcon: Icons.filter_alt_off_rounded,
                        onAction: () {
                          _searchController.clear();
                          _queryNotifier.value = '';
                        },
                      ),
                    );
                  }

                  return ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (context, gIdx) {
                      final group = groups[gIdx];
                      final items =
                          filtered.where((r) => r.group == group).toList();
                      final style = _groupStyle(group);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                            child: Row(
                              children: [
                                Text(
                                  context.tr(group.label).toUpperCase(),
                                  style: AppTypography.label.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${items.length}',
                                  style: AppTypography.label.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.standard),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                children: [
                                  for (var i = 0; i < items.length; i++) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        indent: 66,
                                        color: AppColors.border,
                                      ),
                                    InkWell(
                                      key: ValueKey('report-${items[i].title}'),
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => EnhancedReportPage(
                                              report: items[i],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 13,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: style.$3,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.sharp),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                _iconForReport(items[i]),
                                                color: style.$2,
                                                size: 19,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                context.tr(items[i].title),
                                                style: AppTypography.bodyMain
                                                    .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              size: 20,
                                              color: AppColors.textMuted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
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
}
