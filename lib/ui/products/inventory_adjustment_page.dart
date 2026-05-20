import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';
import 'inventory_product_item.dart';

class InventoryAdjustmentPage extends StatefulWidget {
  const InventoryAdjustmentPage({super.key});

  @override
  State<InventoryAdjustmentPage> createState() =>
      _InventoryAdjustmentPageState();
}

class _InventoryAdjustmentPageState extends State<InventoryAdjustmentPage> {
  final _searchController = TextEditingController();
  final Map<String, int> _adjustments = <String, int>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeAdjustment(String code, int delta) {
    setState(() {
      _adjustments[code] = (_adjustments[code] ?? 0) + delta;
      if (_adjustments[code] == 0) {
        _adjustments.remove(code);
      }
    });
  }

  Future<void> _confirmAdjustment() async {
    final store = context.read<PosLocalStore>();
    final totalAdjusted =
        _adjustments.values.fold<int>(0, (sum, item) => sum + item.abs());

    if (totalAdjusted == 0) {
      showMarketNotice(
        context,
        title: 'No Changes',
        message: 'Adjust at least one product before confirming',
        type: MarketNoticeType.warning,
      );
      return;
    }

    await store.applyInventoryAdjustments(Map<String, int>.from(_adjustments));
    if (!mounted) return;

    showMarketNotice(
      context,
      title: 'Adjustment Saved',
      message:
          'The stock update was applied to ${_adjustments.length} product(s)',
    );

    setState(() {
      _adjustments.clear();
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final query = _searchController.text.trim().toLowerCase();
    final items = store.inventory.where((product) {
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _AdjustmentFooter(
        onConfirm: _confirmAdjustment,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF1E273A),
                        size: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Inventory Adjustment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E273A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDE2EA)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF7A8393),
                            size: 28,
                          ),
                          hintText: 'Search by product name or SKU',
                          hintStyle: TextStyle(
                            color: Color(0xFFABB2BF),
                            fontSize: 15.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Filter Inventory'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text('All Items'),
                                trailing: Icon(Icons.check_circle_outline),
                              ),
                              ListTile(
                                title: Text('Low Stock'),
                              ),
                              ListTile(
                                title: Text('Out of Stock'),
                              ),
                              ListTile(
                                title: Text('Recent Updates'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      width: 122,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDE2EA)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            color: Color(0xFF1E273A),
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Filter',
                            style: TextStyle(
                              color: Color(0xFF1E273A),
                              fontSize: 15.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      border: Border.all(color: const Color(0xFFE1E5EC)),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Product',
                              style: TextStyle(
                                color: Color(0xFF3B4254),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Current Stock',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF3B4254),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Adjustment Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF3B4254),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                      border: Border.all(color: const Color(0xFFE1E5EC)),
                    ),
                    child: Column(
                      children: [
                        for (var index = 0; index < items.length; index++)
                          Column(
                            children: [
                              _AdjustmentProductRow(
                                product: items[index],
                                adjustmentQty:
                                    _adjustments[items[index].code] ?? 0,
                                onDecrease: () =>
                                    _changeAdjustment(items[index].code, -1),
                                onIncrease: () =>
                                    _changeAdjustment(items[index].code, 1),
                              ),
                              if (index != items.length - 1)
                                const Divider(
                                    height: 1, color: Color(0xFFE7EAF0)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentProductRow extends StatelessWidget {
  const _AdjustmentProductRow({
    required this.product,
    required this.adjustmentQty,
    required this.onDecrease,
    required this.onIncrease,
  });

  final InventoryProductItem product;
  final int adjustmentQty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E9F1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imagePath != null && product.imagePath!.isNotEmpty
                  ? Image.file(
                      File(product.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: ProductArt(type: product.artType),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E273A),
                    fontSize: 15.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${product.code}',
                  style: const TextStyle(
                    color: Color(0xFF8A93A3),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${product.stockCount}',
                  style: const TextStyle(
                    color: Color(0xFF1E273A),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'units',
                  style: TextStyle(
                    color: Color(0xFF8A93A3),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD7DCE5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: onDecrease,
                    icon: const Icon(
                      Icons.remove_rounded,
                      color: Color(0xFF8A93A3),
                      size: 24,
                    ),
                  ),
                  Text(
                    '$adjustmentQty',
                    style: const TextStyle(
                      color: Color(0xFF1E273A),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: onIncrease,
                    icon: const Icon(
                      Icons.add_rounded,
                      color: Color(0xFF2B5FCE),
                      size: 24,
                    ),
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

class _AdjustmentFooter extends StatelessWidget {
  const _AdjustmentFooter({
    required this.onConfirm,
  });

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF356BD8), Color(0xFF2B5FCE)],
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Confirm Adjustment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4EBF7)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF2B5FCE),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please review the details above before confirming the adjustment.',
                        style: TextStyle(
                          color: Color(0xFF5C667A),
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
