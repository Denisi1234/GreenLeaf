import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_product_page.dart';
import '../models/product_item.dart';
import '../notifications/notifications_page.dart';
import 'inventory_product_item.dart';

String _formatPrice(double value) {
  return 'Sh ${formatCurrency(value)}';
}

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({
    super.key,
    this.useSharedShell = false,
  });

  final bool useSharedShell;

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _category;
  String _stockFilter = 'all';
  int _sortColumn = 0;
  bool _sortAscending = true;
  int _page = 0;
  static const _pageSize = 20;

  void _resetFilters() => setState(() {
        _searchController.clear();
        _searchQuery = '';
        _category = null;
        _stockFilter = 'all';
        _page = 0;
      });

  String _status(InventoryProductItem item) => item.stockCount <= 0
      ? 'Out of stock'
      : item.stockCount <= 5
          ? 'Low stock'
          : 'In stock';

  Color _statusColor(InventoryProductItem item) => item.stockCount <= 0
      ? AppColors.dangerDeep
      : item.stockCount <= 5
          ? AppColors.warningDeep
          : AppColors.successDeep;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddProductPage() async {
    final store = context.read<PosLocalStore>();
    final nextCode =
        'P${(store.inventory.length + 1).toString().padLeft(3, '0')}';
    final created = await Navigator.of(context).push<InventoryProductItem>(
      MaterialPageRoute<InventoryProductItem>(
        builder: (context) => AddProductPage(nextCode: nextCode),
      ),
    );

    if (created == null || !mounted) return;

    try {
      await store.addProduct(created);
    } catch (error) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Save Failed',
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
      return;
    }
    if (!mounted) return;
    showMarketNotice(
      context,
      title: 'Item Added',
      message: '${created.name} is now in your items list',
      type: MarketNoticeType.success,
    );
  }

  Future<void> _editProduct(InventoryProductItem product) async {
    final store = context.read<PosLocalStore>();
    final updated = await Navigator.of(context).push<InventoryProductItem>(
      MaterialPageRoute<InventoryProductItem>(
        builder: (context) => AddProductPage(
          nextCode: product.code,
          product: product,
        ),
      ),
    );

    if (updated == null || !mounted) return;

    try {
      await store.updateProduct(updated);
    } catch (error) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Update Failed',
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
      return;
    }
    if (!mounted) return;
    showMarketNotice(
      context,
      title: 'Item Updated',
      message: '${updated.name} was updated',
      type: MarketNoticeType.success,
    );
  }

  Future<void> _deleteProduct(InventoryProductItem product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'Delete Item?',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${product.name}"? This cannot be undone.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final store = context.read<PosLocalStore>();
    try {
      await store.removeProduct(product.code);
    } catch (error) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Delete Failed',
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
      return;
    }
    if (!mounted) return;
    showMarketNotice(
      context,
      title: 'Item Deleted',
      message: '${product.name} was deleted',
      type: MarketNoticeType.success,
    );
  }

  Future<void> _exportInventoryCsv(List<InventoryProductItem> items) async {
    final buffer = StringBuffer();
    buffer.writeln('Code,Name,Category,CostPrice,SalePrice,Quantity,Unit');
    for (final item in items) {
      buffer.writeln(
        '"${item.code}","${item.name.replaceAll('"', '""')}","${item.category}",${item.purchasePrice},${item.sellingPrice},${item.stockCount},"${item.unit}"',
      );
    }
    final fileName =
        'inventory_export_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(buffer.toString())),
            mimeType: 'text/csv',
          ),
        ],
        fileNameOverrides: [fileName],
      ),
    );
  }

  Future<void> _showImportCsvDialog() async {
    final textController = TextEditingController();
    final imported = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import CSV Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format: Name, Category, Cost, Price, Stock\n(One item per line)',
              style: AppTypography.label,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 7,
              decoration: const InputDecoration(
                hintText: 'Milk 1L, Dairy, 2000, 2500, 30\nBread, Bakery, 1500, 1800, 20',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.successDeep),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (imported == null || imported.isEmpty || !mounted) return;

    final store = context.read<PosLocalStore>();
    final lines = imported.split('\n');
    int addedCount = 0;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 4) {
        final name = parts[0];
        final category = parts[1];
        final cost = double.tryParse(parts[2]) ?? 0.0;
        final price = double.tryParse(parts[3]) ?? (cost * 1.25);
        final stock = parts.length >= 5 ? (int.tryParse(parts[4]) ?? 0) : 0;
        final nextCode = 'P${(store.inventory.length + addedCount + 1).toString().padLeft(3, '0')}';

        try {
          await store.addProduct(
            InventoryProductItem(
              code: nextCode,
              name: name,
              category: category.isNotEmpty ? category : 'General',
              purchasePrice: cost,
              sellingPrice: price,
              stockCount: stock,
              stockState: stock <= 0
                  ? InventoryStockState.outOfStock
                  : stock <= 5
                      ? InventoryStockState.lowStock
                      : InventoryStockState.inStock,
              artType: ProductArtType.aquafina,
              unit: 'Pcs',
            ),
          );
          addedCount++;
        } catch (_) {}
      }
    }

    if (mounted) {
      showMarketNotice(
        context,
        title: 'Import Completed',
        message: 'Successfully added $addedCount products into inventory.',
        type: MarketNoticeType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<PosLocalStore>().inventory;
    final categories = inventory.map((item) => item.category).toSet().toList()
      ..sort();
    final query = _searchQuery.trim().toLowerCase();
    final filtered = inventory.where((item) {
      final matchesQuery = query.isEmpty ||
          [
            item.name,
            item.code,
            item.category,
            ...item.categoryData.values.map((value) => value.toString())
          ].any((value) => value.toLowerCase().contains(query));
      final matchesStock = switch (_stockFilter) {
        'low' => item.stockCount > 0 && item.stockCount <= 5,
        'out' => item.stockCount <= 0,
        _ => true,
      };
      return matchesQuery &&
          matchesStock &&
          (_category == null || item.category == _category);
    }).toList();
    filtered.sort((a, b) {
      final comparison = switch (_sortColumn) {
        1 => a.category.compareTo(b.category),
        2 => a.purchasePrice.compareTo(b.purchasePrice),
        3 => a.sellingPrice.compareTo(b.sellingPrice),
        4 => a.stockCount.compareTo(b.stockCount),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return _sortAscending ? comparison : -comparison;
    });
    final lowCount = inventory
        .where((item) => item.stockCount > 0 && item.stockCount <= 5)
        .length;
    final outCount = inventory.where((item) => item.stockCount <= 0).length;
    final stockValue = inventory.fold<double>(
        0,
        (sum, item) =>
            sum + item.purchasePrice * item.stockCount.clamp(0, 1 << 31));
    final hasFilters =
        query.isNotEmpty || _category != null || _stockFilter != 'all';

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: widget.useSharedShell
          ? null
          : const MarketAppDrawer(selectedItem: 'Items'),
      body: SafeArea(
        top: !widget.useSharedShell,
        child: Column(children: [
          if (!widget.useSharedShell) const _ProductsHeader(),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final page = _page.clamp(
                0, filtered.isEmpty ? 0 : (filtered.length - 1) ~/ _pageSize);
            final rows =
                filtered.skip(page * _pageSize).take(_pageSize).toList();
            return CustomScrollView(slivers: [
              SliverPadding(
                padding: EdgeInsets.all(wide ? 24 : 16),
                sliver: SliverList.list(children: [
                  WorkspaceHeading(
                    title: 'Inventory',
                    subtitle:
                        'Manage your products, pricing and stock availability.',
                    action: FilledButton.icon(
                      onPressed: _openAddProductPage,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.successDeep),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add item'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(builder: (context, metricConstraints) {
                    final columns = metricConstraints.maxWidth >= 760 ? 4 : 2;
                    final width =
                        (metricConstraints.maxWidth - (columns - 1) * 12) /
                            columns;
                    return Wrap(spacing: 12, runSpacing: 12, children: [
                      SizedBox(
                          width: width,
                          child: WorkspaceMetric(
                              label: 'Total items',
                              value: '${inventory.length}',
                              icon: Icons.inventory_2_outlined)),
                      SizedBox(
                          width: width,
                          child: WorkspaceMetric(
                              label: 'Stock value',
                              value: _formatPrice(stockValue),
                              icon: Icons.account_balance_wallet_outlined)),
                      SizedBox(
                          width: width,
                          child: WorkspaceMetric(
                              label: 'Low stock',
                              value: '$lowCount',
                              icon: Icons.trending_down_rounded,
                              color: lowCount > 0
                                  ? AppColors.warningDeep
                                  : AppColors.textMuted)),
                      SizedBox(
                          width: width,
                          child: WorkspaceMetric(
                              label: 'Out of stock',
                              value: '$outCount',
                              icon: Icons.inventory_outlined,
                              color: outCount > 0
                                  ? AppColors.dangerDeep
                                  : AppColors.textMuted)),
                    ]);
                  }),
                  const SizedBox(height: 20),
                  WorkspacePanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarketSearchField(
                            controller: _searchController,
                            hintText: 'Search by name, code or barcode',
                            onChanged: (value) => setState(() {
                              _searchQuery = value;
                              _page = 0;
                            }),
                            onClear: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _page = 0;
                            }),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey('category-$_category'),
                                      initialValue:
                                          categories.contains(_category)
                                              ? _category
                                              : null,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Category'),
                                      items: [
                                        const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('All categories',
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        ...categories.map((category) =>
                                            DropdownMenuItem(
                                                value: category,
                                                child: Text(category,
                                                    overflow:
                                                        TextOverflow.ellipsis)))
                                      ],
                                      onChanged: (value) => setState(() {
                                        _category = value;
                                        _page = 0;
                                      }),
                                    )),
                                SizedBox(
                                    width: 180,
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey('stock-$_stockFilter'),
                                      isExpanded: true,
                                      initialValue: _stockFilter,
                                      decoration: const InputDecoration(
                                          labelText: 'Stock status'),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'all',
                                            child: Text('All stock',
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        DropdownMenuItem(
                                            value: 'low',
                                            child: Text('Low stock',
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        DropdownMenuItem(
                                            value: 'out',
                                            child: Text('Out of stock',
                                                overflow:
                                                    TextOverflow.ellipsis))
                                      ],
                                      onChanged: (value) => setState(() {
                                        _stockFilter = value ?? 'all';
                                        _page = 0;
                                      }),
                                    )),
                                if (hasFilters)
                                  TextButton.icon(
                                    onPressed: _resetFilters,
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.dangerDeep),
                                    icon: const Icon(
                                        Icons.filter_alt_off_outlined,
                                        size: 18),
                                    label: const Text('Clear filters'),
                                  ),
                              ]),
                        ]),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: Text('${filtered.length} items',
                            style: AppTypography.sectionHeader)),
                    if (!wide)
                      PopupMenuButton<int>(
                        tooltip: 'Sort inventory',
                        onSelected: (value) => setState(() {
                          _sortColumn = value;
                          _page = 0;
                        }),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 0, child: Text('Sort by name')),
                          PopupMenuItem(value: 4, child: Text('Sort by stock')),
                          PopupMenuItem(
                              value: 3, child: Text('Sort by sale price'))
                        ],
                        icon: const Icon(Icons.sort_rounded),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    WorkspacePanel(
                        child: _ItemsEmptyState(
                            query: hasFilters ? 'filters' : '',
                            onAddTap: _openAddProductPage,
                            onClearFilter: _resetFilters))
                  else if (wide)
                    WorkspacePanel(
                        padding: EdgeInsets.zero,
                        child: LayoutBuilder(
                            builder: (context, tableConstraints) =>
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minWidth: tableConstraints.maxWidth),
                                      child: DataTable(
                                        headingRowColor:
                                            const WidgetStatePropertyAll(
                                                AppColors.surfaceSecondary),
                                        headingTextStyle:
                                            AppTypography.tableHeader,
                                        dataTextStyle: AppTypography.bodySmall,
                                        horizontalMargin: 20,
                                        columnSpacing: 24,
                                        dataRowMinHeight: 64,
                                        dataRowMaxHeight: 72,
                                        sortColumnIndex: _sortColumn,
                                        sortAscending: _sortAscending,
                                        columns: [
                                          for (final entry in [
                                            'Item',
                                            'Category',
                                            'Cost price',
                                            'Sale price',
                                            'Quantity'
                                          ].asMap().entries)
                                            DataColumn(
                                                label: Text(entry.value),
                                                numeric: entry.key >= 2,
                                                onSort: (index, ascending) =>
                                                    setState(() {
                                                      _sortColumn = index;
                                                      _sortAscending =
                                                          ascending;
                                                      _page = 0;
                                                    })),
                                          const DataColumn(
                                              label: Text('Status')),
                                          const DataColumn(
                                              label: Text('Actions')),
                                        ],
                                        rows: rows
                                            .map((item) => DataRow(cells: [
                                                  DataCell(
                                                      ConstrainedBox(
                                                          constraints:
                                                              const BoxConstraints(
                                                                  maxWidth:
                                                                      240),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(item.name,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: AppTypography
                                                                      .bodySmall
                                                                      .copyWith(
                                                                          fontWeight:
                                                                              FontWeight.w700)),
                                                              Text(item.code,
                                                                  style:
                                                                      AppTypography
                                                                          .label)
                                                            ],
                                                          )),
                                                      onTap: () =>
                                                          _editProduct(item)),
                                                  DataCell(Text(item.category)),
                                                  DataCell(Text(_formatPrice(
                                                      item.purchasePrice))),
                                                  DataCell(Text(_formatPrice(
                                                      item.sellingPrice))),
                                                  DataCell(Text(
                                                      '${item.stockCount}')),
                                                  DataCell(WorkspaceStatus(
                                                      label: _status(item),
                                                      color:
                                                          _statusColor(item))),
                                                  DataCell(Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                            tooltip:
                                                                'Edit item',
                                                            onPressed: () =>
                                                                _editProduct(
                                                                    item),
                                                            icon: const Icon(
                                                                Icons
                                                                    .edit_outlined,
                                                                size: 19)),
                                                        IconButton(
                                                            tooltip:
                                                                'Delete item',
                                                            onPressed: () =>
                                                                _deleteProduct(
                                                                    item),
                                                            icon: const Icon(
                                                                Icons
                                                                    .delete_outline_rounded,
                                                                color: AppColors
                                                                    .dangerDeep,
                                                                size: 19)),
                                                      ])),
                                                ]))
                                            .toList(),
                                      )),
                                )))
                  else
                    ...rows.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ItemRowCard(
                          product: item,
                          onTap: () => _editProduct(item),
                          onDelete: () => _deleteProduct(item),
                        ))),
                  if (filtered.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        Expanded(
                            child: Text(
                                '${page * _pageSize + 1}–${page * _pageSize + rows.length} of ${filtered.length}',
                                style: AppTypography.label)),
                        IconButton(
                            tooltip: 'Previous page',
                            onPressed: page > 0
                                ? () => setState(() => _page = page - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded)),
                        Text('${page + 1}', style: AppTypography.bodySmall),
                        IconButton(
                            tooltip: 'Next page',
                            onPressed: (page + 1) * _pageSize < filtered.length
                                ? () => setState(() => _page = page + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded)),
                      ]),
                    ),
                  const SizedBox(height: 72),
                ]),
              ),
            ]);
          })),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item Row Card (Matches the reference screenshot)
// ---------------------------------------------------------------------------
class _ItemRowCard extends StatelessWidget {
  const _ItemRowCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  final InventoryProductItem product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stockCount <= 5 && product.stockCount > 0;
    final isOutOfStock = product.stockCount <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Item Name and Share / Action icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') onTap();
                        if (val == 'delete') onDelete();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined,
                                  size: 18, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text('Edit',
                                  style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrics row: Sale Price | Purchase Price | In Stock (exact layout from screenshot)
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sale Price',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatPrice(product.sellingPrice),
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase Price',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatPrice(product.purchasePrice),
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'In Stock',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            product.stockCount.toString(),
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isOutOfStock
                                  ? const Color(0xFFEF4444)
                                  : (isLowStock
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981)),
                            ),
                          ),
                        ],
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
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------
class _ItemsEmptyState extends StatelessWidget {
  const _ItemsEmptyState({
    required this.query,
    required this.onAddTap,
    required this.onClearFilter,
  });

  final String query;
  final VoidCallback onAddTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final hasFilter = query.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE2E8F0),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'No items match your search'
                : 'No items found in stock',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try searching with a different name or item code.'
                : 'Use Add item to register your first product.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          if (hasFilter)
            OutlinedButton(
              onPressed: onClearFilter,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerDeep,
                side: const BorderSide(color: AppColors.dangerBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                'Clear Search',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header (for standalone non-shared-shell usage)
// ---------------------------------------------------------------------------
class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader();

  @override
  Widget build(BuildContext context) {
    return MarketPageHeader(
      title: 'Items',
      showBackButton: false,
      centerTitle: false,
      showBorder: false,
      titleSize: 22,
      titleWeight: FontWeight.w800,
      actions: [
        MarketHeaderActionButtons(
          notificationBackground: const Color(0xFFF8FAFC),
          notificationBorderColor: const Color(0xFFE5EAF0),
          showNotificationDot: true,
          onNotificationTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
