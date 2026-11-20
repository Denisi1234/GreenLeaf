import 'package:flutter/material.dart';

import '../../../service/supplier_model.dart';
import '../../../utils/currency_formatter.dart';
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
    final totalUnits =
        receiving.lines.fold<double>(0, (sum, line) => sum + line.quantity);
    final countLabel =
        '${receiving.lines.length} ${isSwahili ? 'vitu' : 'items'} • ${totalUnits.toStringAsFixed(totalUnits.truncateToDouble() == totalUnits ? 0 : 1)} ${isSwahili ? 'vipande' : 'units'}';
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
                          borderRadius: BorderRadius.zero,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  isFiltered
                      ? Icons.search_off_rounded
                      : Icons.move_to_inbox_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isFiltered
                    ? t('No deliveries match your search', 'Hakuna rekodi inayolingana')
                    : t('No goods received yet', 'Hakuna bidhaa zilizopokelewa bado'),
                textAlign: TextAlign.center,
                style: AppTypography.cardHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltered
                    ? t(
                        'Check the invoice number, supplier name, or product name searched.',
                        'Kagua namba ya ankara, jina la msambazaji, au jina la bidhaa.',
                      )
                    : t(
                        'Record supplier deliveries to automatically update warehouse inventory levels and track cost prices.',
                        'Rekodi usambazaji ili kuongeza idadi ya bidhaa ghalani kiotomatiki na kusasisha bei za ununuzi.',
                      ),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (isFiltered)
                MarketButton(
                  label: t('Clear search', 'Ondoa utafutaji'),
                  icon: Icons.filter_alt_off_rounded,
                  isFullWidth: false,
                  isPrimary: false,
                  onTap: onClearFilter,
                )
              else
                MarketButton(
                  label: t('Record new delivery', 'Pokea bidhaa mpya'),
                  icon: Icons.add_rounded,
                  isFullWidth: false,
                  onTap: onNew,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
