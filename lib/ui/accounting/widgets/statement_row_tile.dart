import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/accounting_model.dart';
import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import 'reconciliation_models.dart';

class StatementRowTile extends StatelessWidget {
  const StatementRowTile({
    super.key,
    required this.entry,
    required this.isSwahili,
  });

  final BankTransaction entry;
  final bool isSwahili;

  String _t(String en, String swahili) => isSwahili ? swahili : en;

  @override
  Widget build(BuildContext context) {
    final inflow = entry.isInflow;
    final amountColor = inflow ? AppColors.success : AppColors.danger;
    final date = entry.date.toLocal().toString().substring(0, 10);
    final desc = entry.description.trim().isNotEmpty
        ? entry.description.trim()
        : entry.accountName;
    final ref = entry.reference.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                color: entry.matched
                    ? AppColors.success
                    : (inflow ? AppColors.warning : AppColors.danger),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [date, if (ref.isNotEmpty) ref, entry.accountName]
                          .join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: Text(
                  '${inflow ? '+' : '-'}${bankReconciliationMoney(entry.amount.abs())}',
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
              ),
              SizedBox(
                width: 74,
                child: Text(
                  entry.matched
                      ? _t('Matched', 'Imeoanishwa')
                      : _t('Open', 'Wazi'),
                  textAlign: TextAlign.right,
                  style: AppTypography.helperText.copyWith(
                    fontWeight: FontWeight.w700,
                    color: entry.matched ? AppColors.success : AppColors.danger,
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
                Text(
                  inflow
                      ? _t('Money in', 'Imeingia')
                      : _t('Money out', 'Imetoka'),
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _toggleMatched(context),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      entry.matched
                          ? _t('Unmatch', 'Ondoa ulinganifu')
                          : _t('Mark matched', 'Weka imeoanishwa'),
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _confirmDelete(context),
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

  Future<void> _toggleMatched(BuildContext context) async {
    if (entry.id == null) return;
    await context
        .read<PosLocalStore>()
        .setBankTransactionMatched(entry.id!, !entry.matched);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (entry.id == null) return;
    final store = context.read<PosLocalStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(_t('Delete line?', 'Futa mstari?')),
        content: Text(
          _t(
            'This statement line will be removed from reconciliation.',
            'Mstari huu wa taarifa utaondolewa kwenye upatanishi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t('Delete', 'Futa')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.deleteBankTransaction(entry.id!);
  }
}
