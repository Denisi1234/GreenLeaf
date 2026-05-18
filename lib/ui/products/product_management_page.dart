import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import 'add_product_page.dart';
import 'inventory_product_item.dart';
import '../widgets/market_shared_widgets.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
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
      message: '${created.name} is now in your inventory list',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    return Scaffold(
      drawer: const MarketAppDrawer(selectedItem: 'Products'),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Row(
                    children: [
                      DrawerMenuButton(),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product Management',
                              style: TextStyle(
                                color: Color(0xFF202938),
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage your products and inventory',
                              style: TextStyle(
                                color: Color(0xFF96A0AF),
                                fontSize: 12.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NotificationButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 108),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFF0F2F6)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            _ManagementSearchBar(),
                            SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _FilterChip(
                                    label: 'Categories',
                                    icon: Icons.tune_rounded,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _FilterChip(
                                    label: 'Status',
                                    icon: Icons.inventory_2_outlined,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _FilterChip(
                                    label: 'Filter',
                                    icon: Icons.tune_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text(
                            'Total Products ',
                            style: TextStyle(
                              color: Color(0xFF8D97A6),
                              fontSize: 12.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${store.inventory.length}',
                              style: const TextStyle(
                                color: Color(0xFF2B6FF3),
                                fontSize: 13.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Sort by: ',
                              style: TextStyle(
                                color: Color(0xFF8D97A6),
                                fontSize: 12.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              'Name',
                              style: TextStyle(
                                color: Color(0xFF2B6FF3),
                                fontSize: 13.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF2B6FF3),
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...store.inventory.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ProductManagementCard(product: product),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 28,
              child: GestureDetector(
                onTap: _openAddProductPage,
                child: Container(
                  width: 94,
                  height: 94,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3C86FF), Color(0xFF2B6FF3)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x332B6FF3),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 30),
                      SizedBox(height: 2),
                      Text(
                        'Add Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementSearchBar extends StatelessWidget {
  const _ManagementSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, size: 28, color: Color(0xFF98A1AF)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search products by name or ID...',
              style: TextStyle(
                color: Color(0xFFA7AFBC),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.qr_code_scanner_rounded,
            color: Color(0xFF7E8AA0),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EBF1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF556071), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3B4557),
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7A8493),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ProductManagementCard extends StatelessWidget {
  const _ProductManagementCard({required this.product});

  final InventoryProductItem product;

  @override
  Widget build(BuildContext context) {
    final stockColor = switch (product.stockState) {
      InventoryStockState.inStock => const Color(0xFF2DBB5F),
      InventoryStockState.lowStock => const Color(0xFFFFAA15),
      InventoryStockState.outOfStock => const Color(0xFFE63946),
    };

    final stockLabel = switch (product.stockState) {
      InventoryStockState.inStock => 'In Stock',
      InventoryStockState.lowStock => 'Low Stock',
      InventoryStockState.outOfStock => 'Out of Stock',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEFF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.imagePath != null && product.imagePath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(product.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Padding(
                        padding: const EdgeInsets.all(9),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: ProductArt(type: product.artType),
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(9),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: ProductArt(type: product.artType),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 88,
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
                              product.code,
                              style: const TextStyle(
                                color: Color(0xFFA0A8B6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF202938),
                                fontSize: 14.3,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              product.category,
                              style: const TextStyle(
                                color: Color(0xFF8E96A4),
                                fontSize: 11.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        product.sellingPriceLabel,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$stockLabel: ${product.stockCount}',
                        style: const TextStyle(
                          color: Color(0xFF6E7684),
                          fontSize: 11.4,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF202938),
            size: 28,
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF2B6FF3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
