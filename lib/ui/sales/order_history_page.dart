import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<_OrderHistoryItem> get _orders =>
      context.watch<PosLocalStore>().orders
          .map(
            (o) => _OrderHistoryItem(
              id: '#${o.id}',
              dateTime: '${o.date} • ${o.time}',
              amount: 'TSH ${o.total.toStringAsFixed(0)}',
              status: o.status,
              statusColor: const Color(0xFF2FA45B),
              statusBg: const Color(0xFFEAF8EE),
              accentColor: const Color(0xFF2B6FF3),
              customerName: o.cashierName,
              customerPhone: '',
              paymentMethod: o.paymentMethod,
              paidAmount: 'TSH ${o.cashTendered.toStringAsFixed(0)}',
              isExpanded: false,
              lines: o.lines
                  .map(
                    (l) => _OrderLine(
                      l.itemName,
                      l.quantity,
                      'TSH ${l.unitPriceValue.toStringAsFixed(0)}',
                      'TSH ${l.lineTotal.toStringAsFixed(0)}',
                    ),
                  )
                  .toList(),
              subtotal: 'TSH ${o.total.toStringAsFixed(0)}',
              tax: 'TSH 0',
              total: 'TSH ${o.total.toStringAsFixed(0)}',
            ),
          )
          .toList();

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: const MarketAppDrawer(selectedItem: 'Sales'),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            Column(
              children: [
                MarketPageHeader(
                  title: 'Order History',
                  showBackButton: false,
                  centerTitle: false,
                  leading: Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: AppColors.ink,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  actions: const [_SalesMetricButton()],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Expanded(child: _OrderSearchBar()),
                            SizedBox(width: 12),
                            _OrderActionChip(
                              label: 'Filter',
                              icon: Icons.filter_alt_outlined,
                            ),
                            SizedBox(width: 10),
                            _OrderActionChip(
                              label: 'Date',
                              icon: Icons.calendar_today_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...orders.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OrderCard(order: order),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSearchBar extends StatelessWidget {
  const _OrderSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: Color(0xFF98A1AF), size: 30),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search orders by ID or customer...',
              style: TextStyle(
                color: Color(0xFFB0B7C3),
                fontSize: 13.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActionChip extends StatelessWidget {
  const _OrderActionChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF202938), size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF202938),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesMetricButton extends StatelessWidget {
  const _SalesMetricButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.bar_chart_rounded,
        color: Color(0xFF202938),
        size: 26,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final _OrderHistoryItem order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDCE7F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: order.accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: order.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        color: Color(0xFF202938),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.dateTime,
                      style: const TextStyle(
                        color: Color(0xFF7E8797),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                order.amount,
                style: const TextStyle(
                  color: Color(0xFF202938),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: order.statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: order.statusColor,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FD),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  order.isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF202938),
                  size: 26,
                ),
              ),
            ],
          ),
          if (order.isExpanded) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE4E8EF)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6FA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF202938),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer',
                                style: TextStyle(
                                  color: Color(0xFF7E8797),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF202938),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.customerPhone!,
                          style: const TextStyle(
                            color: Color(0xFF3F4755),
                            fontSize: 12.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(68, 0, 16, 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        order.customerName!,
                        style: const TextStyle(
                          color: Color(0xFF202938),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E8EF)),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            'ITEM',
                            style: TextStyle(
                              color: Color(0xFF7E8797),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'QTY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF7E8797),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'UNIT PRICE',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Color(0xFF7E8797),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'TOTAL',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Color(0xFF7E8797),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...order.lines!.map(
                    (line) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              line.item,
                              style: const TextStyle(
                                color: Color(0xFF202938),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${line.qty}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF202938),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              line.unitPrice,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF202938),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              line.total,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF202938),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E8EF)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      children: [
                        _AmountRow(label: 'Subtotal', value: order.subtotal!),
                        const SizedBox(height: 6),
                        _AmountRow(label: 'Tax (8.25%)', value: order.tax!),
                        const SizedBox(height: 8),
                        _AmountRow(
                          label: 'Total',
                          value: order.total!,
                          isEmphasis: true,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E8EF)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            color: Color(0xFF2B6FF3),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Method',
                                style: TextStyle(
                                  color: Color(0xFF5D6675),
                                  fontSize: 12.2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.paymentMethod!,
                                style: const TextStyle(
                                  color: Color(0xFF202938),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Paid',
                              style: TextStyle(
                                color: Color(0xFF202938),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.paidAmount!,
                              style: const TextStyle(
                                color: Color(0xFF202938),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF3E4756),
              fontSize: isEmphasis ? 14 : 13,
              fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 28),
        SizedBox(
          width: 82,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF202938),
              fontSize: isEmphasis ? 14 : 13,
              fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderHistoryItem {
  const _OrderHistoryItem({
    required this.id,
    required this.dateTime,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.accentColor,
    this.customerName,
    this.customerPhone,
    this.paymentMethod,
    this.paidAmount,
    this.isExpanded = false,
    this.lines,
    this.subtotal,
    this.tax,
    this.total,
  });

  final String id;
  final String dateTime;
  final String amount;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final Color accentColor;
  final String? customerName;
  final String? customerPhone;
  final String? paymentMethod;
  final String? paidAmount;
  final bool isExpanded;
  final List<_OrderLine>? lines;
  final String? subtotal;
  final String? tax;
  final String? total;
}

class _OrderLine {
  const _OrderLine(this.item, this.qty, this.unitPrice, this.total);

  final String item;
  final int qty;
  final String unitPrice;
  final String total;
}
