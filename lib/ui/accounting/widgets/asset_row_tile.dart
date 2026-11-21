import 'package:flutter/material.dart';

import '../../../service/accounting_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';

class AssetRowTile extends StatelessWidget {
  const AssetRowTile({
    super.key,
    required this.asset,
    required this.isSwahili,
    required this.onEdit,
    required this.onDelete,
  });

  final FixedAsset asset;
  final bool isSwahili;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _t(String en, String swahili) => isSwahili ? swahili : en;

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final dep = asset.accumulatedDepreciation();
    final nbv = asset.netBookValue();
    final fullyDep = nbv <= 0.01 && asset.cost > 0;
    final date = asset.purchaseDate.toLocal().toString().substring(0, 10);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 42,
                color: fullyDep ? AppColors.textMuted : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (asset.category.trim().isNotEmpty)
                          asset.category.trim(),
                        date,
                      ].join(' • '),
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _money(asset.cost),
                  textAlign: TextAlign.right,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _money(nbv),
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        fullyDep ? AppColors.textMuted : AppColors.successDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_t('Depreciation', 'Uchakavu')}: ${_money(dep)} • ${_t('Life', 'Muda')}: ${asset.usefulLifeYears} ${_t('yrs', 'miaka')}',
                    style: AppTypography.helperText
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
                InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      _t('Edit', 'Hariri'),
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      _t('Delete', 'Futa'),
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
