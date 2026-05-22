import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../models/product_item.dart';
import '../home/home_page.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_product_page.dart';
import 'inventory_product_item.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _InventoryFilter _selectedFilter = _InventoryFilter.all;
  String? _successMessage;
  ProductArtType? _lastAddedType;
  String? _lastAddedImagePath;

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

    store.addProduct(created);
    showMarketNotice(
      context,
      title: 'Product Added',
      message: '${created.name} is now in your items list',
    );
  }

  Future<void> _editProduct(InventoryProductItem product) async {
    final updated = await Navigator.of(context).push<InventoryProductItem>(
      MaterialPageRoute<InventoryProductItem>(
        builder: (context) => AddProductPage(
          nextCode: product.code,
          product: product,
        ),
      ),
    );

    if (updated == null || !mounted) return;

    context.read<PosLocalStore>().updateProduct(updated);
    showMarketNotice(
      context,
      title: 'Product Updated',
      message: '${updated.name} has been updated successfully',
    );
  }

  void _deleteProduct(InventoryProductItem product) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PosLocalStore>().removeProduct(product.code);
              showMarketNotice(
                context,
                title: 'Product Deleted',
                message: '${product.name} has been removed',
                type: MarketNoticeType.warning,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final query = _searchQuery.trim().toLowerCase();
    final filteredItems = store.inventory.where((product) {
      if (!_matchesFilter(product, _selectedFilter)) {
        return false;
      }
      if (query.isEmpty) return true;
      final stockLabel = product.stockState == InventoryStockState.lowStock
          ? 'low stock'
          : product.stockState == InventoryStockState.outOfStock
              ? 'out of stock'
              : 'in stock';
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query) ||
          stockLabel.contains(query) ||
          product.purchasePrice.toStringAsFixed(0).contains(query) ||
          product.sellingPrice.toStringAsFixed(0).contains(query);
    }).toList();
    final summary = _buildInventorySummary(store.inventory);
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        drawer: const MarketAppDrawer(selectedItem: 'Products'),
        backgroundColor: const Color(0xFFFFFEFC),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _PremiumProductsHeader(
                    onAddTap: _openAddProductPage,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InventorySummaryGrid(summary: summary),
                          const SizedBox(height: 12),
                          _ItemsSearchBar(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _FilterChipsRow(
                            selectedFilter: _selectedFilter,
                            onChanged: (filter) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _SectionHeader(
                            title: 'All Products',
                            trailing: '${filteredItems.length} shown',
                          ),
                          const SizedBox(height: 8),
                          if (filteredItems.isEmpty)
                            _EmptyProductsState(
                              query: _searchQuery,
                              filter: _selectedFilter,
                              onAddTap: _openAddProductPage,
                              onClearFilter: () {
                                setState(() {
                                  _selectedFilter = _InventoryFilter.all;
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          else
                            ListView.separated(
                              itemCount: filteredItems.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final product = filteredItems[index];
                                return _InventoryRowTile(
                                  product: product,
                                  onEdit: () => _editProduct(product),
                                  onDelete: () => _deleteProduct(product),
                                );
                              },
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_successMessage != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 86,
                  child: SuccessMessageBanner(
                    message: _successMessage!,
                    type: _lastAddedType ?? ProductArtType.aquafina,
                    imagePath: _lastAddedImagePath,
                  ),
                ),
              const Positioned(
                right: 6,
                top: 300,
                child: ScrollHandle(),
              ),
            ],
          ),
        ),
        floatingActionButton: _FloatingAddButton(onTap: _openAddProductPage),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

String _money(double value) {
  final whole = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return 'TSH $buffer';
}


class _PremiumProductsHeader extends StatelessWidget {
  const _PremiumProductsHeader({
    required this.onAddTap,
  });

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE7EAF0)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B8CFF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Products',
                    style: TextStyle(
                      color: Color(0xFF33363F),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  _HeaderActionButton(
                    icon: Icons.add_rounded,
                    background: const Color(0xFF23262D),
                    foreground: Colors.white,
                    onTap: onAddTap,
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

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.showDot = false,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Icon(icon, color: foreground, size: 20),
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (showDot)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

_InventorySummaryData _buildInventorySummary(List<InventoryProductItem> items) {
  final totalProducts = items.length;
  final totalUnits = items.fold<int>(0, (sum, item) => sum + item.stockCount);
  final lowStock = items.where((item) {
    return item.stockState == InventoryStockState.lowStock || item.stockCount <= 20;
  }).length;
  final inventoryValue = items.fold<double>(
    0,
    (sum, item) => sum + (item.sellingPrice * item.stockCount),
  );
  return _InventorySummaryData(
    totalProducts: totalProducts,
    totalUnits: totalUnits,
    lowStock: lowStock,
    inventoryValue: inventoryValue,
  );
}

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.menu, color: AppColors.ink, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Management',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage your products and inventory',
                  style: TextStyle(
                    color: Color(0xFF97A0B2),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _NotificationBell(),
        ],
      ),
    );
  }
}

class _HeaderActionCircle extends StatelessWidget {
  const _HeaderActionCircle({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF23262D) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: filled ? Colors.transparent : const Color(0xFFE7EAF0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0E1726),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : AppColors.ink,
        ),
      ),
    );
  }
}

class _InventorySummaryData {
  const _InventorySummaryData({
    required this.totalProducts,
    required this.totalUnits,
    required this.lowStock,
    required this.inventoryValue,
  });

  final int totalProducts;
  final int totalUnits;
  final int lowStock;
  final double inventoryValue;
}

enum _InventoryFilter {
  all,
  inStock,
  lowStock,
  outOfStock,
}

bool _matchesFilter(InventoryProductItem product, _InventoryFilter filter) {
  switch (filter) {
    case _InventoryFilter.all:
      return true;
    case _InventoryFilter.inStock:
      return product.stockState == InventoryStockState.inStock;
    case _InventoryFilter.lowStock:
      return product.stockState == InventoryStockState.lowStock;
    case _InventoryFilter.outOfStock:
      return product.stockState == InventoryStockState.outOfStock;
  }
}

_StockMeta _stockMeta(InventoryStockState state) {
  switch (state) {
    case InventoryStockState.inStock:
      return const _StockMeta(
        label: 'In stock',
        icon: Icons.check_circle_rounded,
        foreground: Color(0xFF2AA24F),
        background: Color(0xFFEAF8EE),
      );
    case InventoryStockState.lowStock:
      return const _StockMeta(
        label: 'Low stock',
        icon: Icons.schedule_rounded,
        foreground: Color(0xFFC77817),
        background: Color(0xFFFFF4E5),
      );
    case InventoryStockState.outOfStock:
      return const _StockMeta(
        label: 'Out of stock',
        icon: Icons.cancel_rounded,
        foreground: Color(0xFFE06A5C),
        background: Color(0xFFFDECEC),
      );
  }
}

class _StockMeta {
  const _StockMeta({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
}

class _InventorySummaryGrid extends StatelessWidget {
  const _InventorySummaryGrid({required this.summary});

  final _InventorySummaryData summary;

  @override
  Widget build(BuildContext context) {
    final cards = <_InventorySummaryCardData>[
      _InventorySummaryCardData(
        icon: Icons.inventory_2_outlined,
        iconColor: const Color(0xFF2F6FDF),
        iconBackground: const Color(0xFFECF3FF),
        title: 'Total Products',
        value: summary.totalProducts.toString(),
        footer: 'Across your shelves',
      ),
      _InventorySummaryCardData(
        icon: Icons.stacked_bar_chart_rounded,
        iconColor: const Color(0xFF2AA24F),
        iconBackground: const Color(0xFFEAF8EE),
        title: 'Stock Units',
        value: summary.totalUnits.toString(),
        footer: 'Available to sell',
      ),
      _InventorySummaryCardData(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFC77817),
        iconBackground: const Color(0xFFFFF4E5),
        title: 'Low Stock',
        value: summary.lowStock.toString(),
        footer: 'Needs attention',
      ),
      _InventorySummaryCardData(
        icon: Icons.payments_outlined,
        iconColor: const Color(0xFF9747FF),
        iconBackground: const Color(0xFFF3EAFE),
        title: 'Inventory Value',
        value: _money(summary.inventoryValue),
        footer: 'At retail price',
        wideValue: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth > 560 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _InventorySummaryCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _InventorySummaryCardData {
  const _InventorySummaryCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.footer,
    this.wideValue = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final String footer;
  final bool wideValue;
}

class _InventorySummaryCard extends StatelessWidget {
  const _InventorySummaryCard({required this.data});

  final _InventorySummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            style: const TextStyle(
              color: Color(0xFF7A859C),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            maxLines: data.wideValue ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: data.wideValue ? 14 : 18,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.footer,
            style: const TextStyle(
              color: Color(0xFF8A93A7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryGridCard extends StatelessWidget {
  const _InventoryGridCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryProductItem product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stock = _stockMeta(product.stockState);
    final estimatedProfit = product.sellingPrice - product.purchasePrice;

    return SizedBox(
      width: 220,
      height: 138,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onEdit,
          onLongPress: onDelete,
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE7EAF0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C0E1726),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: stock.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            stock.icon,
                            color: stock.foreground,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              color: Color(0xFF7B8598),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _money(product.sellingPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'Stock ${product.stockCount}',
                          style: const TextStyle(
                            color: Color(0xFF7B8598),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Profit ${_money(estimatedProfit)}',
                          style: TextStyle(
                            color: estimatedProfit >= 0
                                ? const Color(0xFF2AA24F)
                                : const Color(0xFFC65B4A),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: Color(0xFF7B8598),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 20, color: Color(0xFF2F6FDF)),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 20, color: Color(0xFFE06A5C)),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Color(0xFFE06A5C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _InventoryPromoCard extends StatelessWidget {
  const _InventoryPromoCard({
    required this.onAddTap,
    required this.onAdjustTap,
  });

  final VoidCallback onAddTap;
  final VoidCallback onAdjustTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0E1726),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          radius: 8,
          color: const Color(0xFFDDE3EA),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6E8F0)),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF5B8CFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keep stock moving',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add new items, review what is low, and keep your shelves in sync.',
                      style: TextStyle(
                        color: Color(0xFF7B8598),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onAddTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B8CFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onAdjustTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(color: Color(0xFFE1E6EE)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add New Sale',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.radius,
    required this.color,
  });

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dashWidth = 5.0;
    const gapWidth = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth > metric.length
            ? metric.length
            : distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
  });

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: Color(0xFF7B8598),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _InventoryFilter selectedFilter;
  final ValueChanged<_InventoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: 'All',
            isSelected: selectedFilter == _InventoryFilter.all,
            onTap: () => onChanged(_InventoryFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: 'In stock',
            isSelected: selectedFilter == _InventoryFilter.inStock,
            onTap: () => onChanged(_InventoryFilter.inStock),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: 'Low stock',
            isSelected: selectedFilter == _InventoryFilter.lowStock,
            onTap: () => onChanged(_InventoryFilter.lowStock),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: 'Out of stock',
            isSelected: selectedFilter == _InventoryFilter.outOfStock,
            onTap: () => onChanged(_InventoryFilter.outOfStock),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF23262D) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFF23262D) : const Color(0xFFE7EAF0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0E1726),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontSize: 11.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7B8598),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? AppColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingHero extends StatelessWidget {
  const _ListingHero({
    required this.totalProducts,
  });

  final int totalProducts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0E1726),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF2B6FF3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Catalog',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Track, sort, and manage $totalProducts items',
                  style: const TextStyle(
                    color: Color(0xFF7B8598),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListHeaderRow extends StatelessWidget {
  const _ListHeaderRow({
    required this.totalLabel,
    required this.sortLabel,
  });

  final String totalLabel;
  final String sortLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF97A0B2),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: 'Total Products '),
              TextSpan(
                text: totalLabel,
                style: const TextStyle(
                  color: Color(0xFF2B6FF3),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              const Text(
                'Sort by: ',
                style: TextStyle(
                  color: Color(0xFF97A0B2),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sortLabel,
                style: const TextStyle(
                  color: Color(0xFF2B6FF3),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF2B6FF3), size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7EAF0)),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.ink,
            size: 26,
          ),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF2B6FF3),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2F6FDF), Color(0xFF265ECB)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332F6FDF),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Add Product',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({
    required this.query,
    required this.filter,
    required this.onAddTap,
    required this.onClearFilter,
  });

  final String query;
  final _InventoryFilter filter;
  final VoidCallback onAddTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final filterLabel = switch (filter) {
      _InventoryFilter.all => 'all products',
      _InventoryFilter.inStock => 'in stock items',
      _InventoryFilter.lowStock => 'low stock items',
      _InventoryFilter.outOfStock => 'out of stock items',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0E1726),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 34,
              color: Color(0xFF5B8CFF),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            query.isEmpty
                ? 'No $filterLabel yet'
                : 'No products match "$query"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            query.isEmpty
                ? 'Add a product to start building a cleaner inventory catalog.'
                : 'Try a different name, code, or clear the active filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8598),
              fontSize: 12.2,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAddTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8CFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Product',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onClearFilter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFE1E6EE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsSearchBar extends StatelessWidget {
  const _ItemsSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD8DDE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 24, color: Color(0xFF7E8695)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              enableInteractiveSelection: true,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search products by name or SKU',
                hintStyle: const TextStyle(
                  color: Color(0xFFB2B8C2),
                  fontSize: 12.8,
                  fontWeight: FontWeight.w500,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          controller.clear();
                          onChanged('');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF8A93A7),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryRowTile extends StatelessWidget {
  const _InventoryRowTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryProductItem product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stock = _stockMeta(product.stockState);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0E1726),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE8EDF3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _TileArt(product: product),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7B8598),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _money(product.sellingPrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: Color(0xFF7B8598),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 20, color: Color(0xFF2F6FDF)),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 20, color: Color(0xFFE06A5C)),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Color(0xFFE06A5C)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock ${product.stockCount}',
                      style: const TextStyle(
                        color: Color(0xFF7B8598),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _StockBadge(
                      label: stock.label,
                      icon: stock.icon,
                      background: stock.background,
                      foreground: stock.foreground,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _TileArt extends StatelessWidget {
  const _TileArt({
    required this.product,
  });

  final InventoryProductItem product;

  @override
  Widget build(BuildContext context) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.expand(
          child: Image.file(
            File(product.imagePath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _FallbackArt(label: product.name),
          ),
        ),
      );
    }
    return _FallbackArt(label: product.name);
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 9.1,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackArt extends StatelessWidget {
  const _FallbackArt({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final initials = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();

    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE6E8F0)),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF5B8CFF),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NewItemRow extends StatelessWidget {
  const _NewItemRow({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7EAF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0E1726),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8CFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEW ITEM',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Add a product to your inventory',
                    style: TextStyle(
                      color: Color(0xFF7B8598),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A93A7)),
          ],
        ),
      ),
    );
  }
}



