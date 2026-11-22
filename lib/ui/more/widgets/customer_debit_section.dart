import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/debit_entry_model.dart';
import '../../../service/debit_statement_service.dart';
import '../../../service/pos_local_store.dart';
import '../../models/customer_data.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../record_payment_sheet.dart';
import 'customer_detail_models.dart';

class CustomerDebitSection extends StatelessWidget {
  const CustomerDebitSection({
    super.key,
    required this.customer,
    required this.entries,
    required this.strings,
  });

  final CustomerData customer;
  final List<DebitEntry> entries;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final charges = entries
        .where((entry) => !entry.isPayment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final paid = entries
        .where((entry) => entry.isPayment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final recent = entries.take(4).toList();
    final hasDebt = customer.debitBalance > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasDebt
                        ? Icons.account_balance_wallet_outlined
                        : Icons.verified_rounded,
                    color: hasDebt ? AppColors.kpiDanger : AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasDebt
                          ? customerDual(
                              strings, 'Outstanding credit', 'Deni la mteja')
                          : customerDual(
                              strings, 'Account settled', 'Deni limekamilika'),
                      style: AppTypography.bodySmall.copyWith(
                        color: hasDebt ? AppColors.ink : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (hasDebt) ...[
                    CustomerDebitAction(
                      label: customerDual(
                          strings, 'Statement (PDF)', 'Taarifa (PDF)'),
                      icon: Icons.picture_as_pdf_rounded,
                      color: AppColors.kpiVioletBg,
                      foregroundColor: AppColors.kpiViolet,
                      onTap: () => _shareStatement(context),
                    ),
                    const SizedBox(width: 6),
                    CustomerDebitAction(
                      label: customerDual(strings, 'Receive', 'Pokea'),
                      icon: Icons.payments_rounded,
                      color: AppColors.primary,
                      onTap: () => _receive(context),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                formatCustomerMoney(customer.debitBalance),
                style: AppTypography.h2.copyWith(
                  color: hasDebt ? AppColors.ink : AppColors.success,
                  fontSize: 22,
                ),
              ),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${customerDual(strings, 'Charged', 'Deni')}: ${formatCustomerMoney(charges)}   ·   ${customerDual(strings, 'Paid', 'Malipo')}: ${formatCustomerMoney(paid)}',
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final entry in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: CustomerLedgerRow(entry: entry, strings: strings),
            ),
          if (entries.length > recent.length)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                customerDual(
                    strings,
                    '+ ${entries.length - recent.length} earlier entries',
                    '+ rekodi ${entries.length - recent.length} za awali'),
                style: AppTypography.helperText.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              customerDual(strings, 'No credit activity recorded yet.',
                  'Hakuna shughuli ya mkopo iliyorekodiwa.'),
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _receive(BuildContext context) async {
    final result = await showRecordPaymentSheet(context, customer: customer);
    if (result == null || !context.mounted) return;

    final store = context.read<PosLocalStore>();
    final applied = await store.recordDebtPayment(
      customerId: customer.id,
      amount: result.amount,
      note: result.note,
    );
    if (!context.mounted) return;

    if (applied == null) {
      showMarketNotice(
        context,
        title:
            customerDual(strings, 'Payment not applied', 'Malipo hayajatumika'),
        message: customerDual(
          strings,
          'The amount must be between 1 and the outstanding balance.',
          'Kiasi lazima kiwe kati ya 1 na deni lililobaki.',
        ),
        type: MarketNoticeType.warning,
      );
      return;
    }

    showMarketNotice(
      context,
      title: customerDual(strings, 'Payment recorded', 'Malipo yamerekodiwa'),
      message: customerDual(
        strings,
        '${formatCustomerMoney(result.amount)} received. Balance ${formatCustomerMoney(applied.debitBalance)}.',
        '${formatCustomerMoney(result.amount)} yamepokelewa. Deni ${formatCustomerMoney(applied.debitBalance)}.',
      ),
    );
  }

  Future<void> _shareStatement(BuildContext context) async {
    final store = context.read<PosLocalStore>();
    await DebitStatementService.generateAndSharePdf(
      customer: customer,
      store: store,
      strings: strings,
    );
  }
}

class CustomerDebitAction extends StatelessWidget {
  const CustomerDebitAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.payments_rounded,
    this.color,
    this.foregroundColor = Colors.white,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final Color? color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.primary,
      borderRadius: AppCorners.control,
      child: InkWell(
        borderRadius: AppCorners.control,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerLedgerRow extends StatelessWidget {
  const CustomerLedgerRow(
      {super.key, required this.entry, required this.strings});

  final DebitEntry entry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color = isPayment ? AppColors.success : AppColors.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border:
            Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            isPayment ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.localized(strings.isSwahili),
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.note.trim().isNotEmpty)
                  Text(
                    entry.note.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.textLight,
                      fontSize: 9.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isPayment ? '-' : '+'}${formatCustomerMoney(entry.amount)}',
                style: AppTypography.helperText.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                DateFormat('MMM d').format(entry.createdAt),
                style: AppTypography.helperText.copyWith(
                  color: AppColors.textLight,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
