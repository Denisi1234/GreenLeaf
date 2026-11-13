import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

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
      body: SafeArea(
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
              child: _SegmentedTabs(
                controller: _tabs,
                labels: [_t('Accounts', 'Akaunti'), _t('Journal', 'Daftari')],
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
    );
  }

  Widget _buildAccounts(PosLocalStore store) {
    final rows = store.trialBalance();
    final totalDebit = rows.fold<double>(0, (sum, row) => sum + row.debit);
    final totalCredit = rows.fold<double>(0, (sum, row) => sum + row.credit);
    final balanced = (totalDebit - totalCredit).abs() < 0.01;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _LedgerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Trial balance', 'Mizania ya majaribio'),
                style: AppTypography.label.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MoneyMetric(
                      label: _t('Total debit', 'Jumla ya deni'),
                      value: _money(totalDebit),
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MoneyMetric(
                      label: _t('Total credit', 'Jumla ya mkopo'),
                      value: _money(totalCredit),
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: balanced
                      ? AppColors.successLight
                      : AppColors.dangerLight,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: balanced
                        ? AppColors.success.withValues(alpha: 0.25)
                        : AppColors.danger.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  balanced
                      ? _t('Balanced — debits equal credits',
                          'Imelingana — deni sawa na mkopo')
                      : _t('Not balanced — review journal entries',
                          'Haijalingana — kagua kumbukumbu'),
                  style: AppTypography.bodySmall.copyWith(
                    color: balanced ? AppColors.successDeep : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                _t('Accounts', 'Akaunti'),
                style: AppTypography.sectionHeader.copyWith(color: AppColors.ink),
              ),
            ),
            Text(
              '${rows.length}',
              style: AppTypography.helperText
                  .copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          _LedgerCard(
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
          _LedgerCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableHeader(),
                const Divider(height: 1, color: AppColors.divider),
                for (var i = 0; i < rows.length; i++) ...[
                  _AccountRow(row: rows[i]),
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
          isPrimary: false,
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
                style: AppTypography.sectionHeader.copyWith(color: AppColors.ink),
              ),
            ),
            MarketButton(
              label: _t('New entry', 'Mpya'),
              icon: Icons.add_rounded,
              isPrimary: false,
              isFullWidth: false,
              height: 38,
              onTap: () => _openJournalForm(context),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          _LedgerCard(
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
              child: _LedgerCard(
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
                                entry.date.toLocal().toString().substring(0, 10),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(_t('Delete entry?', 'Futa kumbukumbu?')),
        content: Text(
          _t('This cannot be undone.', 'Hili haliwezi kurejeshwa.'),
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
    await store.deleteJournalEntry(entry.id!);
  }

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.row});
  final dynamic row;

  @override
  Widget build(BuildContext context) {
    final debit = (row.debit as num).toDouble();
    final credit = (row.credit as num).toDouble();
    final balance = debit - credit;
    final color = balance > 0
        ? AppColors.ink
        : balance < 0
            ? AppColors.successDeep
            : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              row.code as String,
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.name as String,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              _AccountsPageState._money(balance.abs() < 0.01
                  ? (debit > 0 ? debit : credit)
                  : balance.abs()),
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTypography.helperText.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.h3.copyWith(
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: padding,
      showShadow: false,
      borderColor: AppColors.border,
      radius: 0,
      child: child,
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.controller, required this.labels});
  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.border),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:
            AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        tabs: [for (final label in labels) Tab(height: 38, text: label)],
      ),
    );
  }
}

class AccountFormPage extends StatefulWidget {
  const AccountFormPage({super.key, this.account});

  final Account? account;

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late AccountType _type;

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _code = TextEditingController(text: account?.code ?? '');
    _name = TextEditingController(text: account?.name ?? '');
    _balance = TextEditingController(
      text: account == null ? '' : account.openingBalance.toStringAsFixed(0),
    );
    _type = account?.type ?? AccountType.asset;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: widget.account == null
                  ? _t('Add account', 'Ongeza akaunti')
                  : _t('Edit account', 'Badilisha akaunti'),
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _LedgerCard(
                      child: Column(
                        children: [
                          MarketFormField(
                            label: _t('Code', 'Msimbo'),
                            hintText: '1000',
                            controller: _code,
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? _t('Enter a code', 'Weka msimbo')
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Name', 'Jina'),
                            hintText: _t('Cash on hand', 'Pesa taslimu'),
                            controller: _name,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? _t('Enter a name', 'Weka jina')
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<AccountType>(
                            initialValue: _type,
                            decoration: InputDecoration(
                              labelText: _t('Type', 'Aina'),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 1.4),
                              ),
                            ),
                            items: [
                              for (final type in AccountType.values)
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(type.localized(_isSwahili)),
                                ),
                            ],
                            onChanged: (value) => setState(
                                () => _type = value ?? AccountType.asset),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Opening balance (TZS)',
                                'Mizania ya kuanzia (TZS)'),
                            hintText: '0',
                            controller: _balance,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MarketButton(
                      label: _t('Save account', 'Hifadhi akaunti'),
                      icon: Icons.check_rounded,
                      onTap: () {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.of(context).pop(
                          Account(
                            id: widget.account?.id,
                            code: _code.text.trim(),
                            name: _name.text.trim(),
                            type: _type,
                            openingBalance:
                                double.tryParse(_balance.text.trim()) ?? 0,
                          ),
                        );
                      },
                    ),
                    if (widget.account != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      MarketButton(
                        label: _t('Delete account', 'Futa akaunti'),
                        icon: Icons.delete_outline_rounded,
                        isPrimary: false,
                        color: AppColors.dangerLight,
                        foregroundColor: AppColors.danger,
                        borderColor: AppColors.dangerLight,
                        onTap: () async {
                          final store = context.read<PosLocalStore>();
                          final navigator = Navigator.of(context);
                          await store.deleteAccount(widget.account!.id!);
                          if (!mounted) return;
                          navigator.maybePop();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalEntryPage extends StatefulWidget {
  const JournalEntryPage({super.key});

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final _memoController = TextEditingController();
  final List<_JournalDraft> _lines = [
    _JournalDraft(),
    _JournalDraft(),
  ];

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final debit = _lines.fold<double>(0, (sum, line) => sum + line.debit);
    final credit = _lines.fold<double>(0, (sum, line) => sum + line.credit);
    final balanced = (debit - credit).abs() < 0.01;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: _t('New journal entry', 'Kumbukumbu mpya'),
              subtitle:
                  _t('Debit must equal credit', 'Deni liwe sawa na mkopo'),
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _LedgerCard(
                    child: MarketFormField(
                      label: _t('Memo', 'Maelezo'),
                      hintText: _t('Opening balance, correction...',
                          'Mizania, marekebisho...'),
                      controller: _memoController,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (var index = 0; index < _lines.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _JournalLineCard(
                        index: index + 1,
                        draft: _lines[index],
                        accounts: store.accounts,
                        isSwahili: _isSwahili,
                        onChanged: () => setState(() {}),
                        onRemove: _lines.length <= 2
                            ? null
                            : () => setState(() => _lines.removeAt(index)),
                      ),
                    ),
                  MarketButton(
                    label: _t('Add line', 'Ongeza mstari'),
                    icon: Icons.add_rounded,
                    isPrimary: false,
                    onTap: () => setState(() => _lines.add(_JournalDraft())),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _LedgerCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_t('Debit', 'Deni')} ${_AccountsPageState._money(debit)}   •   ${_t('Credit', 'Mkopo')} ${_AccountsPageState._money(credit)}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: balanced ? AppColors.ink : AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                balanced
                                    ? _t('Balanced', 'Imelingana')
                                    : '${_t('Difference', 'Tofauti')} ${_AccountsPageState._money((debit - credit).abs())}',
                                style: AppTypography.helperText.copyWith(
                                  color: balanced
                                      ? AppColors.successDeep
                                      : AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MarketButton(
                    label: _t('Save entry', 'Hifadhi kumbukumbu'),
                    icon: Icons.check_rounded,
                    onTap: () => _save(store),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(PosLocalStore store) async {
    final valid = _lines.where((line) =>
        line.accountId != null && (line.debit > 0 || line.credit > 0));
    if (valid.isEmpty) {
      showMarketNotice(
        context,
        title: _t('Nothing to save', 'Hakuna cha kuhifadhi'),
        message: _t('Add at least one debit or credit line',
            'Ongeza mstari wa deni au mkopo'),
        type: MarketNoticeType.error,
      );
      return;
    }
    final debit = valid.fold<double>(0, (s, l) => s + l.debit);
    final credit = valid.fold<double>(0, (s, l) => s + l.credit);
    if ((debit - credit).abs() >= 0.01) {
      showMarketNotice(
        context,
        title: _t('Not balanced', 'Haijalingana'),
        message: _t('Debit must equal credit before saving.',
            'Deni lazima liwe sawa na mkopo kabla ya kuhifadhi.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    await store.saveJournalEntry(
      JournalEntry(
        date: DateTime.now(),
        memo: _memoController.text.trim(),
        createdBy: store.profile.ownerName,
        lines: [
          for (final line in valid)
            JournalLine(
              accountId: line.accountId,
              debit: line.debit,
              credit: line.credit,
            ),
        ],
      ),
    );
    if (!mounted) return;
    showMarketNotice(
      context,
      title: _t('Journal', 'Daftari'),
      message: _t('Entry saved', 'Kumbukumbu imehifadhiwa'),
      type: MarketNoticeType.success,
    );
    Navigator.of(context).maybePop();
  }
}

class _JournalDraft {
  int? accountId;
  double debit = 0;
  double credit = 0;
}

class _JournalLineCard extends StatelessWidget {
  const _JournalLineCard({
    required this.index,
    required this.draft,
    required this.accounts,
    required this.isSwahili,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _JournalDraft draft;
  final List<Account> accounts;
  final bool isSwahili;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  String _t(String en, String swahili) => isSwahili ? swahili : en;

  @override
  Widget build(BuildContext context) {
    return _LedgerCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_t('Line', 'Mstari')} $index',
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textMuted,
                ),
            ],
          ),
          DropdownButtonFormField<int>(
            initialValue: draft.accountId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: _t('Account', 'Akaunti'),
              isDense: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide:
                    BorderSide(color: AppColors.primary, width: 1.4),
              ),
            ),
            items: [
              for (final account in accounts)
                DropdownMenuItem(
                  value: account.id,
                  child: Text('${account.code} ${account.name}',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              draft.accountId = value;
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: _t('Debit', 'Deni'),
                    isDense: true,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 1.4),
                    ),
                  ),
                  onChanged: (value) {
                    draft.debit = double.tryParse(value) ?? 0;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: _t('Credit', 'Mkopo'),
                    isDense: true,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 1.4),
                    ),
                  ),
                  onChanged: (value) {
                    draft.credit = double.tryParse(value) ?? 0;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
