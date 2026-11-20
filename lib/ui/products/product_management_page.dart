import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'add_product_page.dart';
import 'inventory_product_item.dart';
import 'widgets/product_cards.dart';
import 'widgets/product_csv_service.dart';
import 'widgets/product_filter_bar.dart';

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
      message: '${updated.name} has been updated',
      type: MarketNoticeType.success,
    );
  }

  Future<void> _deleteProduct(InventoryProductItem product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'Delete Item?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete ${product.name}? This will remove it from inventory.',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: const RoundedRectangleBorder(
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

  Future<void> _handleImportCsv() async {
    final store = context.read<PosLocalStore>();
    final count = await ProductCsvService.showImportCsvDialog(context, store);
    if (!mounted) return;
    if (count > 0) {
      showMarketNotice(
        context,
        title: 'Import Completed',
        message: 'Successfully added $count products into inventory.',
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
        child: Column(
          children: [
            if (!widget.useSharedShell) const ProductsHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final page = _page.clamp(
                      0,
                      filtered.isEmpty
                          ? 0
                          : (filtered.length - 1) ~/ _pageSize);
                  final rows =
                      filtered.skip(page * _pageSize).take(_pageSize).toList();
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(wide ? 24 : 16),
                        sliver: SliverList.list(
                          children: [
                            const WorkspaceHeading(
                              title: 'Inventory',
                              subtitle:
                                  'Manage your products, pricing and stock availability.',
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: FilledButton.icon(
                                      onPressed: _openAddProductPage,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.successDeep,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text(
                                        'Add item',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton.outlined(
                                  tooltip: 'Export CSV',
                                  style: OutlinedButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    side: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  onPressed: () =>
                                      ProductCsvService.exportInventoryCsv(
                                          filtered),
                                  icon: const Icon(Icons.download_rounded,
                                      color: AppColors.ink),
                                ),
                                const SizedBox(width: 6),
                                IconButton.outlined(
                                  tooltip: 'Import CSV',
                                  style: OutlinedButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    side: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  onPressed: _handleImportCsv,
                                  icon: const Icon(Icons.upload_file_rounded,
                                      color: AppColors.ink),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
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
                                        label: 'Total items',
                                        value: '${inventory.length}',
                                        icon: Icons.inventory_2_outlined,
                                        sharp: true,
                                        borderless: true,
                                        backgroundColor:
                                            const Color(0xFFFCE7F3),
                                        color: const Color(0xFFBE185D),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: WorkspaceMetric(
                                        label: 'Stock value',
                                        value: formatProductPrice(stockValue),
                                        icon: Icons
                                            .account_balance_wallet_outlined,
                                        sharp: true,
                                        borderless: true,
                                        backgroundColor:
                                            const Color(0xFFE0F2FE),
                                        color: const Color(0xFF0369A1),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: WorkspaceMetric(
                                        label: 'Low stock',
                                        value: '$lowCount',
                                        icon: Icons.trending_down_rounded,
                                        sharp: true,
                                        borderless: true,
                                        backgroundColor:
                                            const Color(0xFFFEF3C7),
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: WorkspaceMetric(
                                        label: 'Out of stock',
                                        value: '$outCount',
                                        icon: Icons.inventory_outlined,
                                        sharp: true,
                                        borderless: true,
                                        backgroundColor:
                                            const Color(0xFFFEE2E2),
                                        color: const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            ProductFilterBar(
                              searchController: _searchController,
                              categories: categories,
                              selectedCategory: _category,
                              selectedStockFilter: _stockFilter,
                              hasFilters: hasFilters,
                              onSearchChanged: (value) => setState(() {
                                _searchQuery = value;
                                _page = 0;
                              }),
                              onSearchClear: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _page = 0;
                              }),
                              onCategoryChanged: (value) => setState(() {
                                _category = value;
                                _page = 0;
                              }),
                              onStockFilterChanged: (value) => setState(() {
                                _stockFilter = value ?? 'all';
                                _page = 0;
                              }),
                              onResetFilters: _resetFilters,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${filtered.length} items',
                                    style: AppTypography.sectionHeader,
                                  ),
                                ),
                                if (!wide)
                                  PopupMenuButton<int>(
                                    tooltip: 'Sort inventory',
                                    onSelected: (value) => setState(() {
                                      _sortColumn = value;
                                      _page = 0;
                                    }),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 0,
                                          child: Text('Sort by name')),
                                      PopupMenuItem(
                                          value: 4,
                                          child: Text('Sort by stock')),
                                      PopupMenuItem(
                                          value: 3,
                                          child: Text('Sort by sale price')),
                                    ],
                                    icon: const Icon(Icons.sort_rounded),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (filtered.isEmpty)
                              WorkspacePanel(
                                child: ProductEmptyState(
                                  query: hasFilters ? 'filters' : '',
                                  onAddTap: _openAddProductPage,
                                  onClearFilter: _resetFilters,
                                ),
                              )
                            else if (wide)
                              WorkspacePanel(
                                padding: EdgeInsets.zero,
                                child: LayoutBuilder(
                                  builder: (context, tableConstraints) =>
                                      SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: tableConstraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        headingRowColor:
                                            const WidgetStatePropertyAll(
                                                AppColors.surfaceSecondary),
                                        headingTextStyle:
                                            AppTypography.tableHeader,
                                        dataTextStyle:
                                            AppTypography.bodySmall,
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
                                                _sortAscending = ascending;
                                                _page = 0;
                                              }),
                                            ),
                                          const DataColumn(
                                              label: Text('Status')),
                                          const DataColumn(
                                              label: Text('Actions')),
                                        ],
                                        rows: rows
                                            .map(
                                              (item) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                              maxWidth: 240),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item.name,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: AppTypography
                                                                .bodySmall
                                                                .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                          Text(item.code,
                                                              style:
                                                                  AppTypography
                                                                      .label),
                                                        ],
                                                      ),
                                                    ),
                                                    onTap: () =>
                                                        _editProduct(item),
                                                  ),
                                                  DataCell(
                                                      Text(item.category)),
                                                  DataCell(Text(
                                                      formatProductPrice(
                                                          item.purchasePrice))),
                                                  DataCell(Text(
                                                      formatProductPrice(
                                                          item.sellingPrice))),
                                                  DataCell(Text(
                                                      '${item.stockCount}')),
                                                  DataCell(
                                                    WorkspaceStatus(
                                                      label: _status(item),
                                                      color:
                                                          _statusColor(item),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          tooltip: 'Edit item',
                                                          onPressed: () =>
                                                              _editProduct(
                                                                  item),
                                                          icon: const Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              size: 19),
                                                        ),
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
                                                            size: 19,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...rows.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ProductItemRowCard(
                                    product: item,
                                    onTap: () => _editProduct(item),
                                    onDelete: () => _deleteProduct(item),
                                  ),
                                ),
                              ),
                            if (filtered.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${page * _pageSize + 1}–${page * _pageSize + rows.length} of ${filtered.length}',
                                        style: AppTypography.label,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Previous page',
                                      onPressed: page > 0
                                          ? () =>
                                              setState(() => _page = page - 1)
                                          : null,
                                      icon: const Icon(
                                          Icons.chevron_left_rounded),
                                    ),
                                    Text('${page + 1}',
                                        style: AppTypography.bodySmall),
                                    IconButton(
                                      tooltip: 'Next page',
                                      onPressed: (page + 1) * _pageSize <
                                              filtered.length
                                          ? () =>
                                              setState(() => _page = page + 1)
                                          : null,
                                      icon: const Icon(
                                          Icons.chevron_right_rounded),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 72),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
