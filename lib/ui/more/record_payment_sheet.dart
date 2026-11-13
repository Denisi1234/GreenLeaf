import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _money(double value) => 'TSh ${NumberFormat('#,##0').format(value)}';

/// Result of a repayment: the amount applied and an optional note.
class DebtPaymentResult {
  const DebtPaymentResult({required this.amount, this.note = ''});

  final double amount;
  final String note;
}

/// Opens the repayment sheet for [customer] and returns the entered payment.
Future<DebtPaymentResult?> showRecordPaymentSheet(
  BuildContext context, {
  required CustomerData customer,
}) {
  return showModalBottomSheet<DebtPaymentResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (_) => RecordPaymentSheet(customer: customer),
  );
}

class RecordPaymentSheet extends StatefulWidget {
  const RecordPaymentSheet({super.key, required this.customer});

  final CustomerData customer;

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  late final TextEditingController _amountController;
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.customer.debitBalance > 0
          ? widget.customer.debitBalance.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _balance => widget.customer.debitBalance;

  void _fill(double value) {
    setState(() {
      _amountController.text = value.toStringAsFixed(0);
    });
  }

  void _submit() {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      showMarketNotice(
        context,
        title: _dual(strings, 'Invalid amount', 'Kiasi si sahihi'),
        message: _dual(strings, 'Enter an amount greater than zero.',
            'Weka kiasi kikubwa kuliko sifuri.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    Navigator.of(context).pop(
      DebtPaymentResult(amount: amount, note: _noteController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.watch<PosLocalStore>().languageCode);
    final balance = _balance;
    final paid = balance <= 0 ? 0.0 : balance;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _dual(strings, 'Record payment', 'Rekodi malipo'),
              style: AppTypography.cardHeader,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.customer.name} · ${widget.customer.phone.trim().isEmpty ? _dual(strings, 'no phone', 'hakuna simu') : widget.customer.phone}',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.zero,
                border:
                    Border.all(color: AppColors.danger.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dual(strings, 'Outstanding balance', 'Deni lililobaki'),
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _money(balance),
                    style: AppTypography.h2.copyWith(
                      color: AppColors.danger,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _dual(strings, 'Amount received', 'Kiasi kilichopokelewa'),
              style: AppTypography.label,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyMain,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: 'TSh ',
                prefixStyle:
                    AppTypography.bodyMain.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (value) {
                final amount = double.tryParse((value ?? '').trim()) ?? 0;
                if (amount <= 0) {
                  return _dual(strings, 'Enter an amount', 'Weka kiasi');
                }
                if (amount > balance) {
                  return _dual(
                      strings, 'More than the balance', 'Kiasi kinazidi deni');
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _QuickAmount(
                  label: _dual(strings, 'Full balance', 'Deni lote'),
                  onTap: balance <= 0 ? null : () => _fill(paid),
                ),
                const SizedBox(width: 8),
                _QuickAmount(
                  label: _dual(strings, 'Half', 'Nusu'),
                  onTap: balance <= 0 ? null : () => _fill(paid / 2),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _dual(strings, 'Note (optional)', 'Maelezo (si lazima)'),
              style: AppTypography.label,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              style: AppTypography.bodyMain,
              decoration: InputDecoration(
                hintText: _dual(strings, 'Cash, M-Pesa, bank transfer...',
                    'Taslimu, M-Pesa, benki...'),
                hintStyle:
                    AppTypography.bodyMain.copyWith(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            MarketButton(
              label: _dual(strings, 'Record payment', 'Rekodi malipo'),
              icon: Icons.check_rounded,
              onTap: balance <= 0 ? null : _submit,
            ),
            if (balance <= 0) ...[
              const SizedBox(height: 8),
              Text(
                _dual(strings, 'This customer has no outstanding balance.',
                    'Mteja huyu hana deni.'),
                style: AppTypography.helperText
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAmount extends StatelessWidget {
  const _QuickAmount({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: onTap == null ? AppColors.surfaceSecondary : AppColors.surface,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              label,
              style: AppTypography.helperText.copyWith(
                color: onTap == null ? AppColors.textLight : AppColors.textBody,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
