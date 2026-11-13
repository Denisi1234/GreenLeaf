import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings.dart';
import '../../service/expense_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/app_image.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_expense_page.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _formatMoney(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

enum _SortMode { newest, oldest, highest, lowest }

extension on _SortMode {
  String label(AppStrings strings) => switch (this) {
        _SortMode.newest => _dual(strings, 'Newest first', 'Mpya kwanza'),
        _SortMode.oldest => _dual(strings, 'Oldest first', 'Zamani kwanza'),
        _SortMode.highest => _dual(strings, 'Highest amount', 'Kiasi kikubwa'),
        _SortMode.lowest => _dual(strings, 'Lowest amount', 'Kiasi kidogo'),
      };

  IconData get icon => switch (this) {
        _SortMode.newest => Icons.schedule_rounded,
        _SortMode.oldest => Icons.history_rounded,
        _SortMode.highest => Icons.trending_up_rounded,
        _SortMode.lowest => Icons.trending_down_rounded,
      };
}

class ExpensesTrackingPage extends StatefulWidget {
  const ExpensesTrackingPage({super.key});

  @override
  State<ExpensesTrackingPage> createState() => _ExpensesTrackingPageState();
}

class _ExpensesTrackingPageState extends State<ExpensesTrackingPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String _paymentFilter = 'All';
  _ExpenseRange _range = _ExpenseRange.thisMonth;
  _SortMode _sort = _SortMode.newest;
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
      body: SafeArea(
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
              final matchesPayment =
                  _paymentFilter == 'All' || e.paymentMethod == _paymentFilter;
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
                  ? _dual(strings, 'Unspecified', 'Haijabainishwa')
                  : e.paymentMethod;
              byPayment[k] = (byPayment[k] ?? 0) + e.totalWithTax;
            }
            final paymentSummary = byPayment.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Column(
              children: [
                MarketPageHeader(
                  title: _dual(strings, 'Expenses', 'Matumizi'),
                  subtitle: _dual(strings, 'Track and review recorded expenses',
                      'Fuatilia na pitia matumizi yaliyorekodiwa'),
                  showBorder: false,
                  actions: [
                    IconButton(
                      tooltip: _dual(strings, 'Export', 'Hamisha'),
                      onPressed: filtered.isEmpty || _exporting
                          ? null
                          : _showExportMenu,
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
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: _dual(strings, 'Total spent', 'Jumla'),
                              value: _formatMoney(total, compact: true),
                              icon: Icons.payments_outlined,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: _dual(strings, 'Records', 'Kumbukumbu'),
                              value: '${filtered.length}',
                              icon: Icons.receipt_long_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: _dual(strings, 'Average', 'Wastani'),
                              value: _formatMoney(
                                filtered.isEmpty ? 0 : total / filtered.length,
                                compact: true,
                              ),
                              icon: Icons.trending_up_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      if (taxTotal > 0) ...[
                        const SizedBox(height: 10),
                        _TaxBanner(
                          amount: taxTotal,
                          strings: strings,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _RangeCard(
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
                        hintText: _dual(
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
                      _PaymentFilterRow(
                        payments: payments,
                        value: _paymentFilter,
                        strings: strings,
                        onChanged: (v) => setState(() => _paymentFilter = v),
                      ),
                      if (paymentSummary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _PaymentSummaryCard(
                            items: paymentSummary, strings: strings),
                      ],
                      const SizedBox(height: 18),
                      MarketSectionHeader(
                        title: _dual(strings, 'Expense Records',
                            'Kumbukumbu za Matumizi'),
                        trailing: Text(
                          _dual(
                              strings,
                              '${filtered.length} entr${filtered.length == 1 ? 'y' : 'ies'}',
                              '${filtered.length} rekodi'),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (filtered.isEmpty)
                        _EmptyState(
                          strings: strings,
                          onAdd: _openAddExpense,
                        )
                      else
                        ...filtered.map(
                          (expense) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ExpenseCard(
                              expense: expense,
                              strings: strings,
                              onTap: () => _showExpense(context, expense),
                              onEdit: () => _openEditExpense(expense),
                              onDelete: expense.id == null
                                  ? null
                                  : () =>
                                      _confirmDelete(context, store, expense),
                            ),
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
      floatingActionButton: Builder(
        builder: (context) {
          final strings =
              AppStrings.of(context.watch<PosLocalStore>().languageCode);
          return _AddExpenseButton(
            label: _dual(strings, 'Add Expense', 'Ongeza Matumizi'),
            onTap: _openAddExpense,
          );
        },
      ),
    );
  }

  void _sortList(List<Expense> list) {
    switch (_sort) {
      case _SortMode.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortMode.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortMode.highest:
        list.sort((a, b) => b.totalWithTax.compareTo(a.totalWithTax));
        break;
      case _SortMode.lowest:
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
    final picked = await showModalBottomSheet<_SortMode>(
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
            Text(_dual(strings, 'Sort by', 'Panga kwa'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final mode in _SortMode.values)
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

  Future<void> _showExportMenu() async {
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
            Text(_dual(strings, 'Export expenses', 'Hamisha matumizi'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.table_view_rounded,
                  color: AppColors.primary, size: 20),
              title: Text(_dual(strings, 'Export as CSV', 'Hamisha kama CSV'),
                  style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(ctx).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.ink, size: 20),
              title: Text(_dual(strings, 'Export as PDF', 'Hamisha kama PDF'),
                  style: AppTypography.bodyMedium),
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'csv') {
      await _exportCsv();
    } else if (choice == 'pdf') {
      await _exportPdf();
    }
  }

  List<Expense> _currentVisible() {
    final store = context.read<PosLocalStore>();
    final all = List<Expense>.from(store.expenses);
    final inRange = _applyRange(all);
    final filtered = inRange.where((e) {
      final q = _search.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.paymentMethod.toLowerCase().contains(q) ||
          e.vendor.toLowerCase().contains(q) ||
          (e.notes ?? '').toLowerCase().contains(q);
      final matchesPayment =
          _paymentFilter == 'All' || e.paymentMethod == _paymentFilter;
      return matchesSearch && matchesPayment;
    }).toList();
    _sortList(filtered);
    return filtered;
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    final rows = _currentVisible();
    final buffer = StringBuffer();
    buffer.writeln(
        'Title,Vendor,Category,Payment Method,Date,Amount,Tax,Total,Status,Notes');
    for (final e in rows) {
      final cells = <String>[
        e.title,
        e.vendor,
        e.category,
        e.paymentMethod,
        DateFormat('yyyy-MM-dd').format(e.date),
        e.amount.toStringAsFixed(2),
        e.taxAmount.toStringAsFixed(2),
        e.totalWithTax.toStringAsFixed(2),
        e.status.label,
        e.notes ?? '',
      ].map(_csvCell).join(',');
      buffer.writeln(cells);
    }
    await _shareBytes(
      Uint8List.fromList(utf8.encode(buffer.toString())),
      'expenses_${_stamp()}.csv',
      'text/csv',
    );
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    final rows = _currentVisible();
    final doc = pw.Document();
    final total = rows.fold<double>(0, (s, e) => s + e.totalWithTax);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(24),
        ),
        header: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Expense Report',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('${rows.length} records · Total ${_formatMoney(total)}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Title',
              'Vendor',
              'Category',
              'Payment',
              'Date',
              'Amount',
              'Tax',
              'Total',
              'Status'
            ],
            data: rows
                .map((e) => [
                      e.title,
                      e.vendor,
                      e.category,
                      e.paymentMethod,
                      DateFormat('yyyy-MM-dd').format(e.date),
                      _formatMoney(e.amount),
                      _formatMoney(e.taxAmount),
                      _formatMoney(e.totalWithTax),
                      e.status.label,
                    ])
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'expenses_${_stamp()}.pdf');
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _shareBytes(Uint8List bytes, String name, String mime) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: mime)]),
      );
    } catch (error) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: _dual(AppStrings.of(context.read<PosLocalStore>().languageCode),
            'Export failed', 'Imeshindwa kuhamisha'),
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
    }
  }

  String _stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  String _csvCell(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  List<Expense> _applyRange(List<Expense> items) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    switch (_range) {
      case _ExpenseRange.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case _ExpenseRange.thisWeek:
        start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case _ExpenseRange.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case _ExpenseRange.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 1);
        break;
      case _ExpenseRange.all:
        return items;
      case _ExpenseRange.custom:
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
    if (_range == _ExpenseRange.custom && _customRange != null) {
      final f = DateFormat('MMM d, yyyy');
      return '${f.format(_customRange!.start)} - ${f.format(_customRange!.end)}';
    }
    return _range.label(strings);
  }

  Future<void> _pickRange() async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final selected = await showModalBottomSheet<_ExpenseRange>(
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
            Text(_dual(strings, 'Select period', 'Chagua kipindi'),
                style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final r in _ExpenseRange.values)
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
      _range = _ExpenseRange.custom;
    });
  }

  Future<void> _showExpense(BuildContext context, Expense expense) async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final fmt = DateFormat('MMM d, yyyy');
    final cat = _CategoryStyle.forName(expense.category);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: const BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.zero)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _CategoryIcon(style: cat, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.title,
                              style: AppTypography.h3.copyWith(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(expense.category,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    _StatusBadge(status: expense.status, strings: strings),
                  ],
                ),
                const SizedBox(height: 14),
                Text(_formatMoney(expense.totalWithTax),
                    style: AppTypography.h2
                        .copyWith(color: AppColors.ink, fontSize: 24)),
                const SizedBox(height: 16),
                _DetailRow(
                    label: _dual(strings, 'Date', 'Tarehe'),
                    value: fmt.format(expense.date)),
                _DetailRow(
                    label: _dual(strings, 'Category', 'Kategoria'),
                    value: expense.category),
                _DetailRow(
                    label: _dual(strings, 'Payment', 'Malipo'),
                    value: expense.paymentMethod),
                _DetailRow(
                    label: _dual(strings, 'Vendor', 'Muuzaji'),
                    value: expense.vendor.trim().isEmpty
                        ? _dual(strings, 'Not set', 'Haijawekwa')
                        : expense.vendor),
                _DetailRow(
                    label: _dual(strings, 'Base amount', 'Kiasi msingi'),
                    value: _formatMoney(expense.amount)),
                if (expense.taxAmount > 0)
                  _DetailRow(
                      label: _dual(strings, 'Tax / VAT', 'Kodi / VAT'),
                      value: _formatMoney(expense.taxAmount)),
                _DetailRow(
                    label: _dual(strings, 'Status', 'Hali'),
                    value: expense.status.localized(strings.isSwahili)),
                if ((expense.notes ?? '').trim().isNotEmpty)
                  _DetailRow(
                      label: _dual(strings, 'Notes', 'Maelezo'),
                      value: expense.notes!.trim()),
                if (expense.receiptPath != null &&
                    expense.receiptPath!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_dual(strings, 'Receipt', 'Risiti'),
                      style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: Image(
                      image: appImageProvider(context, expense.receiptPath!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 60,
                        color: AppColors.surfaceSecondary,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: AppColors.textLight),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openEditExpense(expense);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(_dual(strings, 'Edit', 'Hariri')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (expense.id != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side:
                                const BorderSide(color: AppColors.dangerBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _confirmDelete(context,
                                context.read<PosLocalStore>(), expense);
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: Text(_dual(strings, 'Delete', 'Futa')),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
        title: Text(_dual(strings, 'Delete expense?', 'Futa matumizi?'),
            style: AppTypography.cardHeader),
        content: Text(
            _dual(
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
              child: Text(_dual(strings, 'Delete', 'Futa'))),
        ],
      ),
    );
    if (ok != true) return;
    await store.deleteExpense(expense.id!);
    if (!mounted) return;
    showMarketNotice(context,
        title: _dual(strings, 'Expense deleted', 'Matumizi yamefutwa'),
        message: _dual(strings, 'The expense record was removed.',
            'Rekodi ya matumizi imeondolewa.'));
  }
}

enum _ExpenseRange { today, thisWeek, thisMonth, lastMonth, all, custom }

extension on _ExpenseRange {
  String label(AppStrings strings) => switch (this) {
        _ExpenseRange.today => _dual(strings, 'Today', 'Leo'),
        _ExpenseRange.thisWeek => _dual(strings, 'This week', 'Wiki hii'),
        _ExpenseRange.thisMonth => _dual(strings, 'This month', 'Mwezi huu'),
        _ExpenseRange.lastMonth =>
          _dual(strings, 'Last month', 'Mwezi uliopita'),
        _ExpenseRange.all => _dual(strings, 'All time', 'Muda wote'),
        _ExpenseRange.custom =>
          _dual(strings, 'Custom range', 'Kipindi maalum'),
      };
}

/// Visual identity for an expense category.
class _CategoryStyle {
  const _CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const _known = <String, _CategoryStyle>{
    'Operations': _CategoryStyle(Icons.settings_outlined, AppColors.primary),
    'Inventory': _CategoryStyle(Icons.inventory_2_outlined, AppColors.toneTeal),
    'Rent': _CategoryStyle(Icons.home_work_outlined, AppColors.ink),
    'Utilities': _CategoryStyle(Icons.bolt_outlined, AppColors.warning),
    'Marketing': _CategoryStyle(Icons.campaign_outlined, AppColors.toneIndigo),
    'Transport':
        _CategoryStyle(Icons.local_shipping_outlined, AppColors.toneViolet),
    'Office':
        _CategoryStyle(Icons.business_center_outlined, AppColors.primaryDeep),
    'Supplies':
        _CategoryStyle(Icons.shopping_basket_outlined, AppColors.success),
    'Maintenance': _CategoryStyle(Icons.build_outlined, AppColors.textMuted),
  };

  static _CategoryStyle forName(String name) {
    return _known[name] ??
        const _CategoryStyle(Icons.receipt_long_outlined, AppColors.textMuted);
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.style, this.size = 40});

  final _CategoryStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.zero,
      ),
      child: Icon(style.icon, color: style.color, size: size * 0.5),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.strings});

  final ExpenseStatus status;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ExpenseStatus.draft => AppColors.textMuted,
      ExpenseStatus.submitted => AppColors.primary,
      ExpenseStatus.approved => AppColors.success,
      ExpenseStatus.reimbursed => AppColors.successDeep,
    };
    final bg = switch (status) {
      ExpenseStatus.draft => AppColors.surfaceSecondary,
      ExpenseStatus.submitted => AppColors.surfaceSecondary,
      ExpenseStatus.approved => AppColors.successLight,
      ExpenseStatus.reimbursed => AppColors.successLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.localized(strings.isSwahili),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(fontSize: 18, letterSpacing: -0.4),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxBanner extends StatelessWidget {
  const _TaxBanner({required this.amount, required this.strings});

  final double amount;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.percent_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _dual(strings, 'Tax / VAT collected', 'Kodi / VAT iliyokusanywa'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatMoney(amount),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.label,
    required this.sortLabel,
    required this.sortIcon,
    required this.onPickRange,
    required this.onCustomRange,
    required this.onPickSort,
    required this.strings,
  });

  final String label;
  final String sortLabel;
  final IconData sortIcon;
  final VoidCallback onPickRange;
  final VoidCallback onCustomRange;
  final VoidCallback onPickSort;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: AppColors.border,
      radius: 0,
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
            child: const Icon(Icons.date_range_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dual(strings, 'Period', 'Kipindi'),
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _dual(strings, 'Pick period', 'Chagua kipindi'),
            onPressed: onPickRange,
            icon: const Icon(Icons.tune_rounded,
                color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: _dual(strings, 'Custom range', 'Kipindi maalum'),
            onPressed: onCustomRange,
            icon: const Icon(Icons.event_rounded,
                color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _PaymentFilterRow extends StatelessWidget {
  const _PaymentFilterRow({
    required this.payments,
    required this.value,
    required this.onChanged,
    required this.strings,
  });

  final List<String> payments;
  final String value;
  final ValueChanged<String> onChanged;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final current = payments.contains(value) ? value : 'All';
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            _dual(strings, 'Payment', 'Malipo'),
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: current,
                isExpanded: true,
                isDense: true,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted, size: 20),
                items: payments
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p == 'All' ? _dual(strings, 'All', 'Zote') : p,
                            style: AppTypography.bodySmall,
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.items, required this.strings});

  final List<MapEntry<String, double>> items;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final grand = items.fold<double>(0, (s, e) => s + e.value);
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dual(strings, 'Payment breakdown', 'Mgawanyo wa malipo'),
            style: AppTypography.cardHeader,
          ),
          const SizedBox(height: 12),
          ...items.map((e) {
            final pct = grand <= 0 ? 0.0 : (e.value / grand);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatMoney(e.value, compact: true),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceHover,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.strings,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
  });

  final Expense expense;
  final AppStrings strings;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = _CategoryStyle.forName(expense.category);
    final fmt = DateFormat('MMM d, yyyy');
    final hasReceipt =
        expense.receiptPath != null && expense.receiptPath!.isNotEmpty;
    return MarketSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              _CategoryIcon(style: cat),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMain.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(status: expense.status, strings: strings),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Text(
                              expense.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cat.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${fmt.format(expense.date)} · ${expense.paymentMethod}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.helperText.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (expense.vendor.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 12, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              expense.vendor,
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
                    if (hasReceipt) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _dual(strings, 'Receipt attached',
                                'Risiti imeambatishwa'),
                            style: AppTypography.helperText.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if ((expense.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        expense.notes!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatMoney(expense.totalWithTax, compact: true),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (expense.taxAmount > 0)
                    Text(
                      _dual(strings, 'incl. tax', 'pamoja na kodi'),
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.textLight,
                        fontSize: 9.5,
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip:
                            _dual(strings, 'Edit expense', 'Hariri matumizi'),
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary, size: 18),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip:
                              _dual(strings, 'Delete expense', 'Futa matumizi'),
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.textLight, size: 18),
                        ),
                      ],
                    ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Text(value,
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings, required this.onAdd});

  final AppStrings strings;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(28),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.textMuted, size: 34),
          ),
          const SizedBox(height: 16),
          Text(_dual(strings, 'No expenses found', 'Hakuna matumizi'),
              style: AppTypography.cardHeader),
          const SizedBox(height: 6),
          Text(
            _dual(
                strings,
                'Record an expense or adjust the filters to see entries here.',
                'Rekodi matumizi au rekebisha vichujio kuona rekodi hapa.'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          MarketButton(
            label: _dual(strings, 'Add expense', 'Ongeza matumizi'),
            icon: Icons.add_rounded,
            isFullWidth: false,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _AddExpenseButton extends StatelessWidget {
  const _AddExpenseButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        splashColor: AppColors.primaryDeep.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
