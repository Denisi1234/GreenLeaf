import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

/// Bank and mobile money statement reconciliation.
class BankReconciliationPage extends StatefulWidget {
  const BankReconciliationPage({super.key});

  @override
  State<BankReconciliationPage> createState() => _BankReconciliationPageState();
}

class _BankReconciliationPageState extends State<BankReconciliationPage> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final entries = store.bankTransactions;
    final matched = entries.where((entry) => entry.matched);
    final unmatched = entries.where((entry) => !entry.matched);
    final matchedTotal =
        matched.fold<double>(0, (sum, entry) => sum + entry.amount);
    final unmatchedTotal =
        unmatched.fold<double>(0, (sum, entry) => sum + entry.amount);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: t('Bank reconciliation', 'Upatanishi wa benki'),
              subtitle: '${matched.length} ${t('matched', 'zimeoanishwa')} • '
                  '${unmatched.length} ${t('open', 'wazi')}',
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                IconButton(
                  tooltip: t('Add line', 'Ongeza mstari'),
                  onPressed: () => _showLineDialog(context, store),
                  icon: const Icon(Icons.add_rounded, color: AppColors.ink),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  MarketSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('Reconciliation summary',
                              'Muhtasari wa upatanishi'),
                          style: AppTypography.label,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _BankRow(
                          label: t('Matched', 'Zimeoanishwa'),
                          value: 'TZS ${matchedTotal.toStringAsFixed(0)}',
                        ),
                        _BankRow(
                          label: t('Unmatched', 'Hazijaoanishwa'),
                          value: 'TZS ${unmatchedTotal.toStringAsFixed(0)}',
                          danger: unmatchedTotal != 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: MarketButton(
                          label: t('Auto match', 'Oanisha kiotomatiki'),
                          icon: Icons.link_rounded,
                          isPrimary: false,
                          onTap: () => _autoMatch(context, store),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: MarketButton(
                          label: t('Paste import', 'Bandika orodha'),
                          icon: Icons.content_paste_rounded,
                          isPrimary: false,
                          onTap: () => _showImportSheet(context, store),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (entries.isEmpty)
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_outlined,
                              size: 32, color: AppColors.textLight),
                          const SizedBox(height: 10),
                          Text(
                            t('No statement lines',
                                'Hakuna mistari ya taarifa'),
                            style: AppTypography.h3.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t(
                              'Add statement lines or paste them from your bank or mobile money provider.',
                              'Ongeza mistari ya taarifa au ubandike kutoka benki au mtandao wa simu.',
                            ),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted, height: 1.4),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final entry in entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MarketSurfaceCard(
                          padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: entry.isInflow
                                      ? AppColors.successLight
                                      : AppColors.dangerLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.standard),
                                ),
                                child: Icon(
                                  entry.isInflow
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  size: 18,
                                  color: entry.isInflow
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.description.isEmpty
                                          ? entry.accountName
                                          : entry.description,
                                      style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '${entry.date.toLocal().toString().substring(0, 10)}'
                                      '${entry.reference.isEmpty ? '' : ' • ${entry.reference}'}',
                                      style: AppTypography.helperText
                                          .copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'TZS ${entry.amount.toStringAsFixed(0)}',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: entry.isInflow
                                          ? AppColors.ink
                                          : AppColors.danger,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      await store.setBankTransactionMatched(
                                          entry.id!, !entry.matched);
                                    },
                                    child: Text(
                                      entry.matched
                                          ? t('Matched', 'Imoanishwa')
                                          : t('Mark matched', 'Oanisha'),
                                      style: AppTypography.helperText.copyWith(
                                        color: entry.matched
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoMatch(BuildContext context, PosLocalStore store) async {
    final count = await store.autoMatchBankTransactions();
    if (!mounted) return;
    showMarketNotice(
      context,
      title: context.watch<PosLocalStore>().languageCode == 'sw'
          ? 'Upatanishi'
          : 'Reconciliation',
      message: context.watch<PosLocalStore>().languageCode == 'sw'
          ? 'Mistari $count imeoanishwa'
          : '$count lines matched',
    );
  }

  Future<void> _showLineDialog(
      BuildContext context, PosLocalStore store) async {
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    final dateController = TextEditingController(
      text: DateTime.now().toLocal().toString().substring(0, 10),
    );
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final referenceController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(sw ? 'Ongeza mstari' : 'Add statement line'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MarketFormField(
                label: sw ? 'Tarehe' : 'Date',
                hintText: '2026-01-31',
                controller: dateController,
              ),
              const SizedBox(height: 10),
              MarketFormField(
                label: sw ? 'Maelezo' : 'Description',
                hintText: sw ? 'Malipo ya M-Pesa' : 'M-Pesa payment',
                controller: descriptionController,
              ),
              const SizedBox(height: 10),
              MarketFormField(
                label: sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
                hintText: sw
                    ? 'Chanya kuingia, hasi kutoka'
                    : 'Positive in, negative out',
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
              ),
              const SizedBox(height: 10),
              MarketFormField(
                label: sw ? 'Kumbukumbu' : 'Reference',
                hintText: 'MPX123456',
                controller: referenceController,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(sw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount == 0) return;
              await store.addBankTransaction(
                BankTransaction(
                  date: DateTime.tryParse(dateController.text.trim()) ??
                      DateTime.now(),
                  description: descriptionController.text.trim(),
                  amount: amount,
                  reference: referenceController.text.trim(),
                  accountName: sw ? 'Benki' : 'Bank',
                ),
              );
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
  }

  Future<void> _showImportSheet(
      BuildContext context, PosLocalStore store) async {
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    final controller = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sw ? 'Bandika mistari' : 'Paste statement lines',
              style: AppTypography.h3.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              sw
                  ? 'Mstari mmoja kwa kila miamala: tarehe, maelezo, kiasi'
                  : 'One line per transaction: date, description, amount',
              style:
                  AppTypography.helperText.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '2026-01-31, M-Pesa deposit, 150000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MarketButton(
              label: sw ? 'Ingiza mistari' : 'Import lines',
              icon: Icons.download_rounded,
              onTap: () async {
                final rows = controller.text
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty);
                var imported = 0;
                for (final row in rows) {
                  final parts = row
                      .split(RegExp(r'[,\t;]'))
                      .map((p) => p.trim())
                      .toList();
                  if (parts.length < 3) continue;
                  final amount = double.tryParse(parts.last);
                  if (amount == null || amount == 0) continue;
                  await store.addBankTransaction(
                    BankTransaction(
                      date: DateTime.tryParse(parts.first) ?? DateTime.now(),
                      description: parts.length > 2
                          ? parts.sublist(1, parts.length - 1).join(' ')
                          : '',
                      amount: amount,
                      accountName: sw ? 'Benki' : 'Bank',
                    ),
                  );
                  imported++;
                }
                if (context.mounted) Navigator.of(context).pop(imported > 0);
              },
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({
    required this.label,
    required this.value,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: danger ? AppColors.danger : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
