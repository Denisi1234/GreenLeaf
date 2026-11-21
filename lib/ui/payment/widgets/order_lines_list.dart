import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import '../../../utils/currency_formatter.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

class OrderLinesList extends StatelessWidget {
  const OrderLinesList({
    super.key,
    required this.orderLines,
    required this.hasItems,
    required this.onIncrease,
    required this.onDecrease,
    this.onEditDiscount,
  });

  final List<OrderLineItem> orderLines;
  final bool hasItems;
  final void Function(OrderLineItem line) onIncrease;
  final void Function(OrderLineItem line) onDecrease;
  final void Function(OrderLineItem line)? onEditDiscount;

  @override
  Widget build(BuildContext context) {
    if (!hasItems) {
      return  MarketSurfaceCard(
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
                context.tr('No items in this counter yet'),
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

    return Column(
      children: [
        for (final line in orderLines)
          _CounterLineTile(
            line: line,
            amountText: formatCurrency(line.totalPrice),
            onIncrease: () => onIncrease(line),
            onDecrease: () => onDecrease(line),
            onEditDiscount:
                onEditDiscount == null ? null : () => onEditDiscount!(line),
          ),
      ],
    );
  }
}

class _CounterLineTile extends StatelessWidget {
  const _CounterLineTile({
    required this.line,
    required this.amountText,
    required this.onIncrease,
    required this.onDecrease,
    this.onEditDiscount,
  });

  final OrderLineItem line;
  final String amountText;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback? onEditDiscount;

  @override
  Widget build(BuildContext context) {
    final hasOverride = line.customPrice != null;
    final hasDiscount = line.discountPercent > 0;

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line.product.name,
            style:
                AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(
          [
            if (line.product.code?.isNotEmpty ?? false) line.product.code!,
            line.product.size
          ].where((part) => part.isNotEmpty).join(' • '),
          style: AppTypography.label,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.tr('TSh {p0} each', args: {'p0': formatCurrency(line.unitPrice)}),
              style: AppTypography.bodySmall.copyWith(
                color: hasOverride ? AppColors.primaryDeep : AppColors.textMuted,
                fontWeight: hasOverride ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '−${line.discountPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.successDeep,
                  ),
                ),
              ),
            if (onEditDiscount != null)
              InkWell(
                onTap: onEditDiscount,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        context.tr('Discount / Price'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    final stepper = _QuantityStepper(
      quantity: line.quantity,
      onDecrease: onDecrease,
      onIncrease: onIncrease,
    );

    final total = Text(
      context.tr('TSh {p0}', args: {'p0': amountText}),
      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 520) {
          return Row(children: [
            Expanded(child: identity),
            const SizedBox(width: 20),
            stepper,
            const SizedBox(width: 20),
            SizedBox(
              width: 140,
              child: Align(alignment: Alignment.centerRight, child: total),
            ),
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          identity,
          const SizedBox(height: 16),
          Row(children: [
            stepper,
            const SizedBox(width: 12),
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: total),
            ),
          ]),
        ]);
      }),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            color: AppColors.textBody,
            backgroundColor: AppColors.surfaceSecondary,
            tooltip: context.tr('Remove one'),
            onTap: onDecrease,
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            color: AppColors.textBody,
            backgroundColor: AppColors.surfaceSecondary,
            tooltip: context.tr('Add one'),
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.color,
    this.backgroundColor,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }
}
