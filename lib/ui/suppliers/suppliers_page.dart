import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'receiving_page.dart';
import 'supplier_detail_page.dart';
import 'supplier_form_page.dart';
import 'widgets/supplier_empty_state.dart';
import 'widgets/supplier_row.dart';

/// Supplier directory with payables, balances, and goods-received access.
class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final suppliers = store.suppliers;
    final filtered = _query.isEmpty
        ? suppliers
        : suppliers.where((s) {
            final q = _query.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.phone.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q) ||
                s.address.toLowerCase().contains(q);
          }).toList();

    final totalPayable = suppliers.fold<double>(
      0,
      (sum, s) => sum + store.supplierBalance(s.id ?? 0),
    );
    final owingCount =
        suppliers.where((s) => store.supplierBalance(s.id ?? 0) > 0).length;
    final totalReceived = store.receivings.fold<double>(
      0,
      (sum, r) => sum + r.total,
    );

    final body = ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        LayoutBuilder(
          builder: (context, metricConstraints) {
            final columns = metricConstraints.maxWidth >= 760 ? 4 : 2;
            final width =
                (metricConstraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: WorkspaceMetric(
                    label: t('Total payable', 'Jumla ya deni'),
                    value: _money(totalPayable),
                    icon: Icons.account_balance_wallet_outlined,
                    sharp: true,
                    borderless: true,
                    backgroundColor: const Color(0xFFFEE2E2),
                    color: const Color(0xFFB91C1C),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: WorkspaceMetric(
                    label: t('Suppliers count', 'Idadi ya wasambazaji'),
                    value: '${suppliers.length}',
                    icon: Icons.local_shipping_outlined,
                    sharp: true,
                    borderless: true,
                    backgroundColor: const Color(0xFFE0F2FE),
                    color: const Color(0xFF0369A1),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: WorkspaceMetric(
                    label: t('Owing suppliers', 'Wenye madeni'),
                    value: '$owingCount',
                    icon: Icons.warning_amber_rounded,
                    sharp: true,
                    borderless: true,
                    backgroundColor: const Color(0xFFFEF3C7),
                    color: const Color(0xFFB45309),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: WorkspaceMetric(
                    label: t('Received value', 'Thamani iliyopokelewa'),
                    value: _money(totalReceived),
                    icon: Icons.inventory_2_outlined,
                    sharp: true,
                    borderless: true,
                    backgroundColor: const Color(0xFFD1FAE5),
                    color: const Color(0xFF047857),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MarketButton(
                label: t('Add supplier', 'Ongeza msambazaji'),
                icon: Icons.add_rounded,
                onTap: () => _openForm(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MarketButton(
                label: t('Receive goods', 'Pokea bidhaa'),
                icon: Icons.move_to_inbox_rounded,
                isPrimary: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ReceivingPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MarketSearchField(
          controller: _searchController,
          hintText: t('Search by name, phone, email, address...',
              'Tafuta kwa jina, simu, barua pepe, anwani...'),
          onChanged: (value) => setState(() => _query = value.trim()),
          onClear: () {
            _searchController.clear();
            setState(() => _query = '');
          },
          radius: 0,
          showShadow: false,
          backgroundColor: AppColors.surface,
        ),
        const SizedBox(height: 12),
        if (suppliers.isEmpty)
          SupplierEmptyState(
            isSwahili: sw,
            isFiltered: false,
            onAddSupplier: () => _openForm(context),
          )
        else if (filtered.isEmpty)
          SupplierEmptyState(
            isSwahili: sw,
            isFiltered: true,
            onAddSupplier: () => _openForm(context),
            onClearFilter: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          )
          else
            WorkspaceRegister(
                columns: [
                  DataColumn(label: Text(t('Supplier', 'Msambazaji'))),
                  DataColumn(label: Text(t('Phone', 'Simu'))),
                  DataColumn(label: Text(t('Email', 'Barua pepe'))),
                  DataColumn(
                      label: Text(t('Balance payable', 'Deni')), numeric: true),
                  const DataColumn(label: Text(''))
                ],
                rows: filtered
                    .map((supplier) => DataRow(cells: [
                          DataCell(Text(supplier.name),
                              onTap: () => _openDetail(context, supplier)),
                          DataCell(Text(supplier.phone)),
                          DataCell(Text(supplier.email)),
                          DataCell(Text(
                              _money(store.supplierBalance(supplier.id ?? 0)))),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                                tooltip: t('Receive goods', 'Pokea bidhaa'),
                                onPressed: () => _receiveFor(context, supplier),
                                icon: const Icon(Icons.move_to_inbox_outlined,
                                    size: 20)),
                            IconButton(
                                tooltip: t('Open supplier', 'Fungua msambazaji'),
                                onPressed: () => _openDetail(context, supplier),
                                icon: const Icon(Icons.chevron_right_rounded)),
                          ])),
                        ]))
                    .toList(),
                mobile: MarketSurfaceCard(
                  radius: 0,
                  showShadow: false,
                  borderColor: AppColors.border,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < filtered.length; i++) ...[
                        SupplierRow(
                          supplier: filtered[i],
                          balance: store.supplierBalance(filtered[i].id ?? 0),
                          isSwahili: sw,
                          onTap: () => _openDetail(context, filtered[i]),
                          onReceive: () => _receiveFor(context, filtered[i]),
                        ),
                        if (i != filtered.length - 1)
                          const Divider(height: 1, color: AppColors.divider),
                      ],
                    ],
                  ),
                )),
        ],
      );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: t('Suppliers', 'Wasambazaji'),
                  subtitle: t('Purchases, payables, and goods received',
                      'Manunuzi, madeni, na bidhaa zilizopokelewa'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(child: body),
              ],
            ),
          )),
    );
  }

  void _openForm(BuildContext context, [Supplier? supplier]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SupplierFormPage(supplier: supplier),
      ),
    );
  }

  void _openDetail(BuildContext context, Supplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SupplierDetailPage(supplierId: supplier.id),
      ),
    );
  }

  void _receiveFor(BuildContext context, Supplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReceivingPage(presetSupplier: supplier),
      ),
    );
  }

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }
}

