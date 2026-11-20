import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/expense_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'add_expense_page.dart';
import 'widgets/expense_cards.dart';
import 'widgets/expense_details_sheet.dart';
import 'widgets/expense_export_service.dart';
import 'widgets/expense_filter_widgets.dart';
import 'widgets/expense_models.dart';

class ExpensesTrackingPage extends StatefulWidget {
  const ExpensesTrackingPage({super.key});

  @override
  State<ExpensesTrackingPage> createState() => _ExpensesTrackingPageState();
}

class _ExpensesTrackingPageState extends State<ExpensesTrackingPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String _paymentFilter = 'All';
  ExpenseRange _range = ExpenseRange.thisMonth;
  ExpenseSortMode _sort = ExpenseSortMode.newest;
  DateTimeRange? _customRange;
  bool _exporting = false;

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
              final all = List<Expense>.from(store.expenses);
              final inRange = _applyRange(all);
              final payments = <String>{
                'All',
                ...all
                    .map((e) => e.paymentMethod)
                    .where((e) => e.trim().isNotEmpty),
              }.toList()
                ..sort();

              final filtered = inRange.where((e) {
                final q = _search.trim().toLowerCase();
                final matchesSearch = q.isEmpty ||
                    e.title.toLowerCase().contains(q) ||
                    e.category.toLowerCase().contains(q) ||
                    e.paymentMethod.toLowerCase().contains(q) ||
                    e.vendor.toLowerCase().contains(q) ||
                    (e.notes ?? '').toLowerCase().contains(q);
                final matchesPayment = _paymentFilter == 'All' ||
                    e.paymentMethod == _paymentFilter;
                return matchesSearch && matchesPayment;
              }).toList();
              _sortList(filtered);

              final total =
                  filtered.fold<double>(0, (s, e) => s + e.totalWithTax);
              final taxTotal =
                  filtered.fold<double>(0, (s, e) => s + e.taxAmount);
              final byPayment = <String, double>{};
              for (final e in filtered) {
                final k = e.paymentMethod.trim().isEmpty
                    ? expenseDual(strings, 'Unspecified', 'Haijabainishwa')
                    : e.paymentMethod;
                byPayment[k] = (byPayment[k] ?? 0) + e.totalWithTax;
              }
              final paymentSummary = byPayment.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Column(
                children: [
                  MarketPageHeader(
                    title: expenseDual(strings, 'Expenses', 'Matumizi'),
                    subtitle: expenseDual(
                        strings,
                        'Track and review recorded expenses',
                        'Fuatilia na pitia matumizi yaliyorekodiwa'),
                    showBorder: false,
                    actions: [
                      IconButton(
                        tooltip: expenseDual(strings, 'Export', 'Hamisha'),
                        onPressed: filtered.isEmpty || _exporting
                            ? null
                            : () => _showExportMenu(filtered),
                        icon: const Icon(Icons.ios_share_rounded,
                            color: AppColors.ink),
                      ),
                    ],
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
                                    label: expenseDual(strings, 'Total spent',
                                        'Jumla ya matumizi'),
                                    value: formatExpenseMoney(total, compact: true),
                                    icon: Icons.payments_outlined,
                                    sharp: true,
                                    borderless: true,
                                    backgroundColor: const Color(0xFFFEE2E2),
                                    color: const Color(0xFFB91C1C),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: WorkspaceMetric(
                                    label: expenseDual(strings, 'Total records',
                                        'Idadi ya kumbukumbu'),
                                    value: '${filtered.length}',
                                    icon: Icons.receipt_long_outlined,
                                    sharp: true,
                                    borderless: true,
                                    backgroundColor: const Color(0xFFE0F2FE),
                                    color: const Color(0xFF0369A1),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: WorkspaceMetric(
                                    label: expenseDual(strings, 'Average expense',
                                        'Wastani wa matumizi'),
                                    value: formatExpenseMoney(
                                      filtered.isEmpty
                                          ? 0
                                          : total / filtered.length,
                                      compact: true,
                                    ),
                                    icon: Icons.query_stats_rounded,
                                    sharp: true,
                                    borderless: true,
                                    backgroundColor: const Color(0xFFFEF3C7),
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: WorkspaceMetric(
                                    label: expenseDual(strings, 'Tax included',
                                        'Kodi iliyojumuishwa'),
                                    value: formatExpenseMoney(taxTotal,
                                        compact: true),
                                    icon: Icons.account_balance_outlined,
                                    sharp: true,
                                    borderless: true,
                                    backgroundColor: taxTotal > 0
                                        ? const Color(0xFFEDE9FE)
                                        : const Color(0xFFF1F5F9),
                                    color: taxTotal > 0
                                        ? const Color(0xFF6D28D9)
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (taxTotal > 0) ...[
                          const SizedBox(height: 10),
                          ExpenseTaxBanner(amount: taxTotal, strings: strings),
                        ],
                        const SizedBox(height: 12),
                        ExpenseRangeCard(
                          label: _rangeLabel(strings),
                          sortLabel: _sort.label(strings),
                          sortIcon: _sort.icon,
                          onPickRange: _pickRange,
                          onCustomRange: _pickCustomRange,
                          onPickSort: _pickSort,
                          strings: strings,
                        ),
                        const SizedBox(height: 12),
                        MarketSearchField(
                          controller: _searchController,
                          hintText: expenseDual(
                              strings, 'Search expenses', 'Tafuta matumizi'),
                          radius: 0,
                          showShadow: false,
                          onChanged: (v) => setState(() => _search = v),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        ),
                        const SizedBox(height: 10),
                        ExpensePaymentFilterRow(
                          payments: payments,
                          value: _paymentFilter,
                          strings: strings,
                          onChanged: (v) =>
                              setState(() => _paymentFilter = v),
                        ),
                        if (paymentSummary.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ExpensePaymentSummaryCard(
                              items: paymentSummary, strings: strings),
                        ],
                        const SizedBox(height: 18),
                        MarketSectionHeader(
                          title: expenseDual(strings, 'Expense Records',
                              'Kumbukumbu za Matumizi'),
                          trailing: Text(
                            expenseDual(
                                strings,
                                '${filtered.length} entr${filtered.length == 1 ? 'y' : 'ies'}',
                                '${filtered.length} rekodi'),
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filtered.isEmpty)
                          ExpenseEmptyState(
                            strings: strings,
                            isFiltered: _search.isNotEmpty || _paymentFilter != 'All' || inRange.length != all.length,
                            onAdd: _openAddExpense,
                            onClearFilter: () {
                              _searchController.clear();
                              setState(() {
                                _search = '';
                                _paymentFilter = 'All';
                                _range = ExpenseRange.thisMonth;
                              });
                            },
                          )
                        else
                          WorkspaceRegister(
                            columns: [
                              DataColumn(
                                  label: Text(
                                      expenseDual(strings, 'Date', 'Tarehe'))),
                              DataColumn(
                                  label: Text(expenseDual(
                                      strings, 'Expense', 'Matumizi'))),
                              DataColumn(
                                  label: Text(
                                      expenseDual(strings, 'Category', 'Kundi'))),
                              DataColumn(
                                  label: Text(
                                      expenseDual(strings, 'Payment', 'Malipo'))),
                              DataColumn(
                                  label: Text(
                                      expenseDual(strings, 'Status', 'Hali'))),
                              DataColumn(
                                  label: Text(
                                      expenseDual(strings, 'Total', 'Jumla')),
                                  numeric: true),
                              const DataColumn(label: Text('')),
                            ],
                            rows: filtered
                                .map((expense) => DataRow(cells: [
                                      DataCell(Text(DateFormat.yMMMd()
                                          .format(expense.date))),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 220),
                                          child: Text(expense.title,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        onTap: () =>
                                            _showExpense(context, expense),
                                      ),
                                      DataCell(Text(expense.category)),
                                      DataCell(Text(expense.paymentMethod)),
                                      DataCell(WorkspaceStatus(
                                          label: expense.status
                                              .localized(strings.isSwahili),
                                          color: AppColors.textBody)),
                                      DataCell(Text(formatExpenseMoney(
                                          expense.totalWithTax))),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: expenseDual(
                                                strings,
                                                'Edit expense',
                                                'Badili matumizi'),
                                            onPressed: () =>
                                                _openEditExpense(expense),
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 19),
                                          ),
                                          IconButton(
                                            tooltip: expenseDual(
                                                strings,
                                                'Delete expense',
                                                'Futa matumizi'),
                                            onPressed: expense.id == null
                                                ? null
                                                : () => _confirmDelete(
                                                    context, store, expense),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 19,
                                              color: AppColors.dangerDeep,
                                            ),
                                          ),
                                        ],
                                      )),
                                    ]))
                                .toList(),
                            mobile: Column(
                              children: [
                                ...filtered.map(
                                  (expense) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ExpenseCard(
                                      expense: expense,
                                      strings: strings,
                                      onTap: () =>
                                          _showExpense(context, expense),
                                      onEdit: () => _openEditExpense(expense),
                                      onDelete: expense.id == null
                                          ? null
                                          : () => _confirmDelete(
                                              context, store, expense),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final strings =
              AppStrings.of(context.watch<PosLocalStore>().languageCode);
          return AddExpenseFloatingButton(
            label: expenseDual(strings, 'Add Expense', 'Ongeza Matumizi'),
            onTap: _openAddExpense,
          );
        },
      ),
    );
  }

  void _sortList(List<Expense> list) {
    switch (_sort) {
      case ExpenseSortMode.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ExpenseSortMode.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ExpenseSortMode.highest:
        list.sort((a, b) => b.totalWithTax.compareTo(a.totalWithTax));
        break;
      case ExpenseSortMode.lowest:
        list.sort((a, b) => a.totalWithTax.compareTo(b.totalWithTax));
        break;
    }
  }

  void _openAddExpense() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddExpensePage()),
    );
  }

  void _openEditExpense(Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddExpensePage(expense: expense),
      ),
    );
  }

  Future<void> _pickSort() async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final picked = await showModalBottomSheet<ExpenseSortMode>(
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
                    color: AppColors.border, borderRadius: BorderRadius.zero)),
            const SizedBox(height: 12),
            Text(expenseDual(strings, 'Sort by', 'Panga kwa'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final mode in ExpenseSortMode.values)
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
    if (picked == null) return;
    setState(() => _sort = picked);
  }

  Future<void> _showExportMenu(List<Expense> currentItems) async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final choice = await showModalBottomSheet<String>(
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
                    color: AppColors.border, borderRadius: BorderRadius.zero)),
            const SizedBox(height: 12),
            Text(expenseDual(strings, 'Export expenses', 'Hamisha matumizi'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.table_view_rounded,
                  color: AppColors.primary, size: 20),
              title: Text(
                  expenseDual(strings, 'Export as CSV', 'Hamisha kama CSV'),
                  style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(ctx).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.ink, size: 20),
              title: Text(
                  expenseDual(strings, 'Export as PDF', 'Hamisha kama PDF'),
                  style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      if (choice == 'csv') {
        await ExpenseExportService.exportCsv(
          context: context,
          expenses: currentItems,
          strings: strings,
        );
      } else if (choice == 'pdf') {
        await ExpenseExportService.exportPdf(
          context: context,
          expenses: currentItems,
          strings: strings,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  List<Expense> _applyRange(List<Expense> items) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    switch (_range) {
      case ExpenseRange.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case ExpenseRange.thisWeek:
        start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case ExpenseRange.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case ExpenseRange.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 1);
        break;
      case ExpenseRange.all:
        return items;
      case ExpenseRange.custom:
        if (_customRange == null) return items;
        start = DateTime(_customRange!.start.year, _customRange!.start.month,
            _customRange!.start.day);
        end = DateTime(_customRange!.end.year, _customRange!.end.month,
                _customRange!.end.day)
            .add(const Duration(days: 1));
        break;
    }
    return items
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .toList();
  }

  String _rangeLabel(AppStrings strings) {
    if (_range == ExpenseRange.custom && _customRange != null) {
      final f = DateFormat('MMM d, yyyy');
      return '${f.format(_customRange!.start)} - ${f.format(_customRange!.end)}';
    }
    return _range.label(strings);
  }

  Future<void> _pickRange() async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final selected = await showModalBottomSheet<ExpenseRange>(
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
                    color: AppColors.border, borderRadius: BorderRadius.zero)),
            const SizedBox(height: 12),
            Text(expenseDual(strings, 'Select period', 'Chagua kipindi'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final r in ExpenseRange.values)
              ListTile(
                title: Text(r.label(strings), style: AppTypography.bodyMedium),
                trailing: r == _range
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _range = selected);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.ink,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _range = ExpenseRange.custom;
    });
  }

  Future<void> _showExpense(BuildContext context, Expense expense) async {
    final store = context.read<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    await ExpenseDetailSheet.show(
      context: context,
      expense: expense,
      strings: strings,
      onEdit: () => _openEditExpense(expense),
      onDelete: () => _confirmDelete(context, store, expense),
    );
  }

  Future<void> _confirmDelete(
      BuildContext ctx, PosLocalStore store, Expense expense) async {
    if (expense.id == null) return;
    final strings = AppStrings.of(store.languageCode);
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(expenseDual(strings, 'Delete expense?', 'Futa matumizi?'),
            style: AppTypography.cardHeader),
        content: Text(
            expenseDual(
                strings,
                'This will remove "${expense.title}" from recorded expenses.',
                'Hili litaondoa "${expense.title}" kwenye matumizi yaliyorekodiwa.'),
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(strings.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(expenseDual(strings, 'Delete', 'Futa'))),
        ],
      ),
    );
    if (ok != true) return;
    await store.deleteExpense(expense.id!);
    if (!mounted) return;
    showMarketNotice(context,
        title: expenseDual(strings, 'Expense deleted', 'Matumizi yamefutwa'),
        message: expenseDual(strings, 'The expense record was removed.',
            'Rekodi ya matumizi imeondolewa.'));
  }
}
