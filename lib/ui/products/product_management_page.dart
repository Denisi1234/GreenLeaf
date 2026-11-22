import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../utils/quantity_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'add_product_page.dart';
import 'inventory_product_item.dart';
import 'widgets/product_cards.dart';
import 'widgets/inventory_kpi_metrics.dart';
import 'widgets/inventory_data_table.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddProductPage() async {
    final store = context.read<PosLocalStore>();
    if (!store.hasPermission('Manage Inventory')) {
      showMarketNotice(
        context,
        title: context.tr('Permission Required'),
        message: context.tr('You do not have permission to manage inventory.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
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
        title: context.tr('Save Failed'),
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
      return;
    }
    if (!mounted) return;
    showMarketNotice(
      context,
      title: context.tr('Item Added'),
      message: context.tr('{p0} is now in your items list', args: {'p0': created.name}),
      type: MarketNoticeType.success,
    );
  }

  Future<void> _editProduct(InventoryProductItem product) async {
    final store = context.read<PosLocalStore>();
    if (!store.hasPermission('Manage Inventory')) {
      showMarketNotice(
        context,
        title: context.tr('Permission Required'),
        message: context.tr('You do not have permission to manage inventory.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
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
        title: context.tr('Update Failed'),
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
      return;
    }
    if (!mounted) return;
    showMarketNotice(
      context,
      title: context.tr('Item Updated'),
      message: context.tr('{p0} has been updated', args: {'p0': updated.name}),
      type: MarketNoticeType.success,
    );
  }

  Future<void> _deleteProduct(InventoryProductItem product) async {
    final store = context.read<PosLocalStore>();
    if (!store.hasPermission('Manage Inventory')) {
      showMarketNotice(
        context,
        title: context.tr('Permission Required'),
        message: context.tr('You do not have permission to manage inventory.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    final shouldDelete = await showMarketConfirmDialog(
      context,
      title: context.tr('Delete Item?'),
      message: context.tr(
        'Are you sure you want to delete {p0}? This will remove it from inventory.',
        args: {'p0': product.name},
      ),
      confirmLabel: context.tr('Delete'),
      cancelLabel: context.tr('Cancel'),
      isDestructive: true,
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await store.removeProduct(product.code);
    } catch (error) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: context.tr('Delete Failed'),
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
      return;
    }
    if (!mounted) return;
    showMarketNotice(
      context,
      title: context.tr('Item Deleted'),
      message: context.tr('{p0} was deleted', args: {'p0': product.name}),
      type: MarketNoticeType.success,
    );
  }

  Future<void> _handleImportCsv() async {
    final store = context.read<PosLocalStore>();
    if (!store.hasPermission('Manage Inventory')) {
      showMarketNotice(
        context,
        title: context.tr('Permission Required'),
        message: context.tr('You do not have permission to manage inventory.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    final count = await ProductCsvService.showImportCsvDialog(context, store);
    if (!mounted) return;
    if (count > 0) {
      showMarketNotice(
        context,
        title: context.tr('Import Completed'),
        message: context.tr('Successfully added {p0} products into inventory.', args: {'p0': count}),
        type: MarketNoticeType.success,
      );
    }
  }

  Future<void> _adjustStock(InventoryProductItem product) async {
    final store = context.read<PosLocalStore>();
    if (!store.hasPermission('Manage Inventory')) {
      showMarketNotice(
        context,
        title: context.tr('Permission Required'),
        message: context.tr('You do not have permission to manage inventory.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    final sw = context.strings.isSwahili;
    String t(String en, String swText) => sw ? swText : en;
    final ctrl = TextEditingController(text: formatQuantity(product.stockCount));
    final result = await showDialog<double>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title: Text(
          '${t('Adjust stock', 'Rekebisha stoo')}: ${product.name}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${t('Current stock', 'Stoo ya sasa')}: ${formatStockWithUnit(product.stockCount, product.unit)}',
              style: AppTypography.label,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('adjust-stock-input'),
              controller: ctrl,
              keyboardType: product.allowFractional
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              decoration: InputDecoration(
                labelText: t('New stock quantity', 'Idadi mpya stoo'),
                suffixText: product.unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (product.hasBulkPack)
                  OutlinedButton.icon(
                    onPressed: () {
                      final current = double.tryParse(
                            ctrl.text.trim().replaceAll(',', ''),
                          ) ??
                          product.stockCount;
                      ctrl.text = formatQuantity(
                        roundQuantity(current + product.packSize!),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDeep,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.standard),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text(
                      '+1 ${product.packName} (+${formatQuantity(product.packSize!)} ${product.unit})',
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => ctrl.text = '0',
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerDeep,
                    side: const BorderSide(color: AppColors.dangerBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.standard),
                    ),
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                  label: Text(
                    t(
                      'Mark empty (0 ${product.unit})',
                      'Fanya 0 ${product.unit} (imeisha)',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final parsed =
                  double.tryParse(ctrl.text.trim().replaceAll(',', ''));
              if (parsed == null || parsed < 0) return;
              Navigator.of(dialogCtx).pop(roundQuantity(parsed));
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(t('Save', 'Hifadhi')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || !mounted) return;
    final threshold = store.storePreferences.lowStockThreshold;
    final nextState = result <= 0
        ? InventoryStockState.outOfStock
        : result <= threshold
            ? InventoryStockState.lowStock
            : InventoryStockState.inStock;
    await store.updateProduct(
      product.copyWith(stockCount: result, stockState: nextState),
    );
    if (!mounted) return;
    showMarketNotice(
      context,
      title: t('Stock updated', 'Stoo imesasishwa'),
      message: '${product.name}: ${formatStockWithUnit(result, product.unit)}',
      type: MarketNoticeType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final inventory = store.inventory;
    final lowThreshold = store.storePreferences.lowStockThreshold;
    final canManageInventory = store.hasPermission('Manage Inventory');
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
        'low' => item.stockCount > 0 && item.stockCount <= lowThreshold,
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
        .where((item) => item.stockCount > 0 && item.stockCount <= lowThreshold)
        .length;
    final outCount = inventory.where((item) => item.stockCount <= 0).length;
    final stockValue = inventory.fold<double>(
        0,
        (sum, item) =>
            sum + item.purchasePrice * item.stockCount.clamp(0.0, 1e12));
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
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 24 : 14,
                          wide ? 20 : 14,
                          wide ? 24 : 14,
                          30,
                        ),
                        sliver: SliverList.list(
                          children: [
                            if (!widget.useSharedShell) ...[
                              WorkspaceHeading(
                                title: context.tr('Inventory'),
                                subtitle: context.tr(
                                  'Manage your products, pricing and stock availability.',
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (canManageInventory) ...[
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: FilledButton.icon(
                                        onPressed: _openAddProductPage,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add_rounded),
                                        label: Text(
                                          context.tr('Add item'),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: IconButton.outlined(
                                      tooltip: context.tr('Export CSV'),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: AppColors.kpiSkyBg,
                                        padding: EdgeInsets.zero,
                                        shape: const CircleBorder(),
                                        side: BorderSide.none,
                                      ),
                                      onPressed: () =>
                                          ProductCsvService.exportInventoryCsv(
                                              filtered),
                                      icon: Icon(Icons.download_rounded,
                                          color: AppColors.kpiSky),
                                    ),
                                  ),
                                  if (canManageInventory) ...[
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: IconButton.outlined(
                                        tooltip: context.tr('Import CSV'),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColors.kpiVioletBg,
                                          padding: EdgeInsets.zero,
                                          shape: const CircleBorder(),
                                          side: BorderSide.none,
                                        ),
                                        onPressed: _handleImportCsv,
                                        icon: Icon(Icons.upload_file_rounded,
                                            color: AppColors.kpiViolet),
                                      ),
                                    ),
                                  ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            InventoryKpiMetrics(
                              totalItems: inventory.length,
                              stockValue: stockValue,
                              lowCount: lowCount,
                              outCount: outCount,
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    context.tr('{p0} items', args: {'p0': filtered.length}),
                                    style: AppTypography.sectionHeader,
                                  ),
                                ),
                                if (!wide)
                                  PopupMenuButton<int>(
                                    tooltip: context.tr('Sort inventory'),
                                    onSelected: (value) => setState(() {
                                      _sortColumn = value;
                                      _page = 0;
                                    }),
                                    itemBuilder: (_) =>  [
                                      PopupMenuItem(
                                          value: 0,
                                          child: Text(context.tr('Sort by name'))),
                                      PopupMenuItem(
                                          value: 4,
                                          child: Text(context.tr('Sort by stock'))),
                                      PopupMenuItem(
                                          value: 3,
                                          child: Text(context.tr('Sort by sale price'))),
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
                                  onAddTap: canManageInventory
                                      ? _openAddProductPage
                                      : null,
                                  onClearFilter: _resetFilters,
                                ),
                              )
                            else if (wide)
                              InventoryDataTable(
                                items: rows,
                                sortColumn: _sortColumn,
                                sortAscending: _sortAscending,
                                onSort: (index, ascending) => setState(() {
                                  _sortColumn = index;
                                  _sortAscending = ascending;
                                  _page = 0;
                                }),
                                onEdit:
                                    canManageInventory ? _editProduct : null,
                                onAdjustStock:
                                    canManageInventory ? _adjustStock : null,
                                onDelete:
                                    canManageInventory ? _deleteProduct : null,
                              )
                            else
                              ...rows.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ProductItemRowCard(
                                    product: item,
                                    lowStockThreshold: lowThreshold,
                                    onTap: canManageInventory
                                        ? () => _editProduct(item)
                                        : null,
                                    onAdjustStock: canManageInventory
                                        ? () => _adjustStock(item)
                                        : null,
                                    onDelete: canManageInventory
                                        ? () => _deleteProduct(item)
                                        : null,
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
                                        context.tr('{p0}–{p1} of {p2}', args: {'p0': page * _pageSize + 1, 'p1': page * _pageSize + rows.length, 'p2': filtered.length}),
                                        style: AppTypography.label,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: context.tr('Previous page'),
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
                                      tooltip: context.tr('Next page'),
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
