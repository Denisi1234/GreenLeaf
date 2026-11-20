import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'bank_line_form_page.dart';
import 'import_statement_page.dart';
import 'widgets/reconciliation_models.dart';
import 'widgets/statement_row_tile.dart';

/// Bank and mobile money statement reconciliation.
class BankReconciliationPage extends StatelessWidget {
  const BankReconciliationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final entries = [...store.bankTransactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final matched = entries.where((e) => e.matched).toList();
    final unmatched = entries.where((e) => !e.matched).toList();

    final inflow = entries
        .where((e) => e.amount >= 0)
        .fold<double>(0, (s, e) => s + e.amount);
    final outflow = entries
        .where((e) => e.amount < 0)
        .fold<double>(0, (s, e) => s + e.amount.abs());
    final unmatchedTotal =
        unmatched.fold<double>(0, (s, e) => s + e.amount.abs());
    final net = inflow - outflow;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
        maxWidth: 1280,
        child: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: t('Bank reconciliation', 'Upatanishi wa benki'),
                subtitle: t('Match statement lines to records',
                    'Oanisha mistari ya taarifa na rekodi'),
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  IconButton(
                    tooltip: t('Add line', 'Ongeza mstari'),
                    onPressed: () => _openAddLine(context),
                    icon: const Icon(Icons.add_rounded, color: AppColors.ink),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    ReconciliationCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Reconciliation status', 'Hali ya upatanishi'),
                            style: AppTypography.label
                                .copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            unmatched.isEmpty
                                ? t('All lines matched',
                                    'Mistari yote imeoanishwa')
                                : t('${unmatched.length} line${unmatched.length == 1 ? '' : 's'} unmatched',
                                    'Mistari ${unmatched.length} haijaoanishwa'),
                            style: AppTypography.h1.copyWith(
                              fontSize: 26,
                              color: unmatched.isEmpty
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unmatched.isEmpty
                                ? t('Statement and records are in agreement for imported lines.',
                                    'Taarifa na rekodi zinalingana kwa mistari iliyoingizwa.')
                                : t('Unmatched value ${_money(unmatchedTotal)} — review or auto match.',
                                    'Thamani isiyooanishwa ${_money(unmatchedTotal)} — kagua au oanisha.'),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            label: t('Money in', 'Pesa zilizoingia'),
                            value: _money(inflow),
                            valueColor: inflow > 0
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            label: t('Money out', 'Pesa zilizotoka'),
                            value: _money(outflow),
                            valueColor: outflow > 0
                                ? AppColors.danger
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            label: t('Net movement', 'Mabadiliko halisi'),
                            value: _money(net, signed: true),
                            valueColor: net > 0
                                ? AppColors.success
                                : net < 0
                                    ? AppColors.danger
                                    : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            label:
                                t('Matched / total', 'Zimeoanishwa / jumla'),
                            value: '${matched.length} / ${entries.length}',
                            valueColor:
                                unmatched.isEmpty && entries.isNotEmpty
                                    ? AppColors.success
                                    : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MarketButton(
                            label: t('Add line', 'Ongeza mstari'),
                            icon: Icons.add_rounded,
                            onTap: () => _openAddLine(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MarketButton(
                            label: t('Import statement', 'Ingiza taarifa'),
                            icon: Icons.upload_file_outlined,
                            isPrimary: false,
                            onTap: () => _openImport(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MarketButton(
                      label: t(
                          'Auto match lines', 'Oanisha mistari kiotomatiki'),
                      icon: Icons.link_rounded,
                      isPrimary: false,
                      onTap: entries.isEmpty ? null : () => _autoMatch(context),
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader(t('Statement lines', 'Mistari ya taarifa'),
                        trailing: '${entries.length} ${t('lines', 'mistari')}'),
                    const SizedBox(height: 8),
                    if (entries.isEmpty)
                      ReconciliationCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                  Icons.account_balance_outlined,
                                  color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t('No statement lines yet',
                                  'Hakuna mistari ya taarifa bado'),
                              style: AppTypography.bodyMain
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t(
                                'Add bank/mobile money lines or import them to reconcile against sales and records.',
                                'Ongeza mistari ya benki/mitandao ya simu au yaingize ili upatanishe na mauzo na rekodi.',
                              ),
                              style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted, height: 1.45),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      ReconciliationCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _tableHeader(t),
                            const Divider(
                                height: 1, color: AppColors.divider),
                            for (var i = 0; i < entries.length; i++) ...[
                              StatementRowTile(
                                entry: entries[i],
                                isSwahili: sw,
                              ),
                              if (i != entries.length - 1)
                                const Divider(
                                    height: 1, color: AppColors.divider),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openAddLine(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const BankLineFormPage(),
      ),
    );
  }

  static void _openImport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ImportStatementPage(),
      ),
    );
  }

  static Future<void> _autoMatch(BuildContext context) async {
    final store = context.read<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    final count = await store.autoMatchBankTransactions();
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: sw ? 'Upatanishi' : 'Reconciliation',
      message: count > 0
          ? (sw
              ? 'Mistari $count imeoanishwa'
              : '$count line${count == 1 ? '' : 's'} matched')
          : (sw
              ? 'Hakuna mstari uliooanishwa kiotomatiki'
              : 'No lines were auto matched'),
      type: count > 0 ? MarketNoticeType.success : MarketNoticeType.info,
    );
  }

  static Widget _tableHeader(String Function(String, String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(t('Line', 'Mstari'),
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: 96,
            child: Text(t('Amount', 'Kiasi'),
                textAlign: TextAlign.right,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: 74,
            child: Text(t('Status', 'Hali'),
                textAlign: TextAlign.right,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static Widget _sectionHeader(String text, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(text,
              style:
                  AppTypography.sectionHeader.copyWith(color: AppColors.ink)),
        ),
        if (trailing != null)
          Text(trailing,
              style: AppTypography.helperText.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w700)),
      ],
    );
  }

  static Widget _metricCard({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return ReconciliationCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.helperText
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(
              fontSize: 17,
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _money(double value, {bool signed = false}) {
    final negative = value < 0;
    final abs = formatCurrency(value.abs());
    if (signed) {
      if (value > 0) return '+TSh $abs';
      if (value < 0) return '-TSh $abs';
      return 'TSh $abs';
    }
    return '${negative ? '-' : ''}TSh $abs';
  }
}
