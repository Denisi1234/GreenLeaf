import 'package:track_mauzo/l10n/app_localization.dart';
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
import 'payment_view_model.dart';
import 'record_debit_bottom_sheet.dart';
import '../../utils/currency_formatter.dart';
import '../../service/app_notification_service.dart';
import 'widgets/line_discount_dialog.dart';
import 'widgets/payment_cart_panel.dart';
import 'widgets/payment_customer_selector.dart';
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
  late final PaymentViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = PaymentViewModel(
      store: context.read<PosLocalStore>(),
      initialItems: widget.items,
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  List<OrderLineItem> get _orderLines => _vm.orderLines;
  String? get _selectedCustomer => _vm.selectedCustomer;
  set _selectedCustomer(String? value) => _vm.setCustomer(value);
  double get _discountAmount => _vm.discountAmount;
  set _discountAmount(double value) => _vm.setDiscount(value, _vm.discountLabel);
  String? get _discountLabel => _vm.discountLabel;
  set _discountLabel(String? value) => _vm.setDiscount(_vm.discountAmount, value);
  double? get _cashReceived => _vm.cashReceived;
  set _cashReceived(double? value) => _vm.setCashReceived(value);
  String get _paymentMethod => _vm.paymentMethod;
  set _paymentMethod(String value) => _vm.setPaymentMethod(value);
  List<SplitPaymentEntry> get _splitPayments => _vm.splitPayments;
  bool get _savingSale => _vm.savingSale;
  set _savingSale(bool value) => _vm.setSavingSale(value);
  bool get _saleCompleted => _vm.saleCompleted;
  set _saleCompleted(bool value) {
    if (value) _vm.markSaleCompleted();
  }

  double get _subtotal => _vm.subtotal;
  double get _appliedDiscount => _vm.appliedDiscount;
  double get _tax => _vm.tax;
  double get _grandTotal => _vm.grandTotal;
  double get _remainingDue => _vm.remainingDue;
  double get _changeDue => _vm.changeDue;
  int get _itemTypes => _vm.itemTypes;
  int get _unitCount => _vm.unitCount;
  bool get _hasItems => _vm.hasItems;
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
        title: context.tr('Out Of Stock'),
        message: context.tr('{p0} has no more stock available', args: {'p0': line.product.name}),
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
    if (!context.read<PosLocalStore>().hasPermission('Discounts')) {
      showMarketNotice(
        context,
        title: context.tr('Permission Required'),
        message: context.tr('You do not have permission to apply discounts.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
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
        title:  Text(context.tr('Clear current sale?')),
        content: Text(
            context.tr('Remove all {p0} units and reset the payment details for this sale?', args: {'p0': _unitCount})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:  Text(context.tr('Keep sale'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.dangerDeep),
              child:  Text(context.tr('Clear sale'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<PosLocalStore>().clearCart();
    if (!mounted) return;
    setState(() {
      _vm.clearAll();
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
              title:  Text(context.tr('Select existing customer')),
              subtitle:  Text(context.tr('Find a customer already in your records')),
              onTap: () => Navigator.pop(context, false)),
          ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title:  Text(context.tr('Create new customer')),
              subtitle:  Text(
                  context.tr('Save customer details and attach them to this sale')),
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
    final store = context.read<PosLocalStore>();
    if (!store.hasPermission('Discounts')) {
      showMarketNotice(
        context,
        title: context.tr('Permission Required'),
        message: context.tr('You do not have permission to apply discounts.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    final category = store.businessCategoryConfig.category;
    final result = await PaymentDiscountSheet.show(
      context,
      subtotal: _subtotal,
      currentAmount: _discountAmount,
      category: category,
    );

    if (result != null && mounted) {
      setState(() {
        _vm.setDiscount(result['amount'] as double, result['label'] as String);
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
      _vm.addSplitPayment(SplitPaymentEntry(method: method, amount: amount));
    });
  }

  void _removeSplitPayment(int index) {
    setState(() {
      _vm.removeSplitPaymentAt(index);
    });
  }

  Future<void> _confirmPayment() async {
    if (_savingSale || !_hasItems) return;
    if (_splitPayments.isNotEmpty) {
      if (_remainingDue > 0) {
        showMarketNotice(
          context,
          title: context.tr('Remaining Balance'),
          message: context.tr('Please add payment for remaining TSh{p0}', args: {'p0': _amount(_remainingDue)}),
          type: MarketNoticeType.warning,
        );
        return;
      }
      final methodsSummary = _splitPayments.map((p) => '${p.method} (${_amount(p.amount)})').join(' + ');
      await _completeSale(paymentMethod: 'Split: $methodsSummary');
      return;
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
        title: context.tr('Stock Changed'),
        message:
            context.tr('Only {p0} unit(s) of {p1} are left. Reduce the quantity before charging.', args: {'p0': availableStock, 'p1': line.product.name}),
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
        title: context.tr('Cart Is Empty'),
        message: context.tr('Add at least one product before charging this order'),
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
        title: context.tr('Insufficient Cash'),
        message: context.tr('Cash received must be at least TSh{p0}', args: {'p0': _amount(_grandTotal)}),
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
    } catch (error, stackTrace) {
      debugPrint('Sale save error: $error\n$stackTrace');
      if (!mounted) return;
      showMarketNotice(
        context,
        title: context.tr('Sale Could Not Complete'),
        message: error is StateError
            ? error.message.toString()
            : '${context.tr('The sale could not be saved.')} ($error)',
        type: MarketNoticeType.warning,
      );
    } finally {
      if (mounted && !_saleCompleted) setState(() => _savingSale = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final canDiscount = store.hasPermission('Discounts');
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
      onAddDiscount: canDiscount ? _applyDiscount : null,
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
        minimumSize: const Size(double.infinity, 54),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      icon: _savingSale
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_circle_outline_rounded, size: 21),
      label: Text(_savingSale
          ? context.tr('Saving sale…')
          : context.tr('Complete sale • TSh {p0}', args: {'p0': _amount(_grandTotal)})),
    );
    final customer = PaymentCustomerSelector(
      selectedCustomer: _selectedCustomer,
      savingSale: _savingSale,
      onSelectCustomer: _chooseCustomer,
      onClearCustomer: () => setState(() => _selectedCustomer = null),
    );
    final cart = PaymentCartPanel(
      orderLines: _orderLines,
      hasItems: _hasItems,
      itemTypes: _itemTypes,
      unitCount: _unitCount,
      savingSale: _savingSale,
      onIncrease: _increaseQuantity,
      onDecrease: _decreaseQuantity,
      onEditDiscount: canDiscount ? _editLineDiscount : null,
      onAddItem: () {
        if (!_savingSale) Navigator.of(context).pop();
      },
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
                        child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            children: [
                          customer,
                          const SizedBox(height: 12),
                          cart,
                          const SizedBox(height: 12),
                          Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.zero,
                            child: AbsorbPointer(
                              absorbing: _savingSale,
                              child: totals,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: clear,
                          ),
                        ])),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                              top: BorderSide(color: AppColors.divider))),
                      child: charge,
                    ),
                  ]);
                })),
              ])),
              if (_savingSale)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child:  MarketLoadingView(
                    message: context.tr('Processing Transaction…'),
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
