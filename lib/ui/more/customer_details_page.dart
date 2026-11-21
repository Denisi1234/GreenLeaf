import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'create_customer_page.dart';
import 'widgets/customer_debit_section.dart';
import 'widgets/customer_detail_models.dart';
import 'widgets/customer_hero_card.dart';
import 'widgets/customer_history_widgets.dart';

class CustomerDetailsPage extends StatelessWidget {
  const CustomerDetailsPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Selector<PosLocalStore, CustomerData?>(
      selector: (_, store) {
        for (final customer in store.customers) {
          if (customer.id == customerId) return customer;
        }
        return null;
      },
      builder: (context, customer, _) {
        final strings =
            AppStrings.of(context.watch<PosLocalStore>().languageCode);
        if (customer == null) {
          return Scaffold(
            backgroundColor: AppColors.pageBackground,
            body: ManagementViewport(
              maxWidth: 1280,
              child: SafeArea(
                child: Column(
                  children: [
                    MarketPageHeader(
                      title: customerDual(
                          strings, 'Customer details', 'Maelezo ya mteja'),
                      showBorder: false,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          customerDual(strings, 'Customer no longer exists',
                              'Mteja haipo tena'),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _CustomerDetailsView(customer: customer);
      },
    );
  }
}

class _CustomerDetailsView extends StatelessWidget {
  const _CustomerDetailsView({required this.customer});

  final CustomerData customer;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final orders = store.ordersForCustomer(customer.name);
    final totalSpent =
        orders.fold<double>(0, (sum, order) => sum + order.total);
    final averageOrder = orders.isEmpty ? 0.0 : totalSpent / orders.length;
    final lastOrder = _latestOrder(orders);
    final points = ((totalSpent + customer.totalSpent) / 1000).round();
    final tier = tierForSpend(totalSpent + customer.totalSpent);
    final ledger = store.debitEntriesFor(customer.id);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
        maxWidth: 1280,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              MarketPageHeader(
                title: customerDual(
                    strings, 'Customer details', 'Maelezo ya mteja'),
                subtitle: customerDual(
                    strings,
                    'Profile, credit and order history',
                    'Wasifu, mkopo na historia ya oda'),
                showBorder: false,
                actions: [
                  IconButton(
                    tooltip: customerDual(strings, 'Edit', 'Hariri'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            CreateCustomerPage(existing: customer),
                      ),
                    ),
                    icon:
                        const Icon(Icons.edit_outlined, color: AppColors.ink),
                  ),
                  IconButton(
                    tooltip: customerDual(strings, 'Delete', 'Futa'),
                    onPressed: () => _confirmDelete(context, customer, store),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                  children: [
                    CustomerHeroCard(
                      customer: customer,
                      tier: tier,
                      points: points,
                      strings: strings,
                    ),
                    if (customer.debitBalance > 0 || ledger.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      CustomerDebitSection(
                        customer: customer,
                        entries: ledger,
                        strings: strings,
                      ),
                    ],
                    const SizedBox(height: 12),
                    CustomerContactActions(
                        customer: customer, strings: strings),
                    const SizedBox(height: 16),
                    CustomerStatsGrid(
                      totalSpent: totalSpent,
                      orderCount: orders.length,
                      averageOrder: averageOrder,
                      lastOrder: lastOrder,
                      strings: strings,
                    ),
                    if (customer.address.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      CustomerInfoBlock(
                        icon: Icons.location_on_outlined,
                        label: customerDual(strings, 'Address', 'Anwani'),
                        value: customer.address.trim(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    CustomerOrdersSection(orders: orders, strings: strings),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime? _latestOrder(List<CompletedOrder> orders) {
    DateTime? latest;
    for (final order in orders) {
      final date = DateTime.tryParse(order.dateTime);
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    return latest;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerData customer,
    PosLocalStore store,
  ) async {
    final strings = AppStrings.of(store.languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title: Text(
          customerDual(strings, 'Delete customer?', 'Futa mteja?'),
          style: AppTypography.cardHeader,
        ),
        content: Text(
          customerDual(
            strings,
            'Remove ${customer.name} from your customer list. Past orders are kept.',
            'Ondoa ${customer.name} kwenye orodha ya wateja. Oda za zamani zitabaki.',
          ),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.standard),
              ),
            ),
            child: Text(customerDual(strings, 'Delete', 'Futa')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await store.deleteCustomer(customer.id);
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: customerDual(strings, 'Customer Deleted', 'Mteja Amefutwa'),
      message: customerDual(
        strings,
        '${customer.name} was removed from your customer list.',
        '${customer.name} ameondolewa kwenye orodha ya wateja.',
      ),
      type: MarketNoticeType.success,
    );
    Navigator.of(context).pop();
  }
}
