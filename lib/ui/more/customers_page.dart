import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';
import '../widgets/market_shared_widgets.dart';
import 'create_customer_page.dart';
import 'debtors_page.dart';
import 'customer_details_page.dart';
import 'widgets/customer_cards.dart';
import 'widgets/customer_filter_widgets.dart';
import 'widgets/customer_models.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _formatMoney(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({
    super.key,
    this.isSelectionMode = false,
  });

  final bool isSelectionMode;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = CustomerFilterOption.all.name;
  CustomerSortMode _sort = CustomerSortMode.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            bottom: false,
            child: Consumer<PosLocalStore>(
              builder: (context, store, _) {
                final strings = AppStrings.of(store.languageCode);
                final stats = _buildStats(store);
                final all = List<CustomerData>.from(store.customers);

                final filtered = all.where((customer) {
                  final info = stats[customer.name] ?? CustomerStats.empty;
                  final q = _searchQuery.trim().toLowerCase();
                  final matchesSearch = q.isEmpty ||
                      customer.name.toLowerCase().contains(q) ||
                      customer.phone.toLowerCase().contains(q) ||
                      customer.email.toLowerCase().contains(q) ||
                      customer.address.toLowerCase().contains(q);
                  final matchesFilter = _matchesFilter(customer, info);
                  return matchesSearch && matchesFilter;
                }).toList();
                _sortList(filtered, stats);

                final outstanding = all.fold<double>(
                    0,
                    (sum, c) =>
                        sum + (c.debitBalance > 0 ? c.debitBalance : 0));
                final withOrders = all
                    .where((c) =>
                        (stats[c.name]?.orders ?? 0) > 0 || c.totalOrders > 0)
                    .length;
                final lifetime = all.fold<double>(
                  0,
                  (sum, c) =>
                      sum +
                      (stats[c.name]?.spent ?? 0) +
                      (c.totalSpent > 0 ? c.totalSpent : 0),
                );

                return Column(
                  children: [
                    MarketPageHeader(
                      title: _dual(strings, 'Customers', 'Wateja'),
                      subtitle: _dual(strings, 'Contacts, credit and loyalty',
                          'Mawasiliano, mkopo na uaminifu'),
                      showBorder: false,
                    ),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
                        children: [
                          LayoutBuilder(
                            builder: (context, metricConstraints) {
                              final columns =
                                  metricConstraints.maxWidth >= 760 ? 4 : 2;
                              final width = (metricConstraints.maxWidth -
                                      (columns - 1) * 12) /
                                  columns;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: width,
                                    child: WorkspaceMetric(
                                      label: _dual(strings, 'Total customers',
                                          'Wateja wote'),
                                      value: '${all.length}',
                                      icon: Icons.people_alt_outlined,
                                      sharp: false,
                                      borderless: true,
                                      backgroundColor: AppColors.kpiSkyBg,
                                      color: AppColors.kpiSky,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: WorkspaceMetric(
                                      label: _dual(strings, 'Active buyers',
                                          'Wanunuzi hai'),
                                      value: '${all.isEmpty ? 0 : withOrders}',
                                      icon: Icons.shopping_bag_outlined,
                                      sharp: false,
                                      borderless: true,
                                      backgroundColor: AppColors.kpiRoseBg,
                                      color: AppColors.kpiRose,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: WorkspaceMetric(
                                      label: _dual(strings, 'Lifetime sales',
                                          'Jumla ya mauzo'),
                                      value:
                                          _formatMoney(lifetime, compact: true),
                                      icon: Icons.trending_up_rounded,
                                      sharp: false,
                                      borderless: true,
                                      backgroundColor: AppColors.kpiSuccessBg,
                                      color: AppColors.kpiSuccess,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: WorkspaceMetric(
                                      label: _dual(strings, 'Outstanding debt',
                                          'Madeni yote'),
                                      value: _formatMoney(outstanding,
                                          compact: true),
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      sharp: false,
                                      borderless: true,
                                      backgroundColor: AppColors.kpiDangerBg,
                                      color: AppColors.kpiDanger,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (outstanding > 0) ...[
                            const SizedBox(height: 10),
                            CustomerCreditBanner(
                              amount: outstanding,
                              count: store.debtorCount,
                              strings: strings,
                              onTap: _openDebtors,
                            ),
                          ],
                          const SizedBox(height: 12),
                          MarketSearchField(
                            controller: _searchController,
                            hintText: _dual(
                                strings, 'Search customers', 'Tafuta wateja'),
                            radius: AppRadius.input,
                            showShadow: false,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            onClear: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                          const SizedBox(height: 10),
                          CustomerFilterRow(
                            value: _filter,
                            strings: strings,
                            onChanged: (value) =>
                                setState(() => _filter = value),
                          ),
                          const SizedBox(height: 10),
                          CustomerSortCard(
                            sort: _sort,
                            strings: strings,
                            onPick: _pickSort,
                            activeFilters: _hasActiveFilter,
                            onClear: _clearFilters,
                          ),
                          const SizedBox(height: 18),
                          MarketSectionHeader(
                            title: _dual(strings, 'Customer Directory',
                                'Orodha ya Wateja'),
                            trailing: Text(
                              _dual(
                                strings,
                                '${filtered.length} of ${all.length}',
                                '${filtered.length} kati ya ${all.length}',
                              ),
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (filtered.isEmpty)
                            CustomerEmptyState(
                              strings: strings,
                              filtered: _hasActiveFilter,
                              onAdd: _openCreate,
                              onReset: _clearFilters,
                            )
                          else
                            WorkspaceRegister(
                                columns: [
                                  DataColumn(
                                      label: Text(
                                          _dual(strings, 'Customer', 'Mteja'))),
                                  DataColumn(
                                      label: Text(
                                          _dual(strings, 'Phone', 'Simu'))),
                                  DataColumn(
                                      label: Text(_dual(
                                          strings, 'Email', 'Barua pepe'))),
                                  DataColumn(
                                      label: Text(
                                          _dual(strings, 'Orders', 'Manunuzi')),
                                      numeric: true),
                                  DataColumn(
                                      label: Text(
                                          _dual(strings, 'Sales', 'Mauzo')),
                                      numeric: true),
                                  DataColumn(
                                      label: Text(_dual(strings,
                                          'Credit balance', 'Salio la mkopo')),
                                      numeric: true),
                                  const DataColumn(label: Text('')),
                                ],
                                rows: filtered
                                    .map((customer) => DataRow(cells: [
                                          DataCell(
                                              ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 220),
                                                  child: Text(customer.name,
                                                      overflow: TextOverflow
                                                          .ellipsis)),
                                              onTap: () =>
                                                  _openCustomer(customer)),
                                          DataCell(Text(customer.phone)),
                                          DataCell(Text(customer.email.isEmpty
                                              ? '—'
                                              : customer.email)),
                                          DataCell(Text(
                                              '${stats[customer.name]?.orders ?? customer.totalOrders}')),
                                          DataCell(Text(_formatMoney(
                                              stats[customer.name]?.spent ??
                                                  customer.totalSpent))),
                                          DataCell(Text(
                                              _formatMoney(
                                                  customer.debitBalance),
                                              style: TextStyle(
                                                  color: customer.debitBalance >
                                                          0
                                                      ? AppColors.dangerDeep
                                                      : AppColors.textBody))),
                                          DataCell(IconButton(
                                              tooltip: _dual(
                                                  strings,
                                                  'Open customer',
                                                  'Fungua mteja'),
                                              onPressed: () =>
                                                  _openCustomer(customer),
                                              icon: const Icon(Icons
                                                  .chevron_right_rounded))),
                                        ]))
                                    .toList(),
                                mobile: Column(children: [
                                  ...filtered.map(
                                    (customer) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: CustomerCard(
                                        customer: customer,
                                        stats: stats[customer.name] ??
                                            CustomerStats.empty,
                                        strings: strings,
                                        onTap: () => _openCustomer(customer),
                                      ),
                                    ),
                                  )
                                ])),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          )),
      floatingActionButton: widget.isSelectionMode
          ? null
          : Builder(
              builder: (context) {
                final strings =
                    AppStrings.of(context.watch<PosLocalStore>().languageCode);
                return AddCustomerButton(
                  label: _dual(strings, 'Add Customer', 'Ongeza Mteja'),
                  onTap: _openCreate,
                );
              },
            ),
    );
  }

  bool get _hasActiveFilter =>
      _searchQuery.trim().isNotEmpty ||
      _filter != CustomerFilterOption.all.name;

  bool _matchesFilter(CustomerData customer, CustomerStats info) {
    final filter = filterFromName(_filter);
    switch (filter) {
      case CustomerFilterOption.all:
        return true;
      case CustomerFilterOption.vip:
        return customer.tags.contains('VIP');
      case CustomerFilterOption.wholesale:
        return customer.tags.contains('Wholesale');
      case CustomerFilterOption.debtors:
        return customer.debitBalance > 0;
      case CustomerFilterOption.recent:
        return DateTime.now().difference(customer.createdAt).inDays <= 30;
    }
  }

  Map<String, CustomerStats> _buildStats(PosLocalStore store) {
    final map = <String, CustomerStats>{};
    for (final order in store.orders) {
      final name = order.customerName;
      if (name == null || name.trim().isEmpty) continue;
      final date = DateTime.tryParse(order.dateTime);
      final previous = map[name] ?? CustomerStats.empty;
      map[name] = CustomerStats(
        orders: previous.orders + 1,
        spent: previous.spent + order.total,
        lastOrder: _later(previous.lastOrder, date),
      );
    }
    return map;
  }

  static DateTime? _later(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return b.isAfter(a) ? b : a;
  }

  void _sortList(List<CustomerData> list, Map<String, CustomerStats> stats) {
    double spentOf(CustomerData c) => stats[c.name]?.spent ?? c.totalSpent;
    int ordersOf(CustomerData c) =>
        (stats[c.name]?.orders ?? 0) + c.totalOrders;

    switch (_sort) {
      case CustomerSortMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CustomerSortMode.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case CustomerSortMode.name:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case CustomerSortMode.highestSpend:
        list.sort((a, b) => spentOf(b).compareTo(spentOf(a)));
        break;
      case CustomerSortMode.mostOrders:
        list.sort((a, b) => ordersOf(b).compareTo(ordersOf(a)));
        break;
      case CustomerSortMode.debtors:
        list.sort((a, b) => b.debitBalance.compareTo(a.debitBalance));
        break;
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filter = CustomerFilterOption.all.name;
    });
  }

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateCustomerPage()),
    );
  }

  void _openDebtors() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DebtorsPage(),
      ),
    );
  }

  void _openCustomer(CustomerData customer) {
    if (widget.isSelectionMode) {
      Navigator.of(context).pop(customer.name);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CustomerDetailsPage(customerId: customer.id),
      ),
    );
  }

  Future<void> _pickSort() async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final picked = await showModalBottomSheet<CustomerSortMode>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.extraRounded),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.all(Radius.circular(AppRadius.pill)))),
            const SizedBox(height: 12),
            Text(_dual(strings, 'Sort customers by', 'Panga wateja kwa'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final mode in CustomerSortMode.values)
              ListTile(
                leading: Icon(mode.icon, color: AppColors.textMuted, size: 20),
                title:
                    Text(mode.label(strings), style: AppTypography.bodyMedium),
                trailing: mode == _sort
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(mode),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _sort = picked);
  }
}
