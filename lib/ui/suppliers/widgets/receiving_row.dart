import 'package:flutter/material.dart';

import '../../../service/supplier_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/quantity_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

class ReceivingRow extends StatelessWidget {
  const ReceivingRow({
    super.key,
    required this.receiving,
    required this.isSwahili,
    required this.onDelete,
  });

  final Receiving receiving;
  final bool isSwahili;
  final VoidCallback onDelete;

  static String formatMoney(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  static String formatReceivingDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final invoicePart = receiving.invoiceNo.trim().isNotEmpty
        ? 'Inv #${receiving.invoiceNo.trim()}'
        : null;
    final totalUnits = roundQuantity(
        receiving.lines.fold<double>(0, (sum, line) => sum + line.quantity));
    final countLabel =
        '${receiving.lines.length} ${isSwahili ? 'vitu' : 'items'} • ${formatQuantity(totalUnits)} ${isSwahili ? 'vipimo' : 'units'}';
    final dateLabel = formatReceivingDate(receiving.date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        receiving.supplierName,
                        style: AppTypography.bodyMain
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (invoicePart != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          border: Border.all(color: AppColors.border),
                          borderRadius: AppCorners.control,
                        ),
                        child: Text(
                          invoicePart,
                          style: AppTypography.helperText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  countLabel,
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  dateLabel,
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(receiving.total),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              IconButton(
                tooltip: isSwahili ? 'Futa' : 'Delete',
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.danger),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReceivingEmptyState extends StatelessWidget {
  const ReceivingEmptyState({
    super.key,
    required this.isSwahili,
    this.isFiltered = false,
    required this.onNew,
    this.onClearFilter,
  });

  final bool isSwahili;
  final bool isFiltered;
  final VoidCallback onNew;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: MarketEmptyState(
          icon: isFiltered
              ? Icons.search_off_rounded
              : Icons.move_to_inbox_rounded,
          title: isFiltered
              ? t('No deliveries match your search',
                  'Hakuna rekodi inayolingana')
              : t('No goods received yet', 'Hakuna bidhaa zilizopokelewa bado'),
          message: isFiltered
              ? t(
                  'Check the invoice number, supplier name, or product name searched.',
                  'Kagua namba ya ankara, jina la msambazaji, au jina la bidhaa.',
                )
              : t(
                  'Record supplier deliveries to automatically update warehouse inventory levels and track cost prices.',
                  'Rekodi usambazaji ili kuongeza idadi ya bidhaa ghalani kiotomatiki na kusasisha bei za ununuzi.',
                ),
          actionLabel: isFiltered
              ? t('Clear search', 'Ondoa utafutaji')
              : t('Record new delivery', 'Pokea bidhaa mpya'),
          actionIcon:
              isFiltered ? Icons.filter_alt_off_rounded : Icons.add_rounded,
          onAction: isFiltered ? onClearFilter : onNew,
        ),
      ),
    );
  }
}
