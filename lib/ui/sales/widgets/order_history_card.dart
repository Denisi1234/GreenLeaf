import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_localization.dart';
import '../../../service/pos_local_store.dart';
import '../../../service/pos_order_models.dart';
import '../../receipt/receipt_preview_page.dart';
import '../../widgets/app_design.dart';
import '../../widgets/common/header_action_button.dart';
import '../../widgets/common/market_notice.dart';
class OrderActionChip extends StatelessWidget {
  const OrderActionChip({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tint = active ? AppColors.primary : AppColors.textMain;
    return Container(
      width: 76,
      height: 56,
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: tint, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: tint,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesMetricButton extends StatelessWidget {
  const SalesMetricButton({super.key});

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

class OrderCard extends StatefulWidget {
  const OrderCard({super.key, required this.order});

  final OrderHistoryItem order;

  @override
  State<OrderCard> createState() => OrderCardState();
}

class OrderCardState extends State<OrderCard> {
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
                        color: AppColors.surfaceSecondary,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                      const Icon(Icons.person_outline_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        context.tr('Cashier: '),
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                      Text(
                        order.customerName ?? 'N/A',
                        style: AppTypography.bodySmall
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const OrderTableDivider(),
                  const SizedBox(height: AppSpacing.md),
                  ...order.lines!.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(line.item,
                                  style: AppTypography.bodySmall),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(line.qty,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(line.total,
                                  textAlign: TextAlign.right,
                                  style: AppTypography.bodySmall
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: AppSpacing.md),
                  const OrderTableDivider(),
                  const SizedBox(height: AppSpacing.md),
                  OrderAmountRow(label: context.tr('Subtotal'), value: order.subtotal!),
                  const SizedBox(height: 4),
                  OrderAmountRow(
                      label: context.tr('Total'), value: order.total!, isEmphasis: true),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.sharp),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.tr('Paid via {p0}', args: {'p0': order.paymentMethod}),
                            style: AppTypography.bodySmall
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          order.paidAmount ?? '',
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (order.completedOrder != null) ...[
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.kpiSkyBg,
                              foregroundColor: AppColors.kpiSky,
                              side: BorderSide.none,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(AppRadius.pill)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.receipt_long_outlined,
                                size: 18),
                            label: Text(
                              context.tr('View / Reprint Receipt'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReceiptPreviewPage(
                                    order: order.completedOrder!,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (order.completedOrder != null &&
                          order.status != 'Voided' &&
                          order.status != 'Returned' &&
                          context
                              .watch<PosLocalStore>()
                              .hasPermission('Process Returns'))
                        const SizedBox(width: 10),
                      if (order.status != 'Voided' &&
                          order.status != 'Returned' &&
                          context
                              .watch<PosLocalStore>()
                              .hasPermission('Process Returns'))
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.kpiDangerBg,
                              foregroundColor: AppColors.kpiDanger,
                              side: BorderSide.none,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(AppRadius.pill)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.assignment_return_outlined,
                                size: 18),
                            label: Text(
                              context.tr('Return / Restock'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            onPressed: () {
                              _showReturnDialog(context, order);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  void _showReturnDialog(BuildContext context, OrderHistoryItem order) {
    if (!context.read<PosLocalStore>().hasPermission('Process Returns')) {
      showMarketNotice(
        context,
        title: context.tr('Permission Required'),
        message: context.tr('You do not have permission to process returns.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    final rawId = order.id.replaceFirst('#', '');
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        bool restock = true;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.modal)),
              ),
              title: Text(context.tr('Process Return {p0}', args: {'p0': order.id})),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Order total: {p0}\nPayment: {p1}', args: {'p0': order.amount, 'p1': order.paymentMethod}),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title:  Text(context.tr('Return items to inventory stock'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: restock,
                    onChanged: (val) => setDialogState(() => restock = val ?? true),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceSecondary,
                    foregroundColor: AppColors.textBody,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRadius.pill)),
                    ),
                  ),
                  child: Text(
                    context.tr('Cancel'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRadius.pill)),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final store = context.read<PosLocalStore>();
                    try {
                      await store.voidOrder(rawId);
                      if (!context.mounted) return;
                      showMarketNotice(
                        context,
                        title: context.tr('Order Returned'),
                        message: context.tr(
                            'Sale {p0} was processed as return.',
                            args: {'p0': order.id}),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      showMarketNotice(
                        context,
                        title: context.tr('Return Failed'),
                        message: e.toString(),
                        type: MarketNoticeType.warning,
                      );
                    }
                  },
                  child: Text(
                    context.tr('Confirm Return'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class OrderTableDivider extends StatelessWidget {
  const OrderTableDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.borderLight,
    );
  }
}

class OrderAmountRow extends StatelessWidget {
  const OrderAmountRow({super.key, 
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
              ? AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.primary)
              : AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class OrderHistoryItem {
  const OrderHistoryItem({
    required this.id,
    required this.dateTime,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.accentColor,
    this.completedOrder,
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
  final CompletedOrder? completedOrder;
  final String? customerName;
  final String? customerPhone;
  final String? paymentMethod;
  final String? paidAmount;
  final bool isExpanded;
  final List<OrderHistoryLine>? lines;
  final String? subtotal;
  final String? tax;
  final String? total;
}

class OrderHistoryLine {
  const OrderHistoryLine(this.item, this.qty, this.unitPrice, this.total);

  final String item;
  final String qty;
  final String unitPrice;
  final String total;
}
