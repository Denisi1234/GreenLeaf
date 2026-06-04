import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/daftari_scan_parser.dart';
import '../models/product_item.dart';
import '../scanner/daftari_scan_page.dart';
import '../widgets/app_design.dart';
import '../receipt/receipt_success_page.dart';
import '../widgets/market_shared_widgets.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.items,
  });

  final List<ProductItem> items;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final List<OrderLineItem> _orderLines;
  bool _showScaleBanner = true;

  @override
  void initState() {
    super.initState();
    final byKey = <String, OrderLineItem>{};
    for (final item in widget.items) {
      final key = '${item.name}|${item.size}|${item.price}|${item.type.name}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = OrderLineItem(product: item, quantity: 1);
      } else {
        existing.quantity += 1;
      }
    }
    _orderLines = byKey.values.toList();
  }

  double get _subtotal =>
      _orderLines.fold(0, (sum, line) => sum + line.totalPrice);
  double get _tax => 0;
  double get _grandTotal => _subtotal + _tax;
  int get _itemTypes => _orderLines.length;
  int get _unitCount =>
      _orderLines.fold(0, (sum, line) => sum + line.quantity);
  bool get _hasItems => _orderLines.isNotEmpty;

  String _amount(double value) {
    final whole = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  void _increaseQuantity(OrderLineItem line) {
    final didAdd = context.read<PosLocalStore>().addToCart(line.product);
    if (!didAdd) {
      showMarketNotice(
        context,
        title: 'Out Of Stock',
        message: '${line.product.name} has no more stock available',
        type: MarketNoticeType.warning,
      );
      return;
    }
    setState(() {
      line.quantity += 1;
    });
  }

  void _decreaseQuantity(OrderLineItem line) {
    final didRemove =
        context.read<PosLocalStore>().removeSingleFromCart(line.product);
    if (!didRemove) return;
    setState(() {
      line.quantity -= 1;
      if (line.quantity <= 0) {
        _orderLines.remove(line);
      }
    });
  }

  Future<void> _clearCart() async {
    await context.read<PosLocalStore>().clearCart();
    if (!mounted) return;
    setState(_orderLines.clear);
  }

  void _mergeImportedItem(ProductItem product, int quantity) {
    final key = '${product.name}|${product.size}|${product.price}|${product.type.name}';
    final existingIndex = _orderLines.indexWhere((line) {
      final lineKey =
          '${line.product.name}|${line.product.size}|${line.product.price}|${line.product.type.name}';
      return lineKey == key;
    });

    if (existingIndex == -1) {
      _orderLines.add(OrderLineItem(product: product, quantity: quantity));
      return;
    }

    _orderLines[existingIndex].quantity += quantity;
  }

  Future<void> _scanDaftari() async {
    final importedLines = await Navigator.of(context).push<List<DaftariScanLine>>(
      MaterialPageRoute<List<DaftariScanLine>>(
        builder: (context) => const DaftariScanPage(
          mode: DaftariScanMode.checkout,
        ),
      ),
    );

    if (!mounted || importedLines == null || importedLines.isEmpty) return;

    final store = context.read<PosLocalStore>();
    var importedUnits = 0;
    var skippedLines = 0;

    for (final line in importedLines) {
      final product = line.matchedProduct;
      final quantity = line.quantity.round();
      if (product == null || quantity <= 0) {
        skippedLines += 1;
        continue;
      }

      final didAdd = store.addToCartQuantity(product, quantity);
      if (!didAdd) {
        skippedLines += 1;
        continue;
      }

      setState(() {
        _mergeImportedItem(product, quantity);
      });
      importedUnits += quantity;

      if (line.rawText.trim().isNotEmpty) {
        await store.rememberDaftariCorrection(
          sourceText: line.rawText,
          product: product,
        );
      }
    }

    if (!mounted) return;

    if (importedUnits > 0) {
      showMarketNotice(
        context,
        title: 'Daftari Imported',
        message: '$importedUnits unit(s) added to the current sale',
      );
    }

    if (skippedLines > 0) {
      showMarketNotice(
        context,
        title: 'Some Lines Skipped',
        message: 'A few lines could not be matched or were out of stock',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<void> _confirmPayment() async {
    if (!_hasItems) {
      showMarketNotice(
        context,
        title: 'Cart Is Empty',
        message: 'Add at least one product before charging this order',
        type: MarketNoticeType.warning,
      );
      return;
    }

    try {
      final completedOrder = await context.read<PosLocalStore>().completeCashSale(
            items: _orderLines,
            cashTendered: _grandTotal,
            cashierName: 'John Doe',
            registerName: 'POS-01',
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => ReceiptSuccessPage(order: completedOrder),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Sale Could Not Complete',
        message: error.message,
        type: MarketNoticeType.warning,
      );
    }
  }

  void _showComingSoon(String label) {
    showMarketNotice(
      context,
      title: label,
      message: '$label is not wired yet in this screen',
      type: MarketNoticeType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Column(
          children: [
            _CounterAppBar(onBack: () => Navigator.of(context).pop()),
            if (_showScaleBanner)
              _ScaleBanner(onClose: () => setState(() => _showScaleBanner = false)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                children: [
                  if (_hasItems)
                    ..._orderLines.map(
                      (line) => _CounterLineTile(
                        line: line,
                        amountText: _amount(line.totalPrice),
                        onIncrease: () => _increaseQuantity(line),
                        onDecrease: () => _decreaseQuantity(line),
                      ),
                    )
                  else
                    const _EmptyCounterState(),
                  const SizedBox(height: 6),
                  _CounterActionRow(
                    onAddItem: () => Navigator.of(context).pop(),
                    onScan: _scanDaftari,
                  ),
                  const SizedBox(height: 6),
                  _TotalsPanel(
                    subtotal: _amount(_subtotal),
                    tax: _amount(_tax),
                    grandTotal: _amount(_grandTotal),
                    itemTypes: _itemTypes,
                    unitCount: _unitCount,
                    onAddTax: () => _showComingSoon('Add Tax'),
                    onAddDiscount: () => _showComingSoon('Add Discount'),
                    onOtherCharges: () => _showComingSoon('Add Other Charges'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FooterActionButton(
                          label: 'Clear',
                          color: const Color(0xFFE66C73),
                          onTap: _clearCart,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FooterActionButton(
                          label: 'Save for later',
                          color: const Color(0xFFFFAF2E),
                          onTap: () => _showComingSoon('Save for later'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: _ChargeBar(
                totalLabel: 'Charge: TSh${_amount(_grandTotal)}',
                onTap: _confirmPayment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterAppBar extends StatelessWidget {
  const _CounterAppBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFF355BD8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Counter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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

class _ScaleBanner extends StatelessWidget {
  const _ScaleBanner({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2FB),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text.rich(
              TextSpan(
                text:
                    'We now support weighing scales. Plug in and start billing faster, ',
                children: [
                  TextSpan(
                    text: 'Know More.',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ],
              ),
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.only(left: 8, top: 2),
              child: Icon(Icons.close, color: Color(0xFF7080C2), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterLineTile extends StatelessWidget {
  const _CounterLineTile({
    required this.line,
    required this.amountText,
    required this.onIncrease,
    required this.onDecrease,
  });

  final OrderLineItem line;
  final String amountText;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${line.quantity} x ${line.product.price}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              GestureDetector(
                onTap: onIncrease,
                child: const Icon(Icons.edit, color: Color(0xFF4D6ED8), size: 20),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDecrease,
                child: const Icon(Icons.remove_circle_outline,
                    color: Color(0xFFE66C73), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCounterState extends StatelessWidget {
  const _EmptyCounterState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.remove_shopping_cart_outlined,
              size: 36, color: Color(0xFF9CA3AF)),
          SizedBox(height: 10),
          Text(
            'No items in this counter yet',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterActionRow extends StatelessWidget {
  const _CounterActionRow({
    required this.onAddItem,
    required this.onScan,
  });

  final VoidCallback onAddItem;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onAddItem,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              color: Colors.white,
              child: const Text(
                'Add New Item',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onScan,
          child: Container(
            width: 58,
            height: 54,
            color: Colors.white,
            alignment: Alignment.center,
            child: const Icon(Icons.document_scanner_outlined,
                color: Color(0xFF4D6ED8), size: 24),
          ),
        ),
      ],
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.itemTypes,
    required this.unitCount,
    required this.onAddTax,
    required this.onAddDiscount,
    required this.onOtherCharges,
  });

  final String subtotal;
  final String tax;
  final String grandTotal;
  final int itemTypes;
  final int unitCount;
  final VoidCallback onAddTax;
  final VoidCallback onAddDiscount;
  final VoidCallback onOtherCharges;

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: AppColors.ink,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subtotal',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                subtotal,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tax - Not configured',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(
                tax,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFF444444)),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Grand Total',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'TSh$grandTotal',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onAddTax,
                child: const Text('Add Tax', style: linkStyle),
              ),
              const Spacer(),
              Text(
                '$itemTypes Items | $unitCount Units',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: onAddDiscount,
                child: const Text('Add Discount', style: linkStyle),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onOtherCharges,
                child: const Text('Add Other Charges', style: linkStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterActionButton extends StatelessWidget {
  const _FooterActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChargeBar extends StatelessWidget {
  const _ChargeBar({
    required this.totalLabel,
    required this.onTap,
  });

  final String totalLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF68BE69),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          totalLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
