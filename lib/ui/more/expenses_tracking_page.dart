import '../../service/report_pdf/report_pdf_context.dart';
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
import 'widgets/expense_kpi_metrics.dart';
import 'widgets/expense_history_register.dart';

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
                        icon: Icon(Icons.ios_share_rounded,
                            color: AppColors.ink),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
                      children: [
                        ExpenseKpiMetrics(
                          total: total,
                          totalRecords: filtered.length,
                          taxTotal: taxTotal,
                          strings: strings,
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
                          radius: AppRadius.input,
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
                          onChanged: (v) => setState(() => _paymentFilter = v),
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
                            isFiltered: _search.isNotEmpty ||
                                _paymentFilter != 'All' ||
                                inRange.length != all.length,
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
                          ExpenseHistoryRegister(
                            filtered: filtered,
                            strings: strings,
                            store: store,
                            onShowExpense: _showExpense,
                            onEditExpense: _openEditExpense,
                            onConfirmDelete: _confirmDelete,
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
            Text(expenseDual(strings, 'Sort by', 'Panga kwa'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final mode in ExpenseSortMode.values)
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
    if (picked == null) return;
    setState(() => _sort = picked);
  }

  Future<void> _showExportMenu(List<Expense> currentItems) async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final choice = await showModalBottomSheet<String>(
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
            Text(expenseDual(strings, 'Export expenses', 'Hamisha matumizi'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.table_view_rounded,
                  color: AppColors.primary, size: 20),
              title: Text(
                  expenseDual(strings, 'Export as CSV', 'Hamisha kama CSV'),
                  style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(ctx).pop('csv'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf_rounded,
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
          pdfContext: ReportPdfContext.fromStore(context.read<PosLocalStore>(),
              languageCode: strings.languageCode,
              period: _range == ExpenseRange.custom && _customRange != null
                  ? '${DateFormat('yyyy-MM-dd').format(_customRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_customRange!.end)}'
                  : _range.label(strings),
              filterSummary: [
                if (_search.trim().isNotEmpty)
                  '${strings.text('Search')}: ${_search.trim()}',
                if (_paymentFilter != 'All')
                  strings.paymentMethod(_paymentFilter),
                '${strings.text('Sort')}: ${_sort.label(strings)}',
              ].join(' | ')),
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
            Text(expenseDual(strings, 'Select period', 'Chagua kipindi'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final r in ExpenseRange.values)
              ListTile(
                title: Text(r.label(strings), style: AppTypography.bodyMedium),
                trailing: r == _range
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
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
    final ok = await showMarketConfirmDialog(
      ctx,
      title: expenseDual(strings, 'Delete expense?', 'Futa matumizi?'),
      message: expenseDual(
        strings,
        'This will remove "${expense.title}" from recorded expenses.',
        'Hili litaondoa "${expense.title}" kwenye matumizi yaliyorekodiwa.',
      ),
      confirmLabel: expenseDual(strings, 'Delete', 'Futa'),
      cancelLabel: strings.cancel,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok) return;
    await store.deleteExpense(expense.id!);
    if (!mounted) return;
    showMarketNotice(context,
        title: expenseDual(strings, 'Expense deleted', 'Matumizi yamefutwa'),
        message: expenseDual(strings, 'The expense record was removed.',
            'Rekodi ya matumizi imeondolewa.'));
  }
}
