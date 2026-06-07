import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_product_page.dart';
import '../more/duka_ai_page.dart';
import 'inventory_product_item.dart';

String _formatPrice(double value) {
  return 'TSH ${formatCurrency(value)}';
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
  String _selectedCategory = 'All';

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
        content: Text(
            'Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
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
    final categories = <String>{
      'All',
      ...store.inventory.map((product) => product.category),
    }.toList();
    final filteredItems = store.inventory.where((product) {
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      if (!matchesCategory) return false;
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
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        drawer: widget.useSharedShell
            ? null
            : const MarketAppDrawer(selectedItem: 'Products'),
        floatingActionButton: _AddProductFab(
          onPressed: _openAddProductPage,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          top: !widget.useSharedShell,
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: AppColors.pageBackground),
              ),
              Column(
                children: [
                  if (!widget.useSharedShell) const _ProductsHeader(),
                  _PinnedSearchPanel(
                    controller: _searchController,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onClearSearch: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  ),
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: _CategoryStrip(
                              categories: categories,
                              selectedCategory: _selectedCategory,
                              onSelected: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                          ),
                        ),
                        if (filteredItems.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              child: _ProductsEmptyState(
                                query: _searchQuery,
                                category: _selectedCategory,
                                onAddTap: _openAddProductPage,
                                onClearFilter: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _selectedCategory = 'All';
                                  });
                                },
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.72,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = filteredItems[index];
                                  return _ProductGridCard(
                                    product: product,
                                    onTap: () => _editProduct(product),
                                    onDelete: () => _deleteProduct(product),
                                  );
                                },
                                childCount: filteredItems.length,
                              ),
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
    );
  }
}

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader();

  @override
  Widget build(BuildContext context) {
    return MarketPageHeader(
      title: 'Products',
      showBackButton: false,
      centerTitle: false,
      showBorder: false,
      titleSize: 24,
      titleWeight: FontWeight.w700,
      actions: [
        MarketHeaderActionButtons(
          aiBackground: const Color(0xFFF8FAFC),
          notificationBackground: const Color(0xFFF8FAFC),
          aiBorderColor: const Color(0xFFE5EAF0),
          notificationBorderColor: const Color(0xFFE5EAF0),
          onDukaAiTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const DukaAiAdvisorPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PinnedSearchPanel extends StatelessWidget {
  const _PinnedSearchPanel({
    required this.controller,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: MarketSurfaceCard(
        backgroundColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFE5EAF0),
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: MarketSearchField(
            controller: controller,
            hintText: 'Search products by name, SKU, or category',
            onChanged: onSearchChanged,
            onClear: onClearSearch,
            backgroundColor: const Color(0xFFF8FAFC),
            borderColor: const Color(0xFFE5EAF0),
            radius: 14,
            height: 52,
            paddingHorizontal: 14,
            iconColor: const Color(0xFF94A3B8),
            hintColor: const Color(0xFF94A3B8),
            textColor: const Color(0xFF111827),
            iconSize: 20,
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return _CategoryChip(
            label: category,
            selected: selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1F6FEB) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected ? const Color(0xFF1F6FEB) : const Color(0xFFE5EAF0),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: selected ? Colors.white : const Color(0xFF4B5563),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  final InventoryProductItem product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: MarketSurfaceCard(
          borderColor: const Color(0xFFE1E5EB),
          radius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: ColoredBox(
                          color: const Color(0xFFF8FAFC),
                          child: _ProductArtFrame(product: product),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 15,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatPrice(product.sellingPrice),
                                  style: const TextStyle(
                                    color: Color(0xFF1F6FEB),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product.stockCount} in stock',
                                  style: const TextStyle(
                                    color: Color(0xFF7A859C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 0),
                            child: _EditActionsButton(
                              onEdit: onTap,
                              onDelete: onDelete,
                            ),
                          ),
                        ],
                      ),
                    ],
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

enum _ProductCardAction {
  edit,
  delete,
}

class _EditActionsButton extends StatelessWidget {
  const _EditActionsButton({
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProductCardAction>(
      onSelected: (action) {
        switch (action) {
          case _ProductCardAction.edit:
            onEdit();
            break;
          case _ProductCardAction.delete:
            onDelete();
            break;
        }
      },
      offset: const Offset(0, 42),
      position: PopupMenuPosition.over,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE1E6ED)),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem<_ProductCardAction>(
          value: _ProductCardAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1B9B69)),
              SizedBox(width: 10),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem<_ProductCardAction>(
          value: _ProductCardAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 18, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Delete'),
            ],
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: Icon(
          Icons.edit_outlined,
          color: Color(0xFF1B9B69),
          size: 28,
        ),
      ),
    );
  }
}

class _AddProductFab extends StatelessWidget {
  const _AddProductFab({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: const Color(0xFFD94B4B),
        foregroundColor: Colors.white,
        elevation: 12,
        highlightElevation: 14,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        extendedPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        icon: const Icon(
          Icons.add_rounded,
          size: 24,
        ),
        label: const Text(
          'Add product',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _ProductArtFrame extends StatelessWidget {
  const _ProductArtFrame({
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
        errorBuilder: (_, __, ___) => Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: ProductArt(type: product.artType),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FittedBox(
          fit: BoxFit.contain,
          child: ProductArt(type: product.artType),
        ),
      ),
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState({
    required this.query,
    required this.category,
    required this.onAddTap,
    required this.onClearFilter,
  });

  final String query;
  final String category;
  final VoidCallback onAddTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(24),
      borderColor: const Color(0xFFE3E7ED),
      radius: 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F6),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: Color(0xFF1B9B69),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            query.isEmpty && category == 'All'
                ? 'No products yet'
                : 'No products found',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            query.isEmpty && category == 'All'
                ? 'Your inventory will appear here once products are added.'
                : 'Try another search or switch to a different category.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7A859C),
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          if (query.isEmpty && category == 'All')
            ElevatedButton(
              onPressed: onAddTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B9B69),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Add product',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onClearFilter,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: Color(0xFFD9E2EC)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Clear filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
