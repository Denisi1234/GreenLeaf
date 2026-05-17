import 'dart:math' as math;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../models/product_item.dart';
import '../receipt/receipt_preview_page.dart';
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
  String _tenderedInput = '';

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
  double get _totalDue => _subtotal;
  double get _cashTendered =>
      _tenderedInput.isEmpty ? 0 : double.tryParse(_tenderedInput) ?? 0;
  double get _changeDue => math.max(0, _cashTendered - _totalDue);
  double get _amountRemaining => math.max(0, _totalDue - _cashTendered);
  bool get _hasItems => _orderLines.isNotEmpty;
  bool get _hasEnoughCash => _hasItems && _cashTendered >= _totalDue;

  void _appendKey(String value) {
    setState(() {
      if (value == '.' && _tenderedInput.contains('.')) return;
      if (_tenderedInput == '0' && value != '.') {
        _tenderedInput = value;
        return;
      }
      _tenderedInput += value;
    });
  }

  void _clearLast() {
    if (_tenderedInput.isEmpty) return;
    setState(() {
      _tenderedInput = _tenderedInput.substring(0, _tenderedInput.length - 1);
    });
  }

  void _addAmount(double amount) {
    setState(() {
      final next = _cashTendered + amount;
      _tenderedInput = next.toStringAsFixed(next % 1 == 0 ? 0 : 2);
    });
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
    final didRemove = context.read<PosLocalStore>().removeSingleFromCart(line.product);
    if (!didRemove) return;
    setState(() {
      line.quantity -= 1;
      if (line.quantity <= 0) {
        _orderLines.remove(line);
      }
    });
  }

  Future<void> _confirmPayment() async {
    if (!_hasItems) {
      showMarketNotice(
        context,
        title: 'Cart Is Empty',
        message: 'Add at least one product before confirming payment',
        type: MarketNoticeType.warning,
      );
      return;
    }

    if (!_hasEnoughCash) {
      showMarketNotice(
        context,
        title: 'Payment Incomplete',
        message:
            'Add TSH ${_amountRemaining.toStringAsFixed(0)} more to complete payment',
        type: MarketNoticeType.warning,
      );
      return;
    }

    try {
      final completedOrder = await context.read<PosLocalStore>().completeCashSale(
            items: _orderLines,
            cashTendered: _cashTendered,
            cashierName: 'John Doe',
            registerName: 'POS-01',
          );

      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Payment Confirmed',
        message: 'Cash received for TSH ${completedOrder.total.toStringAsFixed(0)}',
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => ReceiptPreviewPage(order: completedOrder),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF2A3140),
                          size: 28,
                        ),
                      ),
                      const Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Payment',
                              style: TextStyle(
                                color: Color(0xFF2A3140),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Order #12345',
                              style: TextStyle(
                                color: Color(0xFF7C8593),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFF2A3140),
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PaymentSummaryCard(
                          items: _orderLines,
                          subtotal: _subtotal,
                          total: _totalDue,
                          onIncrease: _increaseQuantity,
                          onDecrease: _decreaseQuantity,
                        ),
                        const SizedBox(height: 18),
                        CashTenderedPanel(
                          tendered: _cashTendered,
                          totalDue: _totalDue,
                          onKeyTap: _appendKey,
                          onBackspace: _clearLast,
                          onQuickAdd: _addAmount,
                        ),
                        const SizedBox(height: 12),
                        ChangeDueCard(
                          changeDue: _changeDue,
                          amountRemaining: _amountRemaining,
                          hasEnoughCash: _hasEnoughCash,
                          tendered: _cashTendered,
                          hasItems: _hasItems,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: GestureDetector(
                onTap: _confirmPayment,
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: _hasEnoughCash
                        ? const Color(0xFF255CC5)
                        : const Color(0xFFAEBAD6),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x221D4ED8),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Confirm Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.items,
    required this.subtotal,
    required this.total,
    required this.onIncrease,
    required this.onDecrease,
  });

  final List<OrderLineItem> items;
  final double subtotal;
  final double total;
  final ValueChanged<OrderLineItem> onIncrease;
  final ValueChanged<OrderLineItem> onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F7FF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFF2E6CCE),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Order Summary',
                  style: TextStyle(
                    color: Color(0xFF2A3140),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${items.length} item types',
                style: const TextStyle(
                  color: Color(0xFF2E6CCE),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...items.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: line.product.imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(line.product.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => FittedBox(
                                fit: BoxFit.contain,
                                child: ProductArt(type: line.product.type),
                              ),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.contain,
                            child: ProductArt(type: line.product.type),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.product.name,
                            style: const TextStyle(
                              color: Color(0xFF2A3140),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            line.product.size,
                            style: const TextStyle(
                              color: Color(0xFF7C8593),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QuantityButton(
                                icon: Icons.remove_rounded,
                                onTap: () => onDecrease(line),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '${line.quantity}',
                                  style: const TextStyle(
                                    color: Color(0xFF2A3140),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add_rounded,
                                onTap: () => onIncrease(line),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TSH ${line.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF2A3140),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${line.quantity} x TSH ${line.product.priceValue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF7C8593),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _SummaryRow(label: 'Subtotal', value: subtotal),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFD7DCE3)),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Due',
                  style: TextStyle(
                    color: Color(0xFF2A3140),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'TSH ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF2A3140),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2A3140),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          'TSH ${value.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Color(0xFF2A3140),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
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
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF2A3140)),
      ),
    );
  }
}

class CashTenderedPanel extends StatelessWidget {
  const CashTenderedPanel({
    super.key,
    required this.tendered,
    required this.totalDue,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onQuickAdd,
  });

  final double tendered;
  final double totalDue;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;
  final ValueChanged<double> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '00'],
    ];
    const quickAdd = [10000.0, 20000.0, 50000.0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cash Tendered',
                  style: TextStyle(
                    color: Color(0xFF2A3140),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'TSH ${tendered.toStringAsFixed(0)}',
                style: TextStyle(
                  color: tendered >= totalDue
                      ? const Color(0xFF3E915E)
                      : const Color(0xFFB45309),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: keys.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: row.map((key) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: key == row.last ? 0 : 10),
                              child: NumberPadButton(
                                label: key,
                                onTap: () => onKeyTap(key),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    NumberPadButton(
                      icon: Icons.backspace_outlined,
                      isAccent: true,
                      onTap: onBackspace,
                    ),
                    const SizedBox(height: 8),
                    ...quickAdd.map(
                      (amount) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NumberPadButton(
                          label: '+${amount.toInt()}',
                          isAccent: true,
                          onTap: () => onQuickAdd(amount),
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
    );
  }
}

class NumberPadButton extends StatelessWidget {
  const NumberPadButton({
    super.key,
    this.label,
    this.icon,
    this.isAccent = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool isAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: isAccent ? const Color(0xFFF1FAF3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAccent ? const Color(0xFFE0F1E3) : const Color(0xFFE8EBF0),
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: const Color(0xFF4C9466), size: 24)
              : Text(
                  label!,
                  style: TextStyle(
                    color: isAccent ? const Color(0xFF3E915E) : const Color(0xFF202938),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class ChangeDueCard extends StatelessWidget {
  const ChangeDueCard({
    super.key,
    required this.changeDue,
    required this.amountRemaining,
    required this.hasEnoughCash,
    required this.tendered,
    required this.hasItems,
  });

  final double changeDue;
  final double amountRemaining;
  final bool hasEnoughCash;
  final double tendered;
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    if (!hasItems) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              color: Color(0xFFB45309),
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add items to the order to continue',
                style: TextStyle(
                  color: Color(0xFF2A3140),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isExact = hasEnoughCash && changeDue == 0 && tendered > 0;
    final title = hasEnoughCash
        ? (isExact ? 'Exact Cash' : 'Change Due')
        : 'Amount Remaining';
    final amount = hasEnoughCash ? changeDue : amountRemaining;
    final accent = hasEnoughCash
        ? const Color(0xFF3E915E)
        : const Color(0xFFB45309);
    final iconBg = hasEnoughCash
        ? const Color(0xFFF1FAF3)
        : const Color(0xFFFFF5E8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              hasEnoughCash ? Icons.paid_outlined : Icons.error_outline_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2A3140),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'TSH ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
