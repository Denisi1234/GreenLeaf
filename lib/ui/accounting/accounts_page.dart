import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'account_form_page.dart';
import 'journal_entry_page.dart';
import 'widgets/account_row_tile.dart';
import 'widgets/accounting_common_widgets.dart';
import 'widgets/trial_balance_kpi_metrics.dart';

/// Chart of accounts and manual journal entries.
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
        maxWidth: 1280,
        child: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: _t('Accounts & ledger', 'Akaunti na daftari'),
                subtitle: _t('Trial balance and journal entries',
                    'Mizania na kumbukumbu za daftari'),
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  IconButton(
                    tooltip: _t('New journal entry', 'Kumbukumbu mpya'),
                    onPressed: () => _openJournalForm(context),
                    icon: const Icon(Icons.add_rounded, color: AppColors.ink),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedTabs(
                  controller: _tabs,
                  labels: [
                    _t('Accounts', 'Akaunti'),
                    _t('Journal', 'Daftari')
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildAccounts(store),
                    _buildJournal(store),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccounts(PosLocalStore store) {
    final rows = store.trialBalance();
    final totalDebit = rows.fold<double>(0, (sum, row) => sum + row.debit);
    final totalCredit = rows.fold<double>(0, (sum, row) => sum + row.credit);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TrialBalanceKpiMetrics(
          totalDebit: totalDebit,
          totalCredit: totalCredit,
          isSwahili: _isSwahili,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                _t('Accounts', 'Akaunti'),
                style:
                    AppTypography.sectionHeader.copyWith(color: AppColors.ink),
              ),
            ),
            Text(
              '${rows.length}',
              style: AppTypography.helperText.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          LedgerCard(
            child: Text(
              _t(
                'No ledger activity yet. Sales, expenses and purchases will appear here.',
                'Hakuna shughuli bado. Mauzo, matumizi na manunuzi yataonekana hapa.',
              ),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted, height: 1.45),
            ),
          )
        else
          LedgerCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableHeader(),
                const Divider(height: 1, color: AppColors.divider),
                for (var i = 0; i < rows.length; i++) ...[
                  AccountRowTile(
                    code: rows[i].code,
                    name: rows[i].name,
                    debit: rows[i].debit,
                    credit: rows[i].credit,
                    formattedAmount: _money(
                      (rows[i].debit - rows[i].credit).abs() < 0.01
                          ? (rows[i].debit > 0 ? rows[i].debit : rows[i].credit)
                          : (rows[i].debit - rows[i].credit).abs(),
                    ),
                  ),
                  if (i != rows.length - 1)
                    const Divider(height: 1, color: AppColors.divider),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        MarketButton(
          label: _t('Add account', 'Ongeza akaunti'),
          icon: Icons.add_rounded,
          onTap: () => _openAccountForm(context),
        ),
      ],
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(_t('Code', 'Msimbo'),
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(_t('Account', 'Akaunti'),
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: 100,
            child: Text(_t('Balance', 'Salio'),
                textAlign: TextAlign.right,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildJournal(PosLocalStore store) {
    final entries = store.journalEntries;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _t('Journal entries', 'Kumbukumbu za daftari'),
                style:
                    AppTypography.sectionHeader.copyWith(color: AppColors.ink),
              ),
            ),
            MarketButton(
              label: _t('New entry', 'Mpya'),
              icon: Icons.add_rounded,
              isFullWidth: false,
              height: 38,
              onTap: () => _openJournalForm(context),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          LedgerCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(Icons.menu_book_outlined,
                      size: 26, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Text(
                  _t('No journal entries', 'Hakuna kumbukumbu'),
                  style: AppTypography.h3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  _t(
                    'Use journal entries for corrections, opening balances and adjustments.',
                    'Tumia kumbukumbu kwa marekebisho, mizania ya kuanzia na mipangilio.',
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted, height: 1.45),
                ),
              ],
            ),
          )
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LedgerCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.memo.isEmpty
                                    ? _t('Adjustment', 'Marekebisho')
                                    : entry.memo,
                                style: AppTypography.bodyMain
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.date
                                    .toLocal()
                                    .toString()
                                    .substring(0, 10),
                                style: AppTypography.helperText
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: _t('Delete', 'Futa'),
                          onPressed: () => _confirmDeleteJournal(entry),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 6),
                    for (final line in entry.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: line.debit > 0
                                    ? AppColors.surfaceSecondary
                                    : AppColors.successLight,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                line.debit > 0 ? 'DR' : 'CR',
                                style: AppTypography.helperText.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: line.debit > 0
                                      ? AppColors.ink
                                      : AppColors.successDeep,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _money(line.debit > 0 ? line.debit : line.credit),
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: line.debit > 0
                                    ? AppColors.ink
                                    : AppColors.successDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _openAccountForm(
    BuildContext context, [
    Account? account,
  ]) async {
    final store = context.read<PosLocalStore>();
    final result = await Navigator.of(context).push<Account>(
      MaterialPageRoute<Account>(
        builder: (context) => AccountFormPage(account: account),
      ),
    );
    if (result == null) return;
    await store.saveAccount(result);
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: account == null
          ? _t('Account Added', 'Akaunti Imeongezwa')
          : _t('Account Updated', 'Akaunti Imesasishwa'),
      message: _t(
        '${result.name} has been saved to your chart of accounts.',
        '${result.name} imehifadhiwa kwenye orodha ya akaunti.',
      ),
      type: MarketNoticeType.success,
    );
  }

  void _openJournalForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const JournalEntryPage(),
      ),
    );
  }

  Future<void> _confirmDeleteJournal(JournalEntry entry) async {
    if (entry.id == null) return;
    final store = context.read<PosLocalStore>();
    final confirmed = await showMarketConfirmDialog(
      context,
      title: _t('Delete entry?', 'Futa kumbukumbu?'),
      message: _t('This cannot be undone.', 'Hili haliwezi kurejeshwa.'),
      confirmLabel: _t('Delete', 'Futa'),
      cancelLabel: _t('Cancel', 'Ghairi'),
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    await store.deleteJournalEntry(entry.id!);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: _t('Entry Deleted', 'Kumbukumbu Imefutwa'),
      message: _t('Journal entry was removed.', 'Kumbukumbu ya daftari imeondolewa.'),
      type: MarketNoticeType.success,
    );
  }

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }
}
