import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../business_category_config.dart';
import '../models/product_item.dart';
import '../widgets/app_design.dart';
import '../more/create_customer_page.dart';
import '../receipt/receipt_success_page.dart';
import '../widgets/market_shared_widgets.dart';
import '../more/customers_page.dart';
import 'record_debit_bottom_sheet.dart';
import '../../utils/currency_formatter.dart';

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
  String? _selectedCustomer;
  double _discountAmount = 0;
  String? _discountLabel;
  double? _cashReceived;

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
  double get _grandTotal =>
      (_subtotal + _tax - _discountAmount).clamp(0, double.infinity);
  double get _changeDue =>
      (_cashReceived != null && _cashReceived! > _grandTotal)
          ? _cashReceived! - _grandTotal
          : 0;
  int get _itemTypes => _orderLines.length;
  int get _unitCount => _orderLines.fold(0, (sum, line) => sum + line.quantity);
  bool get _hasItems => _orderLines.isNotEmpty;
  BusinessCategoryConfig get _config =>
      context.read<PosLocalStore>().businessCategoryConfig;
  String get _paymentTitle => switch (_config.category) {
        BusinessCategory.pharmacy => 'Dispense Sale',
        BusinessCategory.electronics => 'Counter',
        BusinessCategory.retail => 'Counter',
      };
  String get _paymentSubtitle => switch (_config.category) {
        BusinessCategory.pharmacy =>
          'Keep insurance and prescription context close to the sale.',
        BusinessCategory.electronics =>
          'Manage the cart, discounts, and payment with ease.',
        BusinessCategory.retail =>
          'Manage the cart, discounts, and payment with ease.',
      };

  String _amount(double value) => formatCurrency(value);

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
    setState(() {
      _orderLines.clear();
      _discountAmount = 0;
      _discountLabel = null;
      _cashReceived = null;
    });
  }

  Future<void> _addCustomer() async {
    final customerName = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => const CreateCustomerPage(),
      ),
    );

    if (customerName != null && mounted) {
      setState(() => _selectedCustomer = customerName);
    }
  }

  Future<String?> _selectExistingCustomer() async {
    final customerName = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => const CustomersPage(isSelectionMode: true),
      ),
    );

    if (customerName != null) {
      setState(() => _selectedCustomer = customerName);
    }
    return customerName;
  }

  Future<void> _applyDiscount() async {
    final category =
        context.read<PosLocalStore>().businessCategoryConfig.category;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiscountBottomSheet(
        subtotal: _subtotal,
        currentAmount: _discountAmount,
        category: category,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _discountAmount = result['amount'] as double;
        _discountLabel = result['label'] as String;
      });
    }
  }

  Future<void> _enterCashReceived() async {
    if (!_validateStockBeforeCheckout()) return;
    final category =
        context.read<PosLocalStore>().businessCategoryConfig.category;
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CashReceivedBottomSheet(
        grandTotal: _grandTotal,
        currentAmount: _cashReceived,
        category: category,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _cashReceived = result;
      });
    }
  }

  Future<void> _recordDebit() async {
    final customer = await _selectExistingCustomer();

    if (customer == null || !mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordDebitBottomSheet(
        customerName: customer,
        total: _grandTotal,
      ),
    );

    if (confirmed == true && mounted) {
      _completeSale(customerName: customer, paymentMethod: 'Credit');
    }
  }

  Future<void> _confirmPayment() async {
    _completeSale();
  }

  bool _validateStockBeforeCheckout() {
    final store = context.read<PosLocalStore>();
    final inventoryByCode = <String, int>{};
    final inventoryByIdentity = <String, int>{};

    for (final item in store.inventory) {
      final code = item.code.trim();
      if (code.isNotEmpty) {
        inventoryByCode[code] = item.stockCount;
      } else {
        inventoryByIdentity[item.name.trim()] = item.stockCount;
      }
    }

    for (final line in _orderLines) {
      final code = line.product.code?.trim();
      final stock = code != null && code.isNotEmpty
          ? inventoryByCode[code]
          : inventoryByIdentity[line.product.name.trim()];
      final availableStock = stock ?? 0;
      if (availableStock >= line.quantity) continue;

      showMarketNotice(
        context,
        title: 'Stock Changed',
        message:
            'Only $availableStock unit(s) of ${line.product.name} are left. Reduce the quantity before charging.',
        type: MarketNoticeType.warning,
      );
      return false;
    }

    return true;
  }

  Future<void> _completeSale({
    String? customerName,
    String paymentMethod = 'Cash',
  }) async {
    if (!_hasItems) {
      showMarketNotice(
        context,
        title: 'Cart Is Empty',
        message: 'Add at least one product before charging this order',
        type: MarketNoticeType.warning,
      );
      return;
    }

    if (!_validateStockBeforeCheckout()) {
      return;
    }

    final tendered = _cashReceived ?? _grandTotal;
    if (paymentMethod == 'Cash' && tendered < _grandTotal) {
      showMarketNotice(
        context,
        title: 'Insufficient Cash',
        message: 'Cash received must be at least TSh${_amount(_grandTotal)}',
        type: MarketNoticeType.warning,
      );
      return;
    }

    try {
      final profile = context.read<PosLocalStore>().profile;
      final cashierName =
          profile.ownerName.isEmpty ? 'Cashier' : profile.ownerName;
      final completedOrder =
          await context.read<PosLocalStore>().completeCashSale(
                items: _orderLines,
                cashTendered: paymentMethod == 'Cash' ? tendered : 0,
                cashierName: cashierName,
                registerName: 'POS-01',
                customerName: customerName ?? _selectedCustomer,
                discountAmount: _discountAmount > 0 ? _discountAmount : null,
                discountLabel: _discountAmount > 0 ? _discountLabel : null,
                paymentMethod: paymentMethod,
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

  @override
  Widget build(BuildContext context) {
    final config = context.watch<PosLocalStore>().businessCategoryConfig;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: _paymentTitle,
              subtitle: _paymentSubtitle,
              onBack: () => Navigator.of(context).pop(),
              showBackButton: true,
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: _addCustomer,
                  icon: Icon(
                    switch (config.category) {
                      BusinessCategory.pharmacy => Icons.badge_outlined,
                      BusinessCategory.electronics => Icons.person_outline,
                      BusinessCategory.retail => Icons.group_add_outlined,
                    },
                    color: AppColors.ink,
                    size: 26,
                  ),
                ),
              ],
            ),
            if (_selectedCustomer != null)
              Container(
                color: const Color(0xFFE8F4FF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 18, color: Color(0xFF2B5FCE)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Customer: $_selectedCustomer',
                        style: const TextStyle(
                          color: Color(0xFF2B5FCE),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedCustomer = null),
                      child: const Icon(Icons.close,
                          size: 18, color: Color(0xFF2B5FCE)),
                    ),
                  ],
                ),
              ),
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
                  ),
                  const SizedBox(height: 6),
                  _TotalsPanel(
                    category: config.category,
                    subtotal: _amount(_subtotal),
                    tax: _amount(_tax),
                    discount:
                        _discountAmount > 0 ? _amount(_discountAmount) : null,
                    grandTotal: _amount(_grandTotal),
                    cashReceived:
                        _cashReceived != null ? _amount(_cashReceived!) : null,
                    changeDue:
                        _cashReceived != null ? _amount(_changeDue) : null,
                    itemTypes: _itemTypes,
                    unitCount: _unitCount,
                    onEnterCash: _enterCashReceived,
                    onAddDiscount: _applyDiscount,
                    onRecordDebit: _recordDebit,
                  ),
                  const SizedBox(height: 12),
                  _FooterActionButton(
                    label: _clearLabel(config.category),
                    color: const Color(0xFFE66C73),
                    onTap: _clearCart,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: _ChargeBar(
                totalLabel: _chargeLabel(config.category, _amount(_grandTotal)),
                onTap: _confirmPayment,
                accentColor: config.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _chargeLabel(BusinessCategory category, String amount) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Charge Sale: TSh$amount',
    BusinessCategory.electronics => 'Charge: TSh$amount',
    BusinessCategory.retail => 'Charge: TSh$amount',
  };
}

String _clearLabel(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Clear Basket',
    BusinessCategory.electronics => 'Clear',
    BusinessCategory.retail => 'Clear',
  };
}

String _discountLabelFor(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Discount',
    BusinessCategory.electronics => 'Discount',
    BusinessCategory.retail => 'Discount',
  };
}

String _cashReceivedLabelFor(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Cash / Insurance',
    BusinessCategory.electronics => 'Cash Received',
    BusinessCategory.retail => 'Cash Received',
  };
}

String _secondaryPaymentAction(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Apply Discount',
    BusinessCategory.electronics => 'Add Discount',
    BusinessCategory.retail => 'Add Discount',
  };
}

String _tertiaryPaymentAction(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Record Debit',
    BusinessCategory.electronics => 'Record Debit',
    BusinessCategory.retail => 'Record Debit',
  };
}

String _totalsSummaryLabel(
  BusinessCategory category,
  int itemTypes,
  int unitCount,
) {
  final base = '$itemTypes Items | $unitCount Units';
  return switch (category) {
    BusinessCategory.pharmacy => '$base | Pharmacy Sale',
    BusinessCategory.electronics => base,
    BusinessCategory.retail => base,
  };
}

String _confirmLabel(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Confirm',
    BusinessCategory.electronics => 'Done',
    BusinessCategory.retail => 'Done',
  };
}

String _applyLabel(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => 'Apply',
    BusinessCategory.electronics => 'Apply',
    BusinessCategory.retail => 'Apply',
  };
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
                child: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDecrease,
                child: const Icon(
                  Icons.remove_circle_outline,
                  color: Color(0xFFE66C73),
                  size: 20,
                ),
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
    return const MarketSurfaceCard(
      padding: EdgeInsets.all(24),
      child: SizedBox(
        height: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }
}

class _CounterActionRow extends StatelessWidget {
  const _CounterActionRow({
    required this.onAddItem,
  });

  final VoidCallback onAddItem;

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
      ],
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({
    required this.category,
    required this.subtotal,
    required this.tax,
    this.discount,
    required this.grandTotal,
    this.cashReceived,
    this.changeDue,
    required this.itemTypes,
    required this.unitCount,
    required this.onEnterCash,
    required this.onAddDiscount,
    required this.onRecordDebit,
  });

  final BusinessCategory category;
  final String subtotal;
  final String tax;
  final String? discount;
  final String grandTotal;
  final String? cashReceived;
  final String? changeDue;
  final int itemTypes;
  final int unitCount;
  final VoidCallback onEnterCash;
  final VoidCallback onAddDiscount;
  final VoidCallback onRecordDebit;

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: AppColors.ink,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
    );

    return MarketSurfaceCard(
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
          if (discount != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _discountLabelFor(category),
                    style: const TextStyle(
                      color: Color(0xFFE66C73),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '- $discount',
                  style: const TextStyle(
                    color: Color(0xFFE66C73),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
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
          if (cashReceived != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cash Received',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'TSh $cashReceived',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Change Due',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'TSh $changeDue',
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onEnterCash,
                child: Text(_cashReceivedLabelFor(category), style: linkStyle),
              ),
              const Spacer(),
              Text(
                _totalsSummaryLabel(category, itemTypes, unitCount),
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
                child:
                    Text(_secondaryPaymentAction(category), style: linkStyle),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRecordDebit,
                child: Text(_tertiaryPaymentAction(category), style: linkStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashReceivedBottomSheet extends StatefulWidget {
  const _CashReceivedBottomSheet({
    required this.grandTotal,
    required this.category,
    this.currentAmount,
  });

  final double grandTotal;
  final BusinessCategory category;
  final double? currentAmount;

  @override
  State<_CashReceivedBottomSheet> createState() =>
      _CashReceivedBottomSheetState();
}

class _CashReceivedBottomSheetState extends State<_CashReceivedBottomSheet> {
  late final TextEditingController _controller;
  double _currentInput = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentAmount != null
          ? widget.currentAmount!.round().toString()
          : '',
    );
    _currentInput = widget.currentAmount ?? 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) => formatCurrency(value);

  @override
  Widget build(BuildContext context) {
    final changeDue = (_currentInput > widget.grandTotal)
        ? _currentInput - widget.grandTotal
        : 0.0;
    final isInsufficient =
        _currentInput > 0 && _currentInput < widget.grandTotal;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _cashReceivedLabelFor(widget.category),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: (val) => setState(() {
              _currentInput = double.tryParse(val) ?? 0;
            }),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              prefixText: 'TSh ',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _SummaryRow(
                label: 'Total',
                value: 'TSh ${_format(widget.grandTotal)}',
                valueColor: AppColors.ink,
              ),
              const Spacer(),
              _SummaryRow(
                label: isInsufficient ? 'Remaining' : 'Change',
                value:
                    'TSh ${_format(isInsufficient ? (widget.grandTotal - _currentInput) : changeDue)}',
                valueColor: isInsufficient
                    ? const Color(0xFFE11D48)
                    : const Color(0xFF15803D),
                isBold: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _currentInput >= widget.grandTotal
                ? () {
                    Navigator.of(context).pop(_currentInput);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _confirmLabel(widget.category),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
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
    this.accentColor = const Color(0xFFE54040),
  });

  final String totalLabel;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          totalLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DiscountBottomSheet extends StatefulWidget {
  const _DiscountBottomSheet({
    required this.subtotal,
    required this.currentAmount,
    required this.category,
  });

  final double subtotal;
  final double currentAmount;
  final BusinessCategory category;

  @override
  State<_DiscountBottomSheet> createState() => _DiscountBottomSheetState();
}

class _DiscountBottomSheetState extends State<_DiscountBottomSheet> {
  late final TextEditingController _controller;
  bool _isPercentage = false;
  double _currentInput = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentAmount > 0
          ? widget.currentAmount.round().toString()
          : '',
    );
    _currentInput = widget.currentAmount;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) => formatCurrency(value);

  @override
  Widget build(BuildContext context) {
    final calculatedDiscount =
        _isPercentage ? (widget.subtotal * _currentInput / 100) : _currentInput;

    final finalDiscount = calculatedDiscount.clamp(0.0, widget.subtotal);
    final revisedTotal =
        (widget.subtotal - finalDiscount).clamp(0.0, double.infinity);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _discountLabelFor(widget.category),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _DiscountModeTab(
                      label: 'TSh',
                      isSelected: !_isPercentage,
                      onTap: () => setState(() => _isPercentage = false),
                    ),
                    _DiscountModeTab(
                      label: '%',
                      isSelected: _isPercentage,
                      onTap: () => setState(() => _isPercentage = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: (val) => setState(() {
              _currentInput = double.tryParse(val) ?? 0;
            }),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText: '0',
              prefixText: _isPercentage ? null : 'TSh ',
              suffixText: _isPercentage ? '%' : null,
              hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.1)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _SummaryRow(
                label: 'Savings',
                value: '- TSh ${_format(finalDiscount)}',
                valueColor: const Color(0xFFE11D48),
              ),
              const Spacer(),
              _SummaryRow(
                label: 'Total',
                value: 'TSh ${_format(revisedTotal)}',
                valueColor: AppColors.ink,
                isBold: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'amount': finalDiscount,
                'label': _isPercentage
                    ? '${_currentInput.round()}% Discount'
                    : 'Discount',
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _applyLabel(widget.category),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DiscountModeTab extends StatelessWidget {
  const _DiscountModeTab({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD7DDEA) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color:
                isSelected ? const Color(0xFF1F2937) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
