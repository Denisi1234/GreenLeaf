import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'bank_line_form_page.dart';
import 'import_statement_page.dart';
import 'widgets/bank_reconciliation_kpi_metrics.dart';
import 'widgets/reconciliation_empty_state.dart';
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
                    tooltip: t('Import statement', 'Ingiza taarifa'),
                    onPressed: () => _openImport(context),
                    icon: const Icon(Icons.upload_file_outlined, color: AppColors.ink),
                  ),
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
                    // Overview status banner
                    ReconciliationCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: unmatched.isEmpty && entries.isNotEmpty
                                  ? const Color(0xFFDCFCE7)
                                  : (entries.isEmpty
                                      ? AppColors.surfaceSecondary
                                      : const Color(0xFFFEE2E2)),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Icon(
                              unmatched.isEmpty && entries.isNotEmpty
                                  ? Icons.verified_outlined
                                  : (entries.isEmpty
                                      ? Icons.account_balance_outlined
                                      : Icons.warning_amber_rounded),
                              color: unmatched.isEmpty && entries.isNotEmpty
                                  ? const Color(0xFF15803D)
                                  : (entries.isEmpty
                                      ? AppColors.textMuted
                                      : const Color(0xFFB91C1C)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entries.isEmpty
                                      ? t('No reconciliation data', 'Hakuna data ya upatanishi')
                                      : (unmatched.isEmpty
                                          ? t('All lines matched', 'Mistari yote imeoanishwa')
                                          : t(
                                              '${unmatched.length} line${unmatched.length == 1 ? '' : 's'} unmatched',
                                              'Mistari ${unmatched.length} haijaoanishwa',
                                            )),
                                  style: AppTypography.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: entries.isEmpty
                                        ? AppColors.ink
                                        : (unmatched.isEmpty
                                            ? AppColors.success
                                            : AppColors.danger),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  entries.isEmpty
                                      ? t(
                                          'Import or add statement lines to get started.',
                                          'Ingiza au ongeza mistari ya taarifa ili kuanza.',
                                        )
                                      : (unmatched.isEmpty
                                          ? t(
                                              'Statement and records are in complete agreement.',
                                              'Taarifa na rekodi zinalingana kikamilifu.',
                                            )
                                          : t(
                                              'Unmatched value ${_money(unmatchedTotal)} — review details or auto match.',
                                              'Thamani isiyooanishwa ${_money(unmatchedTotal)} — kagua au oanisha.',
                                            )),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (unmatched.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            MarketButton(
                              label: t('Auto match', 'Oanisha'),
                              icon: Icons.auto_fix_high_rounded,
                              radius: 0,
                              onTap: () => _autoMatch(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Modern borderless sharp KPI cards
                    BankReconciliationKpiMetrics(
                      inflow: inflow,
                      outflow: outflow,
                      net: net,
                      matchedCount: matched.length,
                      totalCount: entries.length,
                      isSwahili: sw,
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: MarketButton(
                            label: t('Add line', 'Ongeza mstari'),
                            icon: Icons.add_rounded,
                            radius: 0,
                            onTap: () => _openAddLine(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MarketButton(
                            label: t('Import statement', 'Ingiza taarifa'),
                            icon: Icons.upload_file_outlined,
                            isPrimary: false,
                            radius: 0,
                            onTap: () => _openImport(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section header & list / empty state
                    _sectionHeader(
                      t('Statement lines', 'Mistari ya taarifa'),
                      trailing: '${entries.length} ${t('lines', 'mistari')}',
                    ),
                    const SizedBox(height: 10),

                    if (entries.isEmpty)
                      ReconciliationEmptyState(
                        isSwahili: sw,
                        onAddLine: () => _openAddLine(context),
                        onImport: () => _openImport(context),
                      )
                    else
                      ReconciliationCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _tableHeader(t),
                            const Divider(height: 1, color: AppColors.divider),
                            for (var i = 0; i < entries.length; i++) ...[
                              StatementRowTile(
                                entry: entries[i],
                                isSwahili: sw,
                              ),
                              if (i != entries.length - 1)
                                const Divider(height: 1, color: AppColors.divider),
                            ],
                          ],
                        ),
                      ),
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
              ? 'Mistari $count imeoanishwa kiotomatiki'
              : '$count line${count == 1 ? '' : 's'} automatically matched')
          : (sw
              ? 'Hakuna mstari uliooanishwa kiotomatiki'
              : 'No lines were auto matched'),
      type: count > 0 ? MarketNoticeType.success : MarketNoticeType.info,
    );
  }

  static Widget _tableHeader(String Function(String, String) t) {
    return Container(
      color: AppColors.surfaceSecondary,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              t('Transaction / Description', 'Muamala / Maelezo'),
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 104,
            child: Text(
              t('Amount', 'Kiasi'),
              textAlign: TextAlign.right,
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              t('Status', 'Hali'),
              textAlign: TextAlign.right,
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionHeader(String text, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: AppTypography.sectionHeader.copyWith(color: AppColors.ink),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  static String _money(double value) {
    final negative = value < 0;
    final abs = formatCurrency(value.abs());
    return '${negative ? '-' : ''}TSh $abs';
  }
}
