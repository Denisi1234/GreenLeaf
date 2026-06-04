import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
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
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
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
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ItemsSearchBar(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          if (filteredItems.isEmpty)
                            _EmptyProductsState(
                              query: _searchQuery,
                              onAddTap: _openAddProductPage,
                              onClearFilter: () {
                                setState(() {
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
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final product = filteredItems[index];
                                return _InventoryRowTile(
                                  product: product,
                                  onEdit: () => _editProduct(product),
                                  onDelete: () => _deleteProduct(product),
                                );
                              },
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Inventory',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 23,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage stock, pricing, and edits',
                      style: TextStyle(
                        color: Color(0xFF7A859C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _AddProductPill(onTap: onAddTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProductPill extends StatelessWidget {
  const _AddProductPill({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 46,
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF20A363),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A20A363),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Add Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
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

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({
    required this.query,
    required this.onAddTap,
    required this.onClearFilter,
  });

  final String query;
  final VoidCallback onAddTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 38,
              color: Color(0xFF1C8F5A),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            query.isEmpty ? 'No products yet' : 'No products match "$query"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            query.isEmpty
                ? 'Add your first item to start building the inventory list.'
                : 'Try a different name or clear the search text.',
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
                    backgroundColor: const Color(0xFF1C8F5A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                    side: const BorderSide(color: Color(0xFFD9E2EC)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 18,
              color: Color(0xFF7B8598),
            ),
          ),
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
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search inventory...',
                hintStyle: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF8A93A7),
                        ),
                      )
                    : null,
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        onLongPress: () => _confirmDelete(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EBF1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x040E1726),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: _TileArt(product: product),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16.3,
                        fontWeight: FontWeight.w800,
                        height: 1.06,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: 'Stock: ',
                        style: const TextStyle(
                          color: Color(0xFF7B8598),
                          fontSize: 12.3,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '${product.stockCount}',
                            style: TextStyle(
                              color: stock.foreground,
                              fontSize: 12.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 74,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _money(product.sellingPrice),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1C8F5A),
                        fontSize: 16.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _EditActionButton(onTap: onEdit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditActionButton extends StatelessWidget {
  const _EditActionButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E9F0)),
          ),
          child: const Icon(
            Icons.edit_outlined,
            size: 19,
            color: Color(0xFF1C8F5A),
          ),
        ),
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
      return Image.file(
        File(product.imagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _FallbackArt(label: product.name),
      );
    }
    return _FallbackArt(label: product.name);
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E8F0)),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF1C8F5A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}


