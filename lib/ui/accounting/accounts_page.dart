import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
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
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

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
            TabBar(
              controller: _tabs,
              labelColor: AppColors.ink,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: _t('Accounts', 'Akaunti')),
                Tab(text: _t('Journal', 'Daftari')),
              ],
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        MarketSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _t('Trial balance', 'Mizania'),
                      style: AppTypography.label,
                    ),
                  ),
                  Text(
                    '${_money(totalDebit)} / ${_money(totalCredit)}',
                    style: AppTypography.helperText
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (rows.isEmpty)
                Text(
                  _t(
                    'No ledger activity yet. Sales, expenses and purchases feed this report.',
                    'Hakuna shughuli bado. Mauzo, matumizi na manunuzi hujaza ripoti hii.',
                  ),
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted, height: 1.4),
                )
              else
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 46,
                          child: Text(
                            row.code,
                            style: AppTypography.helperText
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.name,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Text(
                          row.debit > 0
                              ? _money(row.debit)
                              : _money(row.credit),
                          style: AppTypography.helperText.copyWith(
                            fontWeight: FontWeight.w700,
                            color: row.debit > 0
                                ? AppColors.ink
                                : AppColors.textMuted,
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
          label: _t('Add account', 'Ongeza akaunti'),
          icon: Icons.add_rounded,
          isPrimary: false,
          onTap: () => _openAccountForm(context),
        ),
      ],
    );
  }

  Widget _buildJournal(PosLocalStore store) {
    final entries = store.journalEntries;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (entries.isEmpty)
          MarketSurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.menu_book_outlined,
                    size: 32, color: AppColors.textLight),
                const SizedBox(height: 10),
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
                      .copyWith(color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          )
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MarketSurfaceCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.memo.isEmpty
                                ? _t('Adjustment', 'Marekebisho')
                                : entry.memo,
                            style: AppTypography.bodySmall
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          entry.date.toLocal().toString().substring(0, 10),
                          style: AppTypography.helperText
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    for (final line in entry.lines)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${line.debit > 0 ? 'Dr' : 'Cr'} ${_money(line.debit > 0 ? line.debit : line.credit)}',
                          style: AppTypography.helperText
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _confirmDeleteJournal(entry),
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 16),
                        label: Text(_t('Delete', 'Futa')),
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
    final result = await Navigator.of(context).push<Account>(
      MaterialPageRoute<Account>(
        builder: (context) => AccountFormPage(account: account),
      ),
    );
    if (result == null || !mounted) return;
    await context.read<PosLocalStore>().saveAccount(result);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
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
    await context.read<PosLocalStore>().deleteJournalEntry(entry.id!);
  }

  static String _money(double value) {
    final text = value.abs().toStringAsFixed(0);
    final grouped = text.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match.group(1)},',
    );
    return '${value < 0 ? '-' : ''}TZS $grouped';
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
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

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
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(18),
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
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.input),
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
                          await context
                              .read<PosLocalStore>()
                              .deleteAccount(widget.account!.id!);
                          if (!mounted) return;
                          Navigator.of(context).maybePop();
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
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

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
                  MarketFormField(
                    label: _t('Memo', 'Maelezo'),
                    hintText: _t('Opening balance, correction...',
                        'Mizania, marekebisho...'),
                    controller: _memoController,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  MarketSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dr ${_money(debit)}   Cr ${_money(credit)}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: (debit - credit).abs() < 0.01
                                  ? AppColors.ink
                                  : AppColors.danger,
                            ),
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
    );
    Navigator.of(context).maybePop();
  }

  static String _money(double value) {
    final grouped = value.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match.group(1)},');
    return '${value < 0 ? '-' : ''}TZS $grouped';
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
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$index',
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.textLight,
                ),
            ],
          ),
          DropdownButtonFormField<int>(
            initialValue: draft.accountId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: _t('Account', 'Akaunti'),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
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
