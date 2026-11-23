import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/debit_statement_service.dart';
import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';
import '../widgets/market_shared_widgets.dart';
import 'customer_details_page.dart';
import 'record_payment_sheet.dart';
import 'widgets/debtor_actions.dart';
import 'widgets/debtor_card.dart';
import 'widgets/debtor_sort_row.dart';
import 'widgets/debtor_tiles.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _money(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

class DebtorsPage extends StatefulWidget {
  const DebtorsPage({super.key});

  @override
  State<DebtorsPage> createState() => _DebtorsPageState();
}

class _DebtorsPageState extends State<DebtorsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  LedgerSortMode _sort = LedgerSortMode.balance;

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
                final debtors = store.customers
                    .where((customer) => customer.debitBalance > 0)
                    .toList();
                final outstanding = store.outstandingDebit;
                final collected = store.debitCollectedSince(
                  DateTime(DateTime.now().year, DateTime.now().month, 1),
                );

                final query = _search.trim().toLowerCase();
                final visible = debtors.where((customer) {
                  if (query.isEmpty) return true;
                  return customer.name.toLowerCase().contains(query) ||
                      customer.phone.toLowerCase().contains(query);
                }).toList();
                _sortDebtors(visible, store);

                final entries = store.debitEntries.take(20).toList();
                final oldestDebt = _oldestDebtDate(debtors, store);
                final criticalDebtors = debtors.where((c) {
                  return DebitStatementService.getAgingDays(c, store) > 30;
                }).length;

                return Column(
                  children: [
                    MarketPageHeader(
                      title: strings.debitLedger,
                      subtitle: _dual(strings, 'Credit sales and repayments',
                          'Mauzo ya mkopo na malipo'),
                      showBorder: false,
                      actions: [
                        if (debtors.isNotEmpty || entries.isNotEmpty)
                          IconButton(
                            tooltip: _dual(strings, 'Clear old debts',
                                'Futa madeni ya zamani'),
                            icon: Icon(Icons.delete_sweep_outlined,
                                color: AppColors.dangerDeep),
                            onPressed: () =>
                                DebtorActions.confirmClearAllDebits(
                              context,
                              store: store,
                              strings: strings,
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
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
                                      label: _dual(strings, 'Total outstanding',
                                          'Jumla ya madeni'),
                                      value: _money(outstanding, compact: true),
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      sharp: false,
                                      borderless: true,
                                      backgroundColor: AppColors.surface,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: WorkspaceMetric(
                                      label: _dual(strings, 'Debtors count',
                                          'Idadi ya wadaiwa'),
                                      value: '${debtors.length}',
                                      icon: Icons.people_alt_outlined,
                                      sharp: false,
                                      borderless: true,
                                      backgroundColor: AppColors.surface,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: WorkspaceMetric(
                                      label: _dual(
                                          strings,
                                          'Collected this month',
                                          'Makusanyo mwezi huu'),
                                      value: _money(collected, compact: true),
                                      icon: Icons.savings_outlined,
                                      sharp: false,
                                      borderless: true,
                                      backgroundColor: AppColors.surface,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: WorkspaceMetric(
                                      label: _dual(strings, 'Overdue (>30d)',
                                          'Imechelewa (>30d)'),
                                      value: '$criticalDebtors',
                                      icon: Icons.warning_amber_rounded,
                                      sharp: false,
                                      borderless: true,
                                      backgroundColor: AppColors.surface,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          MarketSearchField(
                            controller: _searchController,
                            hintText: _dual(
                                strings, 'Search debtors', 'Tafuta wadaiwa'),
                            radius: AppRadius.input,
                            showShadow: false,
                            onChanged: (value) =>
                                setState(() => _search = value),
                            onClear: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                          const SizedBox(height: 10),
                          DebtorSortRow(
                            sort: _sort,
                            strings: strings,
                            oldestDebt: oldestDebt,
                            onPick: _pickSort,
                          ),
                          const SizedBox(height: 18),
                          MarketSectionHeader(
                            title: _dual(strings, 'Who owes you', 'Wanaokudai'),
                            trailing: Text(
                              _dual(
                                strings,
                                '${visible.length} customer${visible.length == 1 ? '' : 's'}',
                                'wateja ${visible.length}',
                              ),
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (visible.isEmpty)
                            EmptyDebtors(
                              strings: strings,
                              filtered: query.isNotEmpty,
                              onReset: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
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
                                      label: Text(
                                          _dual(strings, 'Aging', 'Umri'))),
                                  DataColumn(
                                      label: Text(_dual(
                                          strings,
                                          'Outstanding balance',
                                          'Deni lililobaki')),
                                      numeric: true),
                                  const DataColumn(label: Text('')),
                                ],
                                rows: visible.map((customer) {
                                  final days =
                                      DebitStatementService.getAgingDays(
                                          customer, store);
                                  return DataRow(cells: [
                                    DataCell(Text(customer.name),
                                        onTap: () => _openCustomer(customer)),
                                    DataCell(Text(customer.phone)),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: days > 30
                                              ? AppColors.kpiDangerBg
                                              : (days > 15
                                                  ? AppColors.kpiAmberBg
                                                  : AppColors.kpiSkyBg),
                                        ),
                                        child: Text(
                                          '$days d',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: days > 30
                                                ? AppColors.kpiDanger
                                                : (days > 15
                                                    ? AppColors.kpiAmber
                                                    : AppColors.kpiSky),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(_money(customer.debitBalance),
                                        style: TextStyle(
                                            color: AppColors.dangerDeep,
                                            fontWeight: FontWeight.w700))),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: _dual(
                                              strings,
                                              'Send reminder',
                                              'Tuma kikumbusho'),
                                          icon: Icon(Icons.send_rounded,
                                              size: 18,
                                              color: AppColors.primaryDeep),
                                          onPressed: () =>
                                              DebtorActions.sendReminder(
                                            context,
                                            customer: customer,
                                            store: store,
                                            strings: strings,
                                            formatMoney: (val) => _money(val),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor: Colors.white,
                                              side: BorderSide.none,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.pill),
                                              ),
                                            ),
                                            onPressed: () => _settle(customer),
                                            icon: const Icon(
                                                Icons.payments_outlined,
                                                size: 18),
                                            label: Text(_dual(
                                                strings,
                                                'Record payment',
                                                'Rekodi malipo'))),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                                mobile: Column(children: [
                                  ...visible.map(
                                    (customer) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: DebtorCard(
                                        customer: customer,
                                        store: store,
                                        strings: strings,
                                        onTap: () => _openCustomer(customer),
                                        onSettle: () => _settle(customer),
                                        onReminder: () =>
                                            DebtorActions.sendReminder(
                                          context,
                                          customer: customer,
                                          store: store,
                                          strings: strings,
                                          formatMoney: (val) => _money(val),
                                        ),
                                      ),
                                    ),
                                  )
                                ])),
                          if (entries.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            MarketSectionHeader(
                              title:
                                  _dual(strings, 'Recent activity', 'Shughuli'),
                              trailing: Text(
                                _dual(strings, 'Latest 20', 'Hadi 20'),
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: LedgerTile(
                                  entry: entry,
                                  strings: strings,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          )),
    );
  }

  static DateTime? _oldestDebtDate(
      List<CustomerData> debtors, PosLocalStore store) {
    DateTime? oldest;
    for (final customer in debtors) {
      final date = _oldestCharge(customer, store);
      if (date == null) continue;
      if (oldest == null || date.isBefore(oldest)) oldest = date;
    }
    return oldest;
  }

  void _sortDebtors(List<CustomerData> list, PosLocalStore store) {
    switch (_sort) {
      case LedgerSortMode.balance:
        list.sort((a, b) => b.debitBalance.compareTo(a.debitBalance));
        break;
      case LedgerSortMode.oldest:
        list.sort((a, b) {
          final aDate = _oldestCharge(a, store);
          final bDate = _oldestCharge(b, store);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
        break;
      case LedgerSortMode.recent:
        list.sort((a, b) {
          final aDate = _latestActivity(a, store);
          final bDate = _latestActivity(b, store);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        break;
      case LedgerSortMode.overdue:
        list.sort((a, b) {
          final aDays = DebitStatementService.getAgingDays(a, store);
          final bDays = DebitStatementService.getAgingDays(b, store);
          return bDays.compareTo(aDays);
        });
        break;
    }
  }

  static DateTime? _oldestCharge(CustomerData customer, PosLocalStore store) {
    final charges = store
        .debitEntriesFor(customer.id)
        .where((entry) => !entry.isPayment)
        .toList();
    if (charges.isEmpty) return null;
    return charges.last.createdAt;
  }

  static DateTime? _latestActivity(CustomerData customer, PosLocalStore store) {
    final entries = store.debitEntriesFor(customer.id);
    if (entries.isEmpty) return null;
    return entries.first.createdAt;
  }

  Future<void> _pickSort() async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final picked = await showModalBottomSheet<LedgerSortMode>(
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
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: 12),
            Text(_dual(strings, 'Sort debtors by', 'Panga wadaiwa kwa'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final mode in LedgerSortMode.values)
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

  void _openCustomer(CustomerData customer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerDetailsPage(customerId: customer.id),
      ),
    );
  }

  Future<void> _settle(CustomerData customer) async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final result = await showRecordPaymentSheet(context, customer: customer);
    if (result == null || !mounted) return;

    final store = context.read<PosLocalStore>();
    final applied = await store.recordDebtPayment(
      customerId: customer.id,
      amount: result.amount,
      note: result.note,
    );

    if (!mounted) return;
    if (applied == null) {
      showMarketNotice(
        context,
        title: _dual(strings, 'Payment not applied', 'Malipo hayajatumika'),
        message: _dual(strings, 'This customer has nothing outstanding.',
            'Mteja huyu hana deni.'),
        type: MarketNoticeType.warning,
      );
      return;
    }

    showMarketNotice(
      context,
      title: _dual(strings, 'Payment recorded', 'Malipo yamerekodiwa'),
      message: _dual(
        strings,
        '${_money(result.amount)} received from ${customer.name}. Balance ${_money(applied.debitBalance)}.',
        '${_money(result.amount)} yamepokelewa kutoka ${customer.name}. Deni ${_money(applied.debitBalance)}.',
      ),
    );
  }
}
