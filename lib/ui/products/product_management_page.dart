import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_product_page.dart';
import 'inventory_product_item.dart';

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
      message: '${created.name} is now in your items list',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();

    return Scaffold(
      drawer: const MarketAppDrawer(selectedItem: 'Products'),
      backgroundColor: const Color(0xFFE7E7E7),
      body: SafeArea(
        child: Column(
          children: [
            const _ItemsTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: Row(
                children: [
                  const Expanded(child: _ItemsSearchBar()),
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    icon: Icons.qr_code_scanner,
                    onTap: () => showMarketNotice(
                      context,
                      title: 'Scan',
                      message: 'Barcode scanner is not connected yet',
                      type: MarketNoticeType.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    icon: Icons.bolt,
                    onTap: () => showMarketNotice(
                      context,
                      title: 'Quick Action',
                      message: 'Quick action is not connected yet',
                      type: MarketNoticeType.warning,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                itemCount: store.inventory.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, index) {
                  if (index == store.inventory.length) {
                    return _NewItemTile(onTap: _openAddProductPage);
                  }

                  final product = store.inventory[index];
                  return _InventoryGridTile(product: product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsTopBar extends StatelessWidget {
  const _ItemsTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFF355BD8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Items',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          const Icon(Icons.group_add_outlined, color: Colors.white, size: 24),
          const SizedBox(width: 14),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.mark_chat_unread_outlined,
                  color: Colors.white, size: 24),
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE54040),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ItemsSearchBar extends StatelessWidget {
  const _ItemsSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 24, color: Color(0xFF4C68D6)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'I want to sell...',
              style: TextStyle(
                color: Color(0xFF202938),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF4C68D6), size: 26),
      ),
    );
  }
}

class _InventoryGridTile extends StatelessWidget {
  const _InventoryGridTile({
    required this.product,
  });

  final InventoryProductItem product;

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
    return 'TSh$buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFD3D3D3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: _TileArt(product: product),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _money(product.sellingPrice),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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
        borderRadius: BorderRadius.circular(4),
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

class _FallbackArt extends StatelessWidget {
  const _FallbackArt({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final initials = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    final isCircle = label.length.isOdd;

    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: label.toLowerCase().contains('g')
              ? const Color(0xFFF2F2FD)
              : const Color(0xFFFF4036),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: label.toLowerCase().contains('g')
                ? Colors.black87
                : Colors.transparent,
            fontSize: 26,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NewItemTile extends StatelessWidget {
  const _NewItemTile({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFFD3D3D3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF476ADB),
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
            SizedBox(height: 16),
            Text(
              'NEW ITEM',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
