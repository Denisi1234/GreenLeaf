import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/barcode_scan_service.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/quantity_formatter.dart';
import '../widgets/app_design.dart';
import 'widgets/order_history_card.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key, this.useSharedShell = false});

  final bool useSharedShell;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _filterOption = 'all';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _scanOrderBarcode() async {
    final scanned = await BarcodeScanService.instance.scan(context);
    if (scanned == null || !mounted) return;
    setState(() {
      _searchController.text = scanned;
      _searchQuery = scanned;
    });
  }

  Future<void> _pickFilter() async {
    final options = <String>[
      'all',
      'Completed',
      'Voided',
      'Cash',
      'Card',
      'Mobile Money',
      'Credit',
    ];
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                context.tr('Filter orders'),
                style: AppTypography.sectionHeader,
              ),
            ),
            for (final option in options)
              ListTile(
                leading: Icon(
                  _filterOption == option
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: _filterOption == option
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(
                  option == 'all'
                      ? context.tr('All orders')
                      : context.tr(option),
                ),
                onTap: () => Navigator.of(sheetCtx).pop(option),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _filterOption = chosen);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = await Navigator.of(context).push<DateTime?>(
      MaterialPageRoute<DateTime?>(
        builder: (pageCtx) => Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              context.tr('Select date'),
              style: AppTypography.cardHeader.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              if (_selectedDate != null)
                TextButton(
                  onPressed: () =>
                      Navigator.of(pageCtx).pop(DateTime(1970, 1, 1)),
                  child: Text(
                    context.tr('Clear'),
                    style: TextStyle(
                      color: AppColors.dangerDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.divider),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SharpFilterCard(
                            label: context.tr('Today'),
                            icon: Icons.today_rounded,
                            active: _selectedDate != null &&
                                _selectedDate!.year == today.year &&
                                _selectedDate!.month == today.month &&
                                _selectedDate!.day == today.day,
                            onTap: () => Navigator.of(pageCtx).pop(today),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SharpFilterCard(
                            label: context.tr('Yesterday'),
                            icon: Icons.history_rounded,
                            active: false,
                            onTap: () => Navigator.of(pageCtx)
                                .pop(today.subtract(const Duration(days: 1))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.zero,
                    child: CalendarDatePicker(
                      initialDate: _selectedDate ?? today,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 1),
                      onDateChanged: (picked) =>
                          Navigator.of(pageCtx).pop(picked),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedDate = result.year == 1970 ? null : result;
    });
  }

  OrderHistoryItem _toItem(CompletedOrder o) {
    final lower = o.status.trim().toLowerCase();
    final isReversed =
        lower == 'voided' || lower == 'returned' || lower == 'cancelled';
    return OrderHistoryItem(
      id: '#${o.id}',
      dateTime: '${o.date} • ${o.time}',
      amount: 'TSH ${o.total.toStringAsFixed(0)}',
      status: o.status,
      statusColor:
          isReversed ? AppColors.dangerDeep : AppColors.successDeep,
      statusBg: isReversed ? AppColors.dangerLight : AppColors.successLight,
      accentColor: isReversed ? AppColors.danger : AppColors.primary,
      completedOrder: o,
      customerName: o.cashierName,
      customerPhone: '',
      paymentMethod: o.paymentMethod,
      paidAmount: 'TSH ${o.cashTendered.toStringAsFixed(0)}',
      isExpanded: false,
      lines: o.lines
          .map(
            (l) => OrderHistoryLine(
              l.itemName,
              l.unit.toLowerCase() == 'pcs'
                  ? 'x${formatQuantity(l.quantity)}'
                  : formatQtyForReceipt(l.quantity, l.unit),
              'TSH ${l.unitPriceValue.toStringAsFixed(0)}',
              'TSH ${l.lineTotal.toStringAsFixed(0)}',
            ),
          )
          .toList(),
      subtotal: 'TSH ${o.total.toStringAsFixed(0)}',
      tax: 'TSH 0',
      total: 'TSH ${o.total.toStringAsFixed(0)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawOrders = context.watch<PosLocalStore>().orders;
    final query = _searchQuery.trim().toLowerCase();
    final filteredOrders = rawOrders
        .where((o) {
          if (_selectedDate != null) {
            final parsed = DateTime.tryParse(o.dateTime);
            if (parsed == null ||
                parsed.year != _selectedDate!.year ||
                parsed.month != _selectedDate!.month ||
                parsed.day != _selectedDate!.day) {
              return false;
            }
          }
          if (_filterOption != 'all') {
            final matchesStatus =
                o.status.toLowerCase() == _filterOption.toLowerCase();
            final matchesPayment = o.paymentMethod
                .toLowerCase()
                .contains(_filterOption.toLowerCase());
            if (!matchesStatus && !matchesPayment) return false;
          }
          if (query.isEmpty) return true;
          final searchableValues = <String>[
            '#${o.id}',
            o.id,
            '${o.date} ${o.time}',
            o.total.toStringAsFixed(0),
            o.status,
            o.cashierName,
            o.customerName ?? '',
            o.paymentMethod,
          ];
          return searchableValues.any(
            (value) => value.toLowerCase().contains(query),
          );
        })
        .map(_toItem)
        .toList();
    final completedTotal = filteredOrders
        .where((o) {
          final s = o.status.trim().toLowerCase();
          return s != 'voided' && s != 'returned' && s != 'cancelled';
        })
        .fold<double>(0.0, (sum, o) => sum + (o.completedOrder?.total ?? 0.0));
    final completedCount = filteredOrders.where((o) {
      final s = o.status.trim().toLowerCase();
      return s != 'voided' && s != 'returned' && s != 'cancelled';
    }).length;
    final voidedCount = filteredOrders.where((o) {
      final s = o.status.trim().toLowerCase();
      return s == 'voided' || s == 'returned' || s == 'cancelled';
    }).length;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: widget.useSharedShell
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                context.tr('Orders & receipts'),
                style: AppTypography.cardHeader.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink,
              elevation: 0,
              scrolledUnderElevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: AppColors.divider),
              ),
            ),
      body: SafeArea(
        top: !widget.useSharedShell,
        child: Column(
          children: [
            // Full-width sharp borderless ERP search & filter bar
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    textInputAction: TextInputAction.search,
                    style: AppTypography.bodyMain,
                    decoration: InputDecoration(
                      hintText: context.tr(
                        'Search by ID, cashier, customer or payment...',
                      ),
                      hintStyle: AppTypography.label,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          IconButton(
                            tooltip: context.tr('Scan receipt barcode'),
                            icon: Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 19,
                              color: AppColors.ink,
                            ),
                            onPressed: _scanOrderBarcode,
                          ),
                        ],
                      ),
                      filled: true,
                      fillColor: AppColors.pageBackground,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: AppCorners.input,
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: AppCorners.input,
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppCorners.input,
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SharpFilterCard(
                          label: _filterOption == 'all'
                              ? context.tr('Filter: All')
                              : context.tr(_filterOption),
                          icon: Icons.filter_alt_outlined,
                          active: _filterOption != 'all',
                          onTap: _pickFilter,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SharpFilterCard(
                          label: _selectedDate == null
                              ? context.tr('All dates')
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          icon: Icons.calendar_today_outlined,
                          active: _selectedDate != null,
                          onTap: _pickDate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
            // Sharp ERP KPI summary strip
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    color: AppColors.kpiSkyBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('SALES TOTAL').toUpperCase(),
                          style: AppTypography.label.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kpiSky,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TSh ${formatCurrency(completedTotal)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMain.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.kpiSky,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.kpiSuccessBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('ORDERS').toUpperCase(),
                          style: AppTypography.label.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kpiSuccess,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completedCount',
                          style: AppTypography.bodyMain.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.kpiSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.kpiDangerBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('VOIDED').toUpperCase(),
                          style: AppTypography.label.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kpiDanger,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$voidedCount',
                          style: AppTypography.bodyMain.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.kpiDanger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.textMuted,
                              size: 36,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr('No matching orders'),
                              style: AppTypography.bodyMain.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          OrderCard(order: filteredOrders[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharpFilterCard extends StatelessWidget {
  const _SharpFilterCard({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.kpiSkyBg : AppColors.pageBackground;
    final fg = active ? AppColors.kpiSky : AppColors.ink;
    return Material(
      color: bg,
      borderRadius: AppCorners.control,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppCorners.control,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

