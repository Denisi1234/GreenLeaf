import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
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
        backgroundColor: const Color(0xFFF1F5F9),
        body: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            SafeArea(
              child: Column(
                children: [
                  _ProductsHeader(
                    onAddTap: _openAddProductPage,
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      children: [
                        _InventorySummaryGrid(summary: summary),
                        const SizedBox(height: 12),
                        _InventoryPromoCard(
                          onAddTap: _openAddProductPage,
                          onAdjustTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const MarketHomePage(),
                            ),
                          ),
                        ),
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
                        _SectionHeader(
                          title: 'All Items',
                          trailing: '${filteredItems.length} shown',
                        ),
                        const SizedBox(height: 8),
                        ...filteredItems.map(
                          (product) => _InventoryRowTile(
                            product: product,
                            onEdit: () => _editProduct(product),
                            onDelete: () => _deleteProduct(product),
                          ),
                        ),
                        _NewItemRow(onTap: _openAddProductPage),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  const _ProductsHeader({
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
          child: Row(
            children: [
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: AppColors.ink),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  'Products',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _HeaderActionCircle(
                icon: Icons.add_rounded,
                filled: true,
                onTap: onAddTap,
              ),
            ],
          ),
        ),
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
      height: 126,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: data.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: const TextStyle(
              color: Color(0xFF7B8598),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.value,
            maxLines: data.wideValue ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: data.wideValue ? 13 : 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.12,
            ),
          ),
          const Spacer(),
          Text(
            data.footer,
            style: const TextStyle(
              color: Color(0xFF7B8598),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
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
        children: [
          const Icon(Icons.search, size: 24, color: Color(0xFF5B8CFF)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              enableInteractiveSelection: true,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'I want a product...',
                hintStyle: const TextStyle(
                  color: Color(0xFF8A93A7),
                  fontSize: 13.5,
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
    final estimatedProfit = product.sellingPrice - product.purchasePrice;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
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
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: _TileArt(product: product),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B8598),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      padding: EdgeInsets.zero,
                      icon: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE7EAF0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A0E1726),
                              blurRadius: 5,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          ':',
                          style: TextStyle(
                            color: Color(0xFF7B8598),
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                              Text('Delete',
                                  style: TextStyle(color: Color(0xFFE06A5C))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _StockBadge(
                      label: product.stockState == InventoryStockState.lowStock
                          ? 'LOW STOCK'
                          : product.stockState == InventoryStockState.outOfStock
                              ? 'OUT OF STOCK'
                              : 'IN STOCK',
                      icon: product.stockState == InventoryStockState.lowStock
                          ? Icons.schedule_rounded
                          : product.stockState == InventoryStockState.outOfStock
                              ? Icons.cancel_rounded
                              : Icons.check_circle_rounded,
                      background: product.stockState == InventoryStockState.lowStock
                          ? const Color(0xFFFFF4E5)
                          : product.stockState == InventoryStockState.outOfStock
                              ? const Color(0xFFFDECEC)
                              : const Color(0xFFEAF8EE),
                      foreground: product.stockState == InventoryStockState.lowStock
                          ? const Color(0xFFC77817)
                          : product.stockState == InventoryStockState.outOfStock
                              ? const Color(0xFFE06A5C)
                              : const Color(0xFF2AA24F),
                    ),
                    _StockBadge(
                      label: 'Purchase ${_money(product.purchasePrice)}',
                      icon: Icons.arrow_downward_rounded,
                      background: const Color(0xFFF6F8FB),
                      foreground: const Color(0xFF7B8598),
                    ),
                    _StockBadge(
                      label: 'Selling ${_money(product.sellingPrice)}',
                      icon: Icons.arrow_upward_rounded,
                      background: const Color(0xFFF6F8FB),
                      foreground: const Color(0xFF7B8598),
                    ),
                    _StockBadge(
                      label: 'Profit ${_money(estimatedProfit)}',
                      icon: Icons.trending_up_rounded,
                      background: const Color(0xFFF6F8FB),
                      foreground: estimatedProfit >= 0
                          ? const Color(0xFF2AA24F)
                          : const Color(0xFFE06A5C),
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
        child: Image.file(
          File(product.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackArt(label: product.name),
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
