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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final query = _searchQuery.trim().toLowerCase();
    final filteredOrders = orders.where((order) {
      if (query.isEmpty) return true;
      final searchableValues = <String>[
        order.id,
        order.dateTime,
        order.amount,
        order.status,
        order.customerName ?? '',
        order.paymentMethod ?? '',
        order.paidAmount ?? '',
      ];
      return searchableValues.any(
        (value) => value.toLowerCase().contains(query),
      );
    }).toList();
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
                        Row(
                          children: [
                            Expanded(
                              child: MarketSearchField(
                                controller: _searchController,
                                hintText:
                                    'Search orders by ID, cashier, or payment',
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                onClear: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                                onScanTap: () {
                                  showMarketNotice(
                                    context,
                                    title: 'Order Scanner',
                                    message: 'Scan receipt QR/Barcode to find order',
                                  );
                                },
                                height: 60,
                                radius: 30,
                                backgroundColor: Colors.white,
                                borderColor: const Color(0xFFF1F5F9),
                                showShadow: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const _OrderActionChip(
                              label: 'Filter',
                              icon: Icons.filter_alt_outlined,
                            ),
                            const SizedBox(width: 10),
                            const _OrderActionChip(
                              label: 'Date',
                              icon: Icons.calendar_today_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (filteredOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: MarketSurfaceCard(
                              borderColor: Color(0xFFE3E7ED),
                              radius: 4,
                              padding: EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    color: Color(0xFF98A1AF),
                                    size: 28,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No matching orders',
                                    style: TextStyle(
                                      color: Color(0xFF202938),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Try a different order ID, cashier name, or payment method.',
                                    style: TextStyle(
                                      color: Color(0xFF7E8797),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filteredOrders.map(
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
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppRadius.standard),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textMain, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.label.copyWith(color: AppColors.textMain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesMetricButton extends StatelessWidget {
  const _SalesMetricButton();

  @override
  Widget build(BuildContext context) {
    return HeaderActionButton(
      icon: Icons.bar_chart_rounded,
      background: AppColors.surface,
      foreground: AppColors.textMain,
      borderColor: AppColors.border,
      onTap: () {},
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order});

  final _OrderHistoryItem order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppRadius.standard),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sharp),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.id,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.dateTime,
                            style: AppTypography.helperText.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order.amount,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            order.status,
                            style: AppTypography.helperText.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textLight,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Cashier: ',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      Text(
                        order.customerName ?? 'N/A',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _TableDivider(),
                  const SizedBox(height: AppSpacing.md),
                  ...order.lines!.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(line.item, style: AppTypography.bodySmall),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('x${line.qty}', textAlign: TextAlign.center, style: AppTypography.bodySmall),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(line.total, textAlign: TextAlign.right, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: AppSpacing.md),
                  const _TableDivider(),
                  const SizedBox(height: AppSpacing.md),
                  _AmountRow(label: 'Subtotal', value: order.subtotal!),
                  const SizedBox(height: 4),
                  _AmountRow(label: 'Total', value: order.total!, isEmphasis: true),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.sharp),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Paid via ${order.paymentMethod}',
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          order.paidAmount ?? '',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800),
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

class _TableDivider extends StatelessWidget {
  const _TableDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.borderLight,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isEmphasis
              ? AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800)
              : AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        Text(
          value,
          style: isEmphasis
              ? AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)
              : AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
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
