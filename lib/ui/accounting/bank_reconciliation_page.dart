import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

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
                      _flatCard(
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
                        onTap:
                            entries.isEmpty ? null : () => _autoMatch(context),
                      ),
                      const SizedBox(height: 20),
                      _sectionHeader(t('Statement lines', 'Mistari ya taarifa'),
                          trailing:
                              '${entries.length} ${t('lines', 'mistari')}'),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        _flatCard(
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
                        _flatCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _tableHeader(t),
                              const Divider(
                                  height: 1, color: AppColors.divider),
                              for (var i = 0; i < entries.length; i++) ...[
                                _StatementRow(
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
          )),
    );
  }

  static void _openAddLine(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _BankLineFormPage(),
      ),
    );
  }

  static void _openImport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _ImportStatementPage(),
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

  static Widget _flatCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return MarketSurfaceCard(
      padding: padding,
      showShadow: false,
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      child: child,
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
    return _flatCard(
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

class _StatementRow extends StatelessWidget {
  const _StatementRow({required this.entry, required this.isSwahili});
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
                  '${inflow ? '+' : '-'}${BankReconciliationPage._money(entry.amount.abs())}',
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

class _BankLineFormPage extends StatefulWidget {
  const _BankLineFormPage();

  @override
  State<_BankLineFormPage> createState() => _BankLineFormPageState();
}

class _BankLineFormPageState extends State<_BankLineFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _account = TextEditingController();
  late DateTime _date;
  bool _inflow = true;
  bool _saving = false;

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';
  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _reference.dispose();
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: _t('Add statement line', 'Ongeza mstari wa taarifa'),
                  subtitle: _t('Bank or mobile money transaction',
                      'Muamala wa benki au mtandao wa simu'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        _sectionCard(
                          title:
                              _t('Transaction details', 'Taarifa za muamala'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_t('Type', 'Aina'),
                                  style: AppTypography.label
                                      .copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _typeToggle(
                                      label: _t('Money in', 'Pesa imeingia'),
                                      selected: _inflow,
                                      color: AppColors.success,
                                      onTap: () =>
                                          setState(() => _inflow = true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _typeToggle(
                                      label: _t('Money out', 'Pesa imetoka'),
                                      selected: !_inflow,
                                      color: AppColors.danger,
                                      onTap: () =>
                                          setState(() => _inflow = false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide:
                                          BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide:
                                          BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: BorderSide(
                                          color: AppColors.primary, width: 1.4),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(_t('Date', 'Tarehe'),
                                                style: AppTypography.helperText
                                                    .copyWith(
                                                        color: AppColors
                                                            .textMuted)),
                                            const SizedBox(height: 2),
                                            Text(
                                              _date
                                                  .toLocal()
                                                  .toString()
                                                  .substring(0, 10),
                                              style: AppTypography.bodyMain
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 18, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              MarketFormField(
                                label: _t('Description', 'Maelezo'),
                                hintText: _t(
                                    'e.g. M-Pesa deposit, bank transfer',
                                    'mf. Amana ya M-Pesa, uhamisho wa benki'),
                                controller: _description,
                                validator: (v) => (v == null ||
                                        v.trim().isEmpty)
                                    ? _t('Enter a description', 'Weka maelezo')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              MarketFormField(
                                label: _t('Amount (TSh)', 'Kiasi (TSh)'),
                                hintText: '0',
                                controller: _amount,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) => (double.tryParse((v ?? '')
                                                .replaceAll(',', '')) ??
                                            0) <=
                                        0
                                    ? _t('Enter a valid amount',
                                        'Weka kiasi sahihi')
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _sectionCard(
                          title: _t('Reference & account', 'Rejea na akaunti'),
                          child: Column(
                            children: [
                              MarketFormField(
                                label:
                                    _t('Reference (optional)', 'Rejea (hiari)'),
                                hintText: _t('Receipt / transaction ID',
                                    'Namba ya risiti / muamala'),
                                controller: _reference,
                              ),
                              const SizedBox(height: 14),
                              MarketFormField(
                                label: _t('Account name', 'Jina la akaunti'),
                                hintText: _t('Bank, M-Pesa, Airtel Money...',
                                    'Benki, M-Pesa, Airtel Money...'),
                                controller: _account,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        MarketButton(
                          label: _saving
                              ? _t('Saving...', 'Inahifadhi...')
                              : _t('Save statement line',
                                  'Hifadhi mstari wa taarifa'),
                          icon: Icons.check_rounded,
                          onTap: _saving ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _typeToggle({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.surface,
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? color : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textBody,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return BankReconciliationPage._flatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  AppTypography.sectionHeader.copyWith(color: AppColors.ink)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = double.tryParse(_amount.text.trim().replaceAll(',', '')) ?? 0;
    if (raw <= 0) return;
    setState(() => _saving = true);
    try {
      final store = context.read<PosLocalStore>();
      final account = _account.text.trim();
      await store.addBankTransaction(
        BankTransaction(
          date: _date,
          description: _description.text.trim(),
          amount: _inflow ? raw : -raw,
          reference: _reference.text.trim(),
          accountName:
              account.isEmpty ? (_isSwahili ? 'Benki' : 'Bank') : account,
        ),
      );
      if (!mounted) return;
      showMarketNotice(
        context,
        title: _t('Bank reconciliation', 'Upatanishi wa benki'),
        message: _t('Statement line added', 'Mstari wa taarifa umeongezwa'),
        type: MarketNoticeType.success,
      );
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ImportStatementPage extends StatefulWidget {
  const _ImportStatementPage();

  @override
  State<_ImportStatementPage> createState() => _ImportStatementPageState();
}

class _ImportStatementPageState extends State<_ImportStatementPage> {
  final _controller = TextEditingController();
  bool _saving = false;

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';
  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: _t('Import statement', 'Ingiza taarifa'),
                  subtitle: _t('Paste lines from bank or mobile money',
                      'Bandika mistari kutoka benki au mtandao wa simu'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      BankReconciliationPage._flatCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('Format', 'Muundo'),
                              style: AppTypography.sectionHeader
                                  .copyWith(color: AppColors.ink),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _t(
                                'One line per transaction: date, description, amount.\nUse comma, tab, or semicolon. Positive = money in, negative = money out.',
                                'Mstari mmoja kwa muamala: tarehe, maelezo, kiasi.\nTumia koma, tab, au nukta mkato. Chanya = imeingia, hasi = imetoka.',
                              ),
                              style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted, height: 1.45),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '2026-01-31, M-Pesa deposit, 150000\n2026-02-01, Supplier payment, -45000',
                                style: AppTypography.helperText.copyWith(
                                  color: AppColors.textBody,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      BankReconciliationPage._flatCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Statement lines', 'Mistari ya taarifa'),
                                style: AppTypography.label
                                    .copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _controller,
                              maxLines: 10,
                              minLines: 6,
                              decoration: const InputDecoration(
                                hintText: '2026-01-31, M-Pesa deposit, 150000',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide:
                                      BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide:
                                      BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(
                                      color: AppColors.primary, width: 1.4),
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                                isDense: true,
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      MarketButton(
                        label: _saving
                            ? _t('Importing...', 'Inaingiza...')
                            : _t('Import lines', 'Ingiza mistari'),
                        icon: Icons.download_done_rounded,
                        onTap: _saving ? null : _import,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Future<void> _import() async {
    final rows = _controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    if (rows.isEmpty) {
      showMarketNotice(
        context,
        title: _t('Nothing to import', 'Hakuna cha kuingiza'),
        message: _t('Paste at least one statement line.',
            'Bandika angalau mstari mmoja wa taarifa.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final store = context.read<PosLocalStore>();
      var imported = 0;
      for (final row in rows) {
        final parts = row
            .split(RegExp(r'[,\t;]'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.length < 3) continue;
        final amount = double.tryParse(
            parts.last.replaceAll(',', '').replaceAll('TSh', '').trim());
        if (amount == null || amount == 0) continue;
        final date = DateTime.tryParse(parts.first) ?? DateTime.now();
        final description = parts.length > 2
            ? parts.sublist(1, parts.length - 1).join(' ').trim()
            : parts[1];
        await store.addBankTransaction(
          BankTransaction(
            date: date,
            description: description,
            amount: amount,
            accountName: _isSwahili ? 'Benki' : 'Bank',
          ),
        );
        imported++;
      }
      if (!mounted) return;
      if (imported == 0) {
        showMarketNotice(
          context,
          title: _t('Import', 'Uingizaji'),
          message: _t(
            'No valid lines found. Check the format: date, description, amount.',
            'Hakuna mistari sahihi. Angalia muundo: tarehe, maelezo, kiasi.',
          ),
          type: MarketNoticeType.warning,
        );
        return;
      }
      showMarketNotice(
        context,
        title: _t('Import complete', 'Uingizaji umekamilika'),
        message: _t('$imported line${imported == 1 ? '' : 's'} imported',
            'Mistari $imported imeingizwa'),
        type: MarketNoticeType.success,
      );
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
