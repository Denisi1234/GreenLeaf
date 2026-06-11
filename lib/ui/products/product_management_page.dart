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
import '../notifications/notifications_page.dart';
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
            onPressed: () async {
              final store = context.read<PosLocalStore>();
              Navigator.pop(context);
              await store.removeProduct(product.code);
              if (!context.mounted) return;
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
    final config = store.businessCategoryConfig;
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
          accentColor: config.primaryColor,
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
                    hintText: config.productHint,
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
          showNotificationDot: true,
          onDukaAiTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const DukaAiAdvisorPage(),
              ),
            );
          },
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

class _PinnedSearchPanel extends StatelessWidget {
  const _PinnedSearchPanel({
    required this.controller,
    required this.hintText,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: MarketSearchField(
        controller: controller,
        hintText: hintText,
        onChanged: onSearchChanged,
        onClear: onClearSearch,
        onScanTap: () {
          showMarketNotice(
            context,
            title: 'Scanner Active',
            message: 'SKU Barcode scanner would open here',
          );
        },
        backgroundColor: Colors.white,
        borderColor: const Color(0xFFF1F5F9),
        radius: 30,
        height: 60,
        showShadow: true,
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
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
            boxShadow: selected ? AppShadows.primary : null,
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: selected ? Colors.white : AppColors.textMain,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.standard),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.standard),
                    ),
                    child: _ProductArtFrame(product: product),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(product.sellingPrice),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _EditActionsButton(
                            onEdit: onTap,
                            onDelete: onDelete,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: product.stockCount > 5
                                  ? AppColors.success
                                  : (product.stockCount > 0
                                      ? AppColors.warning
                                      : AppColors.danger),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${product.stockCount} in stock',
                            style: AppTypography.helperText.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
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
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<_ProductCardAction>(
          value: _ProductCardAction.edit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Text('Edit', style: AppTypography.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem<_ProductCardAction>(
          value: _ProductCardAction.delete,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.danger),
              const SizedBox(width: AppSpacing.md),
              Text('Delete',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.textMuted,
          size: 18,
        ),
      ),
    );
  }
}

class _AddProductFab extends StatelessWidget {
  const _AddProductFab({
    required this.onPressed,
    this.accentColor = AppColors.primary,
  });

  final VoidCallback onPressed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'product_management_add_product_fab',
      onPressed: onPressed,
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
      elevation: 8,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.standard),
      ),
      extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      icon: const Icon(Icons.add_rounded, size: 24),
      label: Text(
        'Add Product',
        style: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
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
        padding: const EdgeInsets.all(AppSpacing.lg),
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
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      radius: AppRadius.extraRounded,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.rounded),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            query.isEmpty && category == 'All'
                ? 'No products yet'
                : 'No products found',
            textAlign: TextAlign.center,
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            query.isEmpty && category == 'All'
                ? 'Your inventory will appear here once products are added.'
                : 'Try another search or switch to a different category.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (query.isEmpty && category == 'All')
            MarketButton(
              label: 'Add Product',
              onTap: onAddTap,
              isFullWidth: false,
              icon: Icons.add_rounded,
            )
          else
            MarketButton(
              label: 'Clear Filters',
              onTap: onClearFilter,
              isPrimary: false,
              isFullWidth: false,
              icon: Icons.filter_list_off_rounded,
            ),
        ],
      ),
    );
  }
}
