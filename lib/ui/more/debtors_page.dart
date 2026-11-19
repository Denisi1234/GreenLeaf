import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/debit_entry_model.dart';
import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';
import '../widgets/market_shared_widgets.dart';
import 'customer_details_page.dart';
import 'record_payment_sheet.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _money(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

enum _LedgerSort { balance, oldest, recent }

extension on _LedgerSort {
  String label(AppStrings strings) => switch (this) {
        _LedgerSort.balance => _dual(strings, 'Highest balance', 'Deni kubwa'),
        _LedgerSort.oldest => _dual(strings, 'Oldest debt', 'Deni la zamani'),
        _LedgerSort.recent =>
          _dual(strings, 'Recent activity', 'Shughuli mpya'),
      };

  IconData get icon => switch (this) {
        _LedgerSort.balance => Icons.trending_down_rounded,
        _LedgerSort.oldest => Icons.history_rounded,
        _LedgerSort.recent => Icons.schedule_rounded,
      };
}

class DebtorsPage extends StatefulWidget {
  const DebtorsPage({super.key});

  @override
  State<DebtorsPage> createState() => _DebtorsPageState();
}

class _DebtorsPageState extends State<DebtorsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  _LedgerSort _sort = _LedgerSort.balance;

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

                return Column(
                  children: [
                    MarketPageHeader(
                      title: strings.debitLedger,
                      subtitle: _dual(strings, 'Credit sales and repayments',
                          'Mauzo ya mkopo na malipo'),
                      showBorder: false,
                    ),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                        children: [
                          LayoutBuilder(
                            builder: (context, metricConstraints) {
                              final columns =
                                  metricConstraints.maxWidth >= 760 ? 3 : 1;
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
                                      color: outstanding > 0
                                          ? AppColors.dangerDeep
                                          : AppColors.ink,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: WorkspaceMetric(
                                      label: _dual(strings, 'Debtors count',
                                          'Idadi ya wadaiwa'),
                                      value: '${debtors.length}',
                                      icon: Icons.people_alt_outlined,
                                      color: AppColors.primaryDeep,
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
                                      color: AppColors.successDeep,
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
                            radius: AppRadius.standard,
                            showShadow: false,
                            onChanged: (value) =>
                                setState(() => _search = value),
                            onClear: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                          const SizedBox(height: 10),
                          _SortRow(
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
                            _EmptyDebtors(
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
                                      label: Text(_dual(
                                          strings,
                                          'Outstanding balance',
                                          'Deni lililobaki')),
                                      numeric: true),
                                  const DataColumn(label: Text('')),
                                ],
                                rows: visible
                                    .map((customer) => DataRow(cells: [
                                          DataCell(Text(customer.name),
                                              onTap: () =>
                                                  _openCustomer(customer)),
                                          DataCell(Text(customer.phone)),
                                          DataCell(Text(
                                              _money(customer.debitBalance),
                                              style: const TextStyle(
                                                  color: AppColors.dangerDeep,
                                                  fontWeight:
                                                      FontWeight.w700))),
                                          DataCell(OutlinedButton.icon(
                                              onPressed: () =>
                                                  _settle(customer),
                                              icon: const Icon(
                                                  Icons.payments_outlined,
                                                  size: 18),
                                              label: Text(_dual(
                                                  strings,
                                                  'Record payment',
                                                  'Rekodi malipo')))),
                                        ]))
                                    .toList(),
                                mobile: Column(children: [
                                  ...visible.map(
                                    (customer) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _DebtorCard(
                                        customer: customer,
                                        store: store,
                                        strings: strings,
                                        onTap: () => _openCustomer(customer),
                                        onSettle: () => _settle(customer),
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
                                child: _LedgerTile(
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
      case _LedgerSort.balance:
        list.sort((a, b) => b.debitBalance.compareTo(a.debitBalance));
        break;
      case _LedgerSort.oldest:
        list.sort((a, b) {
          final aDate = _oldestCharge(a, store);
          final bDate = _oldestCharge(b, store);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
        break;
      case _LedgerSort.recent:
        list.sort((a, b) {
          final aDate = _latestActivity(a, store);
          final bDate = _latestActivity(b, store);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
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
    final picked = await showModalBottomSheet<_LedgerSort>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.zero,
              ),
            ),
            const SizedBox(height: 12),
            Text(_dual(strings, 'Sort debtors by', 'Panga wadaiwa kwa'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final mode in _LedgerSort.values)
              ListTile(
                leading: Icon(mode.icon, color: AppColors.textMuted, size: 20),
                title:
                    Text(mode.label(strings), style: AppTypography.bodyMedium),
                trailing: mode == _sort
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
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

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.sort,
    required this.strings,
    required this.oldestDebt,
    required this.onPick,
  });

  final _LedgerSort sort;
  final AppStrings strings;
  final DateTime? oldestDebt;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: false,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.zero,
            ),
            child:
                const Icon(Icons.rule_rounded, color: AppColors.ink, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dual(strings, 'Sort order', 'Mpangilio'),
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sort.label(strings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (oldestDebt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_dual(strings, 'Oldest unpaid charge', 'Deni la zamani halijalipwa')}: ${DateFormat('MMM d, yyyy').format(oldestDebt!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.textLight,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: _dual(strings, 'Sort', 'Panga'),
            onPressed: onPick,
            icon: const Icon(Icons.tune_rounded,
                color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DebtorCard extends StatelessWidget {
  const _DebtorCard({
    required this.customer,
    required this.store,
    required this.strings,
    required this.onTap,
    required this.onSettle,
  });

  final CustomerData customer;
  final PosLocalStore store;
  final AppStrings strings;
  final VoidCallback onTap;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final entries = store.debitEntriesFor(customer.id);
    final charges = entries
        .where((entry) => !entry.isPayment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final paid = entries
        .where((entry) => entry.isPayment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final last = entries.isEmpty ? null : entries.first;

    return MarketSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: const Color(0xFFD6E4F0),
      radius: 10,
      showShadow: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customer.initials,
                      style: AppTypography.cardHeader.copyWith(
                        color: AppColors.ink,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMain.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.phone.trim().isEmpty
                              ? _dual(strings, 'No phone', 'Hakuna simu')
                              : customer.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.helperText.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _money(customer.debitBalance, compact: true),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        _dual(strings, 'OWED', 'DENO'),
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _LedgerMetric(
                      label: _dual(strings, 'Charged', 'Deni'),
                      value: _money(charges, compact: true),
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LedgerMetric(
                      label: _dual(strings, 'Paid', 'Malipo'),
                      value: _money(paid, compact: true),
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LedgerMetric(
                      label: _dual(strings, 'Entries', 'Rekodi'),
                      value: '${entries.length}',
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
              if (last != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      last.isPayment
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 12,
                      color: last.isPayment ? AppColors.success : AppColors.ink,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${last.type.localized(strings.isSwahili)} · ${DateFormat('MMM d').format(last.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFD6E4F0)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onTap,
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: Text(_dual(strings, 'Statement', 'Taarifa')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        highlightColor: Colors.transparent,
                        onTap: onSettle,
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _dual(strings, 'Receive', 'Pokea'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerMetric extends StatelessWidget {
  const _LedgerMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry, required this.strings});

  final DebitEntry entry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color = isPayment ? AppColors.success : AppColors.ink;
    final background =
        isPayment ? AppColors.successLight : AppColors.surfaceSecondary;

    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: const Color(0xFFD6E4F0),
      radius: 10,
      showShadow: true,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPayment ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.customerName} · ${entry.type.localized(strings.isSwahili)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    DateFormat('MMM d, yyyy').format(entry.createdAt),
                    if (entry.note.trim().isNotEmpty) entry.note.trim(),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isPayment ? '-' : '+'}${_money(entry.amount, compact: true)}',
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDebtors extends StatelessWidget {
  const _EmptyDebtors({
    required this.strings,
    required this.filtered,
    required this.onReset,
  });

  final AppStrings strings;
  final bool filtered;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(28),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: false,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              filtered ? Icons.search_off_rounded : Icons.verified_rounded,
              color: AppColors.success,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            filtered
                ? _dual(strings, 'No matching debtors', 'Hakuna wadaiwa')
                : _dual(strings, 'No debts recorded', 'Hakuna madeni'),
            style: AppTypography.cardHeader,
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? _dual(strings, 'Try another name or phone number.',
                    'Jaribu jina au namba nyingine.')
                : _dual(
                    strings,
                    'Credit sales from the counter appear here with full statements.',
                    'Mauzo ya mkopo kutoka kaunta yanaonekana hapa na taarifa kamili.'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          if (filtered) ...[
            const SizedBox(height: 16),
            MarketButton(
              label: _dual(strings, 'Clear search', 'Ondoa utafutaji'),
              icon: Icons.filter_alt_off_rounded,
              isFullWidth: false,
              onTap: onReset,
            ),
          ],
        ],
      ),
    );
  }
}

