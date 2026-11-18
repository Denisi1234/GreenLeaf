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
import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';
import '../widgets/market_shared_widgets.dart';
import 'create_customer_page.dart';
import 'debtors_page.dart';
import 'customer_details_page.dart';

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
  String _filter = _CustomerFilter.all.name;
  _SortMode _sort = _SortMode.newest;
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
            final stats = _buildStats(store);
            final all = List<CustomerData>.from(store.customers);

            final filtered = all.where((customer) {
              final info = stats[customer.name] ?? _CustomerStats.empty;
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
                0, (sum, c) => sum + (c.debitBalance > 0 ? c.debitBalance : 0));
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
                  actions: widget.isSelectionMode
                      ? null
                      : [
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
                      LayoutBuilder(
                        builder: (context, metricConstraints) {
                          final columns = metricConstraints.maxWidth >= 760 ? 4 : 2;
                          final width = (metricConstraints.maxWidth - (columns - 1) * 12) / columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: width,
                                child: WorkspaceMetric(
                                  label: _dual(strings, 'Total customers', 'Wateja wote'),
                                  value: '${all.length}',
                                  icon: Icons.people_alt_outlined,
                                  color: AppColors.ink,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: WorkspaceMetric(
                                  label: _dual(strings, 'Active buyers', 'Wanunuzi hai'),
                                  value: '${all.isEmpty ? 0 : withOrders}',
                                  icon: Icons.shopping_bag_outlined,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: WorkspaceMetric(
                                  label: _dual(strings, 'Lifetime sales', 'Jumla ya mauzo'),
                                  value: _formatMoney(lifetime, compact: true),
                                  icon: Icons.trending_up_rounded,
                                  color: AppColors.successDeep,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: WorkspaceMetric(
                                  label: _dual(strings, 'Outstanding debt', 'Madeni yote'),
                                  value: _formatMoney(outstanding, compact: true),
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: outstanding > 0 ? AppColors.dangerDeep : AppColors.textMuted,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (outstanding > 0) ...[
                        const SizedBox(height: 10),
                        _CreditBanner(
                          amount: outstanding,
                          count: store.debtorCount,
                          strings: strings,
                          onTap: _openDebtors,
                        ),
                      ],
                      const SizedBox(height: 12),
                      MarketSearchField(
                        controller: _searchController,
                        hintText:
                            _dual(strings, 'Search customers', 'Tafuta wateja'),
                        radius: 0,
                        showShadow: false,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      const SizedBox(height: 10),
                      _FilterRow(
                        value: _filter,
                        strings: strings,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                      const SizedBox(height: 10),
                      _SortCard(
                        sort: _sort,
                        strings: strings,
                        onPick: _pickSort,
                        activeFilters: _hasActiveFilter,
                        onClear: _clearFilters,
                      ),
                      const SizedBox(height: 18),
                      MarketSectionHeader(
                        title: _dual(
                            strings, 'Customer Directory', 'Orodha ya Wateja'),
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
                        _EmptyState(
                          strings: strings,
                          filtered: _hasActiveFilter,
                          onAdd: _openCreate,
                          onReset: _clearFilters,
                        )
                      else
                        ...filtered.map(
                          (customer) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CustomerCard(
                              customer: customer,
                              stats:
                                  stats[customer.name] ?? _CustomerStats.empty,
                              strings: strings,
                              onTap: () => _openCustomer(customer),
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
      floatingActionButton: widget.isSelectionMode
          ? null
          : Builder(
              builder: (context) {
                final strings =
                    AppStrings.of(context.watch<PosLocalStore>().languageCode);
                return _AddCustomerButton(
                  label: _dual(strings, 'Add Customer', 'Ongeza Mteja'),
                  onTap: _openCreate,
                );
              },
            ),
    );
  }

  bool get _hasActiveFilter =>
      _searchQuery.trim().isNotEmpty || _filter != _CustomerFilter.all.name;

  bool _matchesFilter(CustomerData customer, _CustomerStats info) {
    final filter = _filterFromName(_filter);
    switch (filter) {
      case _CustomerFilter.all:
        return true;
      case _CustomerFilter.vip:
        return customer.tags.contains('VIP');
      case _CustomerFilter.wholesale:
        return customer.tags.contains('Wholesale');
      case _CustomerFilter.debtors:
        return customer.debitBalance > 0;
      case _CustomerFilter.recent:
        return DateTime.now().difference(customer.createdAt).inDays <= 30;
    }
  }

  Map<String, _CustomerStats> _buildStats(PosLocalStore store) {
    final map = <String, _CustomerStats>{};
    for (final order in store.orders) {
      final name = order.customerName;
      if (name == null || name.trim().isEmpty) continue;
      final date = DateTime.tryParse(order.dateTime);
      final previous = map[name] ?? _CustomerStats.empty;
      map[name] = _CustomerStats(
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

  void _sortList(List<CustomerData> list, Map<String, _CustomerStats> stats) {
    double spentOf(CustomerData c) => stats[c.name]?.spent ?? c.totalSpent;
    int ordersOf(CustomerData c) =>
        (stats[c.name]?.orders ?? 0) + c.totalOrders;

    switch (_sort) {
      case _SortMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortMode.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortMode.name:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortMode.highestSpend:
        list.sort((a, b) => spentOf(b).compareTo(spentOf(a)));
        break;
      case _SortMode.mostOrders:
        list.sort((a, b) => ordersOf(b).compareTo(ordersOf(a)));
        break;
      case _SortMode.debtors:
        list.sort((a, b) => b.debitBalance.compareTo(a.debitBalance));
        break;
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filter = _CustomerFilter.all.name;
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
            Text(_dual(strings, 'Sort customers by', 'Panga wateja kwa'),
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
    if (picked == null || !mounted) return;
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
            Text(_dual(strings, 'Export customers', 'Hamisha wateja'),
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

  List<CustomerData> _visibleCustomers() {
    final store = context.read<PosLocalStore>();
    final stats = _buildStats(store);
    final filtered = store.customers.where((customer) {
      final info = stats[customer.name] ?? _CustomerStats.empty;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          customer.name.toLowerCase().contains(q) ||
          customer.phone.toLowerCase().contains(q) ||
          customer.email.toLowerCase().contains(q) ||
          customer.address.toLowerCase().contains(q);
      return matchesSearch && _matchesFilter(customer, info);
    }).toList();
    _sortList(filtered, stats);
    return filtered;
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    final store = context.read<PosLocalStore>();
    final stats = _buildStats(store);
    final rows = _visibleCustomers();
    final buffer = StringBuffer();
    buffer.writeln(
        'Name,Phone,Email,Address,Orders,Total Spent,Points,Outstanding Debit,Joined,Tags');
    for (final c in rows) {
      final info = stats[c.name] ?? _CustomerStats.empty;
      final cells = <String>[
        c.name,
        c.phone,
        c.email,
        c.address,
        '${info.orders + c.totalOrders}',
        (info.spent + c.totalSpent).toStringAsFixed(2),
        '${_loyaltyPoints(info.spent + c.totalSpent)}',
        c.debitBalance.toStringAsFixed(2),
        DateFormat('yyyy-MM-dd').format(c.createdAt),
        c.tags.join(' | '),
      ].map(_csvCell).join(',');
      buffer.writeln(cells);
    }
    await _shareBytes(
      Uint8List.fromList(utf8.encode(buffer.toString())),
      'customers_${_stamp()}.csv',
      'text/csv',
    );
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    final store = context.read<PosLocalStore>();
    final stats = _buildStats(store);
    final rows = _visibleCustomers();
    final totalSpent = rows.fold<double>(
        0, (sum, c) => sum + (stats[c.name]?.spent ?? c.totalSpent));
    final outstanding = rows.fold<double>(0, (sum, c) => sum + c.debitBalance);
    final doc = pw.Document();

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
              pw.Text('Customer Report',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                  '${rows.length} customers · Lifetime sales ${_formatMoney(totalSpent)} · Outstanding ${_formatMoney(outstanding)}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Name',
              'Phone',
              'Orders',
              'Total Spent',
              'Points',
              'Debit',
              'Joined'
            ],
            data: rows.map((c) {
              final info = stats[c.name] ?? _CustomerStats.empty;
              final spent = info.spent + c.totalSpent;
              return [
                c.name,
                c.phone,
                '${info.orders + c.totalOrders}',
                _formatMoney(spent),
                '${_loyaltyPoints(spent)}',
                c.debitBalance > 0 ? _formatMoney(c.debitBalance) : '—',
                DateFormat('yyyy-MM-dd').format(c.createdAt),
              ];
            }).toList(),
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
        bytes: await doc.save(), filename: 'customers_${_stamp()}.pdf');
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

  static int _loyaltyPoints(double spent) => (spent / 1000).round();
}

enum _SortMode { newest, oldest, name, highestSpend, mostOrders, debtors }

extension on _SortMode {
  String label(AppStrings strings) => switch (this) {
        _SortMode.newest => _dual(strings, 'Newest first', 'Mpya kwanza'),
        _SortMode.oldest => _dual(strings, 'Oldest first', 'Zamani kwanza'),
        _SortMode.name => _dual(strings, 'Name (A-Z)', 'Jina (A-Z)'),
        _SortMode.highestSpend =>
          _dual(strings, 'Highest spend', 'Matumizi makubwa'),
        _SortMode.mostOrders => _dual(strings, 'Most orders', 'Oda nyingi'),
        _SortMode.debtors => _dual(strings, 'Debt balance', 'Madeni'),
      };

  IconData get icon => switch (this) {
        _SortMode.newest => Icons.schedule_rounded,
        _SortMode.oldest => Icons.history_rounded,
        _SortMode.name => Icons.sort_by_alpha_rounded,
        _SortMode.highestSpend => Icons.trending_up_rounded,
        _SortMode.mostOrders => Icons.receipt_long_rounded,
        _SortMode.debtors => Icons.account_balance_wallet_outlined,
      };
}

enum _CustomerFilter { all, vip, wholesale, debtors, recent }

_CustomerFilter _filterFromName(String value) {
  for (final filter in _CustomerFilter.values) {
    if (filter.name == value) return filter;
  }
  return _CustomerFilter.all;
}

extension on _CustomerFilter {
  String get name => switch (this) {
        _CustomerFilter.all => 'all',
        _CustomerFilter.vip => 'vip',
        _CustomerFilter.wholesale => 'wholesale',
        _CustomerFilter.debtors => 'debtors',
        _CustomerFilter.recent => 'new',
      };

  String label(AppStrings strings) => switch (this) {
        _CustomerFilter.all => _dual(strings, 'All', 'Zote'),
        _CustomerFilter.vip => 'VIP',
        _CustomerFilter.wholesale => _dual(strings, 'Wholesale', 'Jumla'),
        _CustomerFilter.debtors => _dual(strings, 'Debtors', 'Wadaiwa'),
        _CustomerFilter.recent =>
          _dual(strings, 'New (30d)', 'Wapya (siku 30)'),
      };
}

class _CustomerStats {
  const _CustomerStats({
    required this.orders,
    required this.spent,
    required this.lastOrder,
  });

  static const empty = _CustomerStats(orders: 0, spent: 0, lastOrder: null);

  final int orders;
  final double spent;
  final DateTime? lastOrder;
}

enum _LoyaltyTier { none, bronze, silver, gold, platinum }

_LoyaltyTier _tierForSpend(double spent) {
  if (spent >= 2000000) return _LoyaltyTier.platinum;
  if (spent >= 750000) return _LoyaltyTier.gold;
  if (spent >= 250000) return _LoyaltyTier.silver;
  if (spent > 0) return _LoyaltyTier.bronze;
  return _LoyaltyTier.none;
}

extension on _LoyaltyTier {
  String label(AppStrings strings) => switch (this) {
        _LoyaltyTier.none => _dual(strings, 'New', 'Mpya'),
        _LoyaltyTier.bronze => 'Bronze',
        _LoyaltyTier.silver => 'Silver',
        _LoyaltyTier.gold => 'Gold',
        _LoyaltyTier.platinum => 'Platinum',
      };

  Color get color => switch (this) {
        _LoyaltyTier.none => AppColors.textMuted,
        _LoyaltyTier.bronze => AppColors.warningDeep,
        _LoyaltyTier.silver => AppColors.textBody,
        _LoyaltyTier.gold => AppColors.warning,
        _LoyaltyTier.platinum => AppColors.primaryDeep,
      };

  Color get background => switch (this) {
        _LoyaltyTier.none => AppColors.surfaceSecondary,
        _LoyaltyTier.bronze => AppColors.warningLight,
        _LoyaltyTier.silver => AppColors.surfaceHover,
        _LoyaltyTier.gold => AppColors.warningLight,
        _LoyaltyTier.platinum => AppColors.surfaceSecondary,
      };
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

class _CreditBanner extends StatelessWidget {
  const _CreditBanner({
    required this.amount,
    required this.count,
    required this.strings,
    required this.onTap,
  });

  final double amount;
  final int count;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerLight,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dual(strings, 'Outstanding customer credit',
                          'Madeni ya wateja'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dual(
                        strings,
                        '$count customer${count == 1 ? '' : 's'} · tap to open the ledger',
                        'wateja $count · gusa kufungua daftari',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.danger,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatMoney(amount),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.danger, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.value,
    required this.strings,
    required this.onChanged,
  });

  final String value;
  final AppStrings strings;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = _CustomerFilter.values;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.name == value;
          return GestureDetector(
            onTap: () => onChanged(filter.name),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                filter.label(strings),
                style: AppTypography.helperText.copyWith(
                  color: selected ? Colors.white : AppColors.textBody,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SortCard extends StatelessWidget {
  const _SortCard({
    required this.sort,
    required this.strings,
    required this.onPick,
    required this.activeFilters,
    required this.onClear,
  });

  final _SortMode sort;
  final AppStrings strings;
  final VoidCallback onPick;
  final bool activeFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Icon(sort.icon, color: AppColors.primary, size: 18),
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
              ],
            ),
          ),
          if (activeFilters)
            IconButton(
              tooltip: _dual(strings, 'Clear filters', 'Ondoa vichujio'),
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_rounded,
                  color: AppColors.textMuted, size: 20),
              visualDensity: VisualDensity.compact,
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.stats,
    required this.strings,
    required this.onTap,
  });

  final CustomerData customer;
  final _CustomerStats stats;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spent = stats.spent + customer.totalSpent;
    final orders = stats.orders + customer.totalOrders;
    final points = (spent / 1000).round();
    final tier = _tierForSpend(spent);
    final hasDebt = customer.debitBalance > 0;

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
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  customer.initials,
                  style: AppTypography.cardHeader.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMain.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tier.background,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            tier.label(strings),
                            style: TextStyle(
                              color: tier.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MetricChip(
                          icon: Icons.receipt_long_rounded,
                          label: _dual(strings, 'orders', 'oda'),
                          value: '$orders',
                          color: AppColors.textBody,
                        ),
                        const SizedBox(width: 6),
                        _MetricChip(
                          icon: Icons.payments_outlined,
                          label: _dual(strings, 'spent', 'matumizi'),
                          value: _formatMoney(spent, compact: true),
                          color: AppColors.textBody,
                        ),
                        if (hasDebt) ...[
                          const SizedBox(width: 6),
                          _MetricChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: _dual(strings, 'due', 'deni'),
                            value: _formatMoney(customer.debitBalance,
                                compact: true),
                            color: AppColors.ink,
                          ),
                        ],
                      ],
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
                    '$points',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    _dual(strings, 'POINTS', 'ALAMA'),
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textLight, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: const BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '$value $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.strings,
    required this.filtered,
    required this.onAdd,
    required this.onReset,
  });

  final AppStrings strings;
  final bool filtered;
  final VoidCallback onAdd;
  final VoidCallback onReset;

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
            child: Icon(
              filtered
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            filtered
                ? _dual(strings, 'No matching customers', 'Hakuna wateja')
                : _dual(strings, 'No customers yet', 'Hakuna wateja bado'),
            style: AppTypography.cardHeader,
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? _dual(
                    strings,
                    'Try a different name, phone or filter to see customers.',
                    'Jaribu jina, simu au kichujio kingine kuona wateja.')
                : _dual(
                    strings,
                    'Add your first customer to start tracking sales and credit.',
                    'Ongeza mteja wako wa kwanza kufuatilia mauzo na mkopo.'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (filtered)
            MarketButton(
              label: _dual(strings, 'Clear filters', 'Ondoa vichujio'),
              icon: Icons.filter_alt_off_rounded,
              isFullWidth: false,
              onTap: onReset,
            )
          else
            MarketButton(
              label: _dual(strings, 'Add customer', 'Ongeza mteja'),
              icon: Icons.add_rounded,
              isFullWidth: false,
              onTap: onAdd,
            ),
        ],
      ),
    );
  }
}

class _AddCustomerButton extends StatelessWidget {
  const _AddCustomerButton({required this.label, required this.onTap});

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
              const Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.white, size: 18),
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
