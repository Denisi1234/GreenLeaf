import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/pos_suspended_sale_model.dart';
import '../business_category_config.dart';
import '../models/product_item.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';
import '../more/create_customer_page.dart';
import '../receipt/receipt_success_page.dart';
import '../widgets/market_shared_widgets.dart';
import '../more/customers_page.dart';
import 'record_debit_bottom_sheet.dart';
import '../../utils/currency_formatter.dart';
import '../../service/app_notification_service.dart';
import 'widgets/line_discount_dialog.dart';
import 'widgets/order_lines_list.dart';
import 'widgets/payment_cash_received_sheet.dart';
import 'widgets/payment_discount_sheet.dart';
import 'widgets/payment_totals_summary_panel.dart';

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
  String _paymentMethod = 'Cash';
  final List<SplitPaymentEntry> _splitPayments = [];
  bool _savingSale = false;
  bool _saleCompleted = false;

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
  double get _appliedDiscount => _discountAmount.clamp(0, _subtotal);
  double get _grandTotal =>
      (_subtotal + _tax - _appliedDiscount).clamp(0, double.infinity);
  double get _totalSplitPaid =>
      _splitPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
  double get _remainingDue =>
      (_grandTotal - _totalSplitPaid).clamp(0, double.infinity);
  double get _changeDue =>
      (_cashReceived != null && _cashReceived! > _grandTotal)
          ? _cashReceived! - _grandTotal
          : 0;
  int get _itemTypes => _orderLines.length;
  int get _unitCount => _orderLines.fold(0, (sum, line) => sum + line.quantity);
  bool get _hasItems => _orderLines.isNotEmpty;
  BusinessCategoryConfig get _config =>
      context.read<PosLocalStore>().businessCategoryConfig;
  String get _paymentTitle => 'Counter';
  String get _paymentSubtitle =>
      'Manage the cart, discounts, and payment with ease.';

  String _amount(double value) => formatCurrency(value);

  void _increaseQuantity(OrderLineItem line) {
    if (_savingSale) return;
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
    if (_savingSale) return;
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

  Future<void> _editLineDiscount(OrderLineItem line) async {
    if (_savingSale) return;
    final updated = await LineDiscountDialog.show(context, line);
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _clearCart() async {
    if (_savingSale || !_hasItems) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear current sale?'),
        content: Text(
            'Remove all $_unitCount units and reset the payment details for this sale?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep sale')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.dangerDeep),
              child: const Text('Clear sale')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<PosLocalStore>().clearCart();
    if (!mounted) return;
    setState(() {
      _orderLines.clear();
      _discountAmount = 0;
      _discountLabel = null;
      _cashReceived = null;
      _selectedCustomer = null;
      _paymentMethod = 'Cash';
    });
  }

  Future<void> _chooseCustomer() async {
    final create = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Select existing customer'),
              subtitle: const Text('Find a customer already in your records'),
              onTap: () => Navigator.pop(context, false)),
          ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title: const Text('Create new customer'),
              subtitle: const Text(
                  'Save customer details and attach them to this sale'),
              onTap: () => Navigator.pop(context, true)),
        ]),
      )),
    );
    if (create == null || !mounted) return;
    if (create) {
      await _addCustomer();
    } else {
      await _selectExistingCustomer();
    }
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

    if (customerName != null && mounted) {
      setState(() => _selectedCustomer = customerName);
    }
    return customerName;
  }

  Future<void> _applyDiscount() async {
    final category =
        context.read<PosLocalStore>().businessCategoryConfig.category;
    final result = await PaymentDiscountSheet.show(
      context,
      subtotal: _subtotal,
      currentAmount: _discountAmount,
      category: category,
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
    final result = await PaymentCashReceivedSheet.show(
      context,
      grandTotal: _grandTotal,
      currentAmount: _cashReceived,
      category: category,
    );

    if (result != null && mounted) {
      setState(() {
        _cashReceived = result;
      });
    }
  }

  Future<void> _recordDebit() async {
    if (_savingSale || !_hasItems) return;
    final customer = _selectedCustomer ?? await _selectExistingCustomer();

    if (customer == null || !mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordDebitBottomSheet(
        customerName: customer,
        total: _grandTotal,
        currentBalance: context
                .read<PosLocalStore>()
                .customerByName(customer)
                ?.debitBalance ??
            0,
      ),
    );

    if (confirmed == true && mounted) {
      _completeSale(customerName: customer, paymentMethod: 'Credit');
    }
  }

  Future<void> _addSplitPayment(String method, double amount) async {
    if (amount <= 0) return;
    setState(() {
      _splitPayments.add(SplitPaymentEntry(method: method, amount: amount));
    });
  }

  void _removeSplitPayment(int index) {
    setState(() {
      _splitPayments.removeAt(index);
    });
  }

  Future<void> _confirmPayment() async {
    if (_savingSale || !_hasItems) return;
    if (_splitPayments.isNotEmpty) {
      if (_remainingDue > 0) {
        showMarketNotice(
          context,
          title: 'Remaining Balance',
          message: 'Please add payment for remaining TSh${_amount(_remainingDue)}',
          type: MarketNoticeType.warning,
        );
        return;
      }
      final methodsSummary = _splitPayments.map((p) => '${p.method} (${_amount(p.amount)})').join(' + ');
      await _completeSale(paymentMethod: 'Split: $methodsSummary');
      return;
    }
    if (_paymentMethod == 'Cash' && _cashReceived == null) {
      await _enterCashReceived();
      if (!mounted || _cashReceived == null) return;
    }
    await _completeSale(paymentMethod: _paymentMethod);
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
    if (_savingSale || _saleCompleted) return;
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

    setState(() => _savingSale = true);
    try {
      final store = context.read<PosLocalStore>();
      final profile = store.profile;
      final cashierName =
          profile.ownerName.isEmpty ? 'Cashier' : profile.ownerName;
      final registerName = store.openShift?.register ?? 'POS-01';
      final completedOrder = await store.completeCashSale(
        items: _orderLines,
        cashTendered: paymentMethod == 'Cash' ? tendered : 0,
        cashierName: cashierName,
        registerName: registerName,
        customerName: customerName ?? _selectedCustomer,
        discountAmount: _appliedDiscount > 0 ? _appliedDiscount : null,
        discountLabel: _discountAmount > 0 ? _discountLabel : null,
        paymentMethod: paymentMethod,
      );

      _saleCompleted = true;
      // A notification failure must not turn a saved sale into a retry.
      unawaited(AppNotificationService.instance
          .showSaleNotification(
            receiptNo: completedOrder.receiptNo,
            totalAmount: completedOrder.total,
            currency: profile.currency.isNotEmpty ? profile.currency : 'TSh',
          )
          .catchError((Object _) {}));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => ReceiptSuccessPage(order: completedOrder),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Sale Could Not Complete',
        message: error is StateError
            ? error.message.toString()
            : 'The sale could not be saved. Please try again.',
        type: MarketNoticeType.warning,
      );
    } finally {
      if (mounted && !_saleCompleted) setState(() => _savingSale = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<PosLocalStore>().businessCategoryConfig;
    final totals = PaymentTotalsSummaryPanel(
      category: config.category,
      subtotal: _amount(_subtotal),
      tax: _amount(_tax),
      discount: _appliedDiscount > 0 ? _amount(_appliedDiscount) : null,
      grandTotal: _amount(_grandTotal),
      cashReceived: _paymentMethod == 'Cash' && _cashReceived != null
          ? _amount(_cashReceived!)
          : null,
      changeDue: _paymentMethod == 'Cash' && _cashReceived != null
          ? _amount(_changeDue)
          : null,
      itemTypes: _itemTypes,
      unitCount: _unitCount,
      onEnterCash: _enterCashReceived,
      onAddDiscount: _applyDiscount,
      onRecordDebit: _recordDebit,
      paymentMethod: _paymentMethod,
      onMethodChanged: (method) => setState(() => _paymentMethod = method),
      onExactCash: () => setState(() => _cashReceived = _grandTotal),
      onRemoveDiscount: () => setState(() {
        _discountAmount = 0;
        _discountLabel = null;
      }),
      splitPayments: _splitPayments,
      remainingDue: _remainingDue,
      onAddSplit: (method, amount) => _addSplitPayment(method, amount),
      onRemoveSplit: (index) => _removeSplitPayment(index),
    );
    final charge = FilledButton.icon(
      key: const ValueKey('complete-sale'),
      onPressed:
          !_hasItems || _savingSale || _saleCompleted ? null : _confirmPayment,
      style: FilledButton.styleFrom(
          backgroundColor: AppColors.successDeep,
          minimumSize: const Size(double.infinity, 54)),
      icon: _savingSale
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_circle_outline_rounded, size: 21),
      label: Text(_savingSale
          ? 'Saving sale…'
          : 'Complete sale • TSh ${_amount(_grandTotal)}'),
    );
    final customer = WorkspacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Customer', style: AppTypography.label),
          const SizedBox(height: 3),
          Text(_selectedCustomer ?? 'Walk-in customer',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700)),
        ])),
        if (_selectedCustomer != null)
          IconButton(
            tooltip: 'Remove customer',
            onPressed: _savingSale
                ? null
                : () => setState(() => _selectedCustomer = null),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        TextButton(
            onPressed: _savingSale ? null : _chooseCustomer,
            child: Text(_selectedCustomer == null ? 'Select' : 'Change')),
      ]),
    );
    final cart = WorkspacePanel(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                  child:
                      Text('Current sale', style: AppTypography.sectionHeader)),
              Text('$_itemTypes items • $_unitCount units',
                  style: AppTypography.label),
            ])),
        const Divider(height: 1),
        OrderLinesList(
          orderLines: _orderLines,
          hasItems: _hasItems,
          onIncrease: _increaseQuantity,
          onDecrease: _decreaseQuantity,
          onEditDiscount: _editLineDiscount,
        ),
        Padding(
            padding: const EdgeInsets.all(12),
            child: _CounterActionRow(onAddItem: () {
              if (!_savingSale) Navigator.of(context).pop();
            })),
      ]),
    );
    final clear = Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _hasItems && !_savingSale ? _clearCart : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.dangerDeep),
          icon: const Icon(Icons.delete_sweep_outlined, size: 19),
          label: Text(_clearLabel(config.category)),
        ));
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: PopScope(
          canPop: !_savingSale,
          child: Stack(
            children: [
              SafeArea(
                  child: Column(children: [
                MarketPageHeader(
                  title: _paymentTitle,
                  subtitle: _paymentSubtitle,
                  onBack: () {
                    if (!_savingSale) Navigator.of(context).pop();
                  },
                  showBackButton: true,
                  centerTitle: false,
                ),
                Expanded(child: LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth >= 1000) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: ListView(children: [
                              cart,
                              const SizedBox(height: 8),
                              clear
                            ])),
                            const SizedBox(width: 24),
                            SizedBox(
                                width: 370,
                                child: Column(children: [
                                  Expanded(
                                      child: ListView(children: [
                                    customer,
                                    const SizedBox(height: 16),
                                    WorkspacePanel(
                                        padding: const EdgeInsets.all(8),
                                        child: AbsorbPointer(
                                            absorbing: _savingSale, child: totals)),
                                  ])),
                                  const SizedBox(height: 16),
                                  charge,
                                ])),
                          ]),
                    );
                  }
                  return Column(children: [
                    Expanded(
                        child:
                            ListView(padding: const EdgeInsets.all(16), children: [
                      customer,
                      const SizedBox(height: 16),
                      cart,
                      const SizedBox(height: 16),
                      WorkspacePanel(
                          padding: const EdgeInsets.all(4),
                          child:
                              AbsorbPointer(absorbing: _savingSale, child: totals)),
                      const SizedBox(height: 8),
                      clear,
                    ])),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(top: BorderSide(color: AppColors.border))),
                      child: charge,
                    ),
                  ]);
                })),
              ])),
              if (_savingSale)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const MarketLoadingView(
                    message: 'Processing Transaction…',
                    subMessage: 'Finalizing invoice, adjusting stock, and logging payment',
                    color: AppColors.successDeep,
                  ),
                ),
            ],
          )),
    );
  }
}

String _clearLabel(BusinessCategory category) => 'Clear';

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
              color: AppColors.surface,
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











