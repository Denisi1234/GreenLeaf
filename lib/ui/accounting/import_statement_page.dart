import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/reconciliation_models.dart';

/// A safe three-step statement import: paste, confirm mapped columns, review.
class ImportStatementPage extends StatefulWidget {
  const ImportStatementPage({super.key});

  @override
  State<ImportStatementPage> createState() => _ImportStatementPageState();
}

class _ImportStatementPageState extends State<ImportStatementPage> {
  final _input = TextEditingController();
  var _step = 0;
  var _saving = false;
  List<String> _headers = const [];
  List<List<String>> _rows = const [];
  int? _date, _description, _amount, _debit, _credit, _reference;

  bool get _sw =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';
  String _t(String en, String sw) => _sw ? sw : en;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<_StatementLine> get _preview =>
      _rows.map(_makeLine).whereType<_StatementLine>().toList(growable: false);
  bool get _ready =>
      _date != null &&
      _description != null &&
      (_amount != null || _debit != null || _credit != null) &&
      _preview.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final titles = [
      _t('Paste statement', 'Bandika taarifa'),
      _t('Map columns', 'Panga safu wima'),
      _t('Review import', 'Kagua uingizaji')
    ];
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
        maxWidth: 860,
        child: SafeArea(
          child: Column(children: [
            MarketPageHeader(
              title: _t('Import statement', 'Ingiza taarifa'),
              subtitle: titles[_step],
              transparentBackButton: true,
              onBack: () => _step == 0
                  ? Navigator.of(context).maybePop()
                  : setState(() => _step -= 1),
            ),
            _steps(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _step == 0
                      ? _paste()
                      : _step == 1
                          ? _mapping()
                          : _review()
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _steps() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
            children: List.generate(
                3,
                (i) => Expanded(
                        child: Row(children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= _step
                                ? AppColors.primary
                                : AppColors.surfaceSecondary),
                        child: Text('${i + 1}',
                            style: AppTypography.helperText.copyWith(
                                color: i <= _step
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w800)),
                      ),
                      if (i < 2)
                        Expanded(
                            child: Container(
                                height: 2,
                                color: i < _step
                                    ? AppColors.primary
                                    : AppColors.border)),
                    ])))),
      );

  Widget _paste() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ReconciliationCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('Copy a statement export', 'Nakili taarifa iliyohamishwa'),
              style:
                  AppTypography.sectionHeader.copyWith(color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(
              _t('Paste a CSV, TSV, spreadsheet, or mobile-money statement below. We automatically find common date, description, amount, debit, credit, and reference columns.',
                  'Bandika CSV, TSV, lahajedwali, au taarifa ya pesa za simu hapa chini. Tunatambua tarehe, maelezo, kiasi, debit, credit na rejea kiotomatiki.'),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted, height: 1.45)),
          const SizedBox(height: 12),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: AppCorners.control,
                  border: Border.all(color: AppColors.border)),
              child: Text(
                  'Date, Description, Amount, Reference\n2026-01-31, M-Pesa deposit, 150000, MPX001\n2026-02-01, Supplier payment, -45000, MPX002',
                  style: AppTypography.helperText
                      .copyWith(fontWeight: FontWeight.w600, height: 1.5))),
        ])),
        const SizedBox(height: 12),
        ReconciliationCard(
            child: TextField(
                controller: _input,
                maxLines: 12,
                minLines: 8,
                decoration: InputDecoration(
                    labelText: _t('Statement data', 'Data ya taarifa'),
                    hintText: _t('Paste statement rows here',
                        'Bandika mistari ya taarifa hapa'),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppColors.pageBackground,
                    border: OutlineInputBorder(
                        borderRadius: AppCorners.input,
                        borderSide: BorderSide(color: AppColors.border))))),
        const SizedBox(height: 20),
        MarketButton(
            label: _t('Detect columns', 'Tambua safu wima'),
            icon: Icons.auto_awesome_outlined,
            onTap: _detect),
      ]);

  Widget _mapping() {
    final count = _preview.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ReconciliationCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t('Confirm column mapping', 'Thibitisha upangaji wa safu wima'),
            style: AppTypography.sectionHeader.copyWith(color: AppColors.ink)),
        const SizedBox(height: 6),
        Text(
            _t('The suggested mapping is based on your statement headings. Adjust it before the review.',
                'Mpangilio uliopendekezwa unatokana na vichwa vya taarifa yako. Urekebishe kabla ya ukaguzi.'),
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        _picker(_t('Date', 'Tarehe'), _date, (v) => setState(() => _date = v)),
        _picker(_t('Description', 'Maelezo'), _description,
            (v) => setState(() => _description = v)),
        _picker(
            _t('Amount', 'Kiasi'), _amount, (v) => setState(() => _amount = v),
            optional: true),
        _picker(_t('Debit / money out', 'Debit / pesa iliyotoka'), _debit,
            (v) => setState(() => _debit = v),
            optional: true),
        _picker(_t('Credit / money in', 'Credit / pesa iliyoingia'), _credit,
            (v) => setState(() => _credit = v),
            optional: true),
        _picker(_t('Reference', 'Rejea'), _reference,
            (v) => setState(() => _reference = v),
            optional: true),
      ])),
      const SizedBox(height: 12),
      ReconciliationCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(
                count > 0
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: count > 0 ? AppColors.success : AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    count > 0
                        ? _t('$count valid lines are ready for review.',
                            'Mistari $count sahihi iko tayari kukaguliwa.')
                        : _t(
                            'Choose date, description, and amount or debit/credit columns to continue.',
                            'Chagua tarehe, maelezo, na kiasi au safu wima za debit/credit ili kuendelea.'),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textBody)))
          ])),
      const SizedBox(height: 20),
      MarketButton(
          label: _t('Review $count lines', 'Kagua mistari $count'),
          icon: Icons.fact_check_outlined,
          onTap: _ready ? () => setState(() => _step = 2) : null),
    ]);
  }

  Widget _picker(String label, int? value, ValueChanged<int?> change,
          {bool optional = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<int?>(
          key: ValueKey<int?>(value),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
              labelText:
                  optional ? '$label (${_t('optional', 'hiari')})' : label,
              filled: true,
              fillColor: AppColors.pageBackground,
              border: const OutlineInputBorder(borderRadius: AppCorners.input)),
          items: [
            DropdownMenuItem<int?>(
                value: null, child: Text(_t('Not imported', 'Usiingize'))),
            ...List.generate(
                _headers.length,
                (i) =>
                    DropdownMenuItem<int?>(value: i, child: Text(_headers[i])))
          ],
          onChanged: change,
        ),
      );

  Widget _review() {
    final lines = _preview;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ReconciliationCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t('Ready to import', 'Tayari kuingiza'),
            style: AppTypography.sectionHeader.copyWith(color: AppColors.ink)),
        const SizedBox(height: 5),
        Text(
            _t('Only these reviewed lines will be added. Nothing has been saved yet.',
                'Mistari hii iliyokaguliwa pekee ndiyo itaongezwa. Bado hakuna kilichohifadhiwa.'),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))
      ])),
      const SizedBox(height: 12),
      ...lines.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ReconciliationCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(
                    line.amount >= 0
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: line.amount >= 0
                        ? AppColors.success
                        : AppColors.danger),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(line.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          '${_dateText(line.date)}${line.reference.isEmpty ? '' : ' • ${line.reference}'}',
                          style: AppTypography.helperText
                              .copyWith(color: AppColors.textMuted))
                    ])),
                Text(
                    '${line.amount >= 0 ? '+' : '-'}${line.amount.abs().toStringAsFixed(2)}',
                    style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: line.amount >= 0
                            ? AppColors.success
                            : AppColors.danger))
              ])))),
      const SizedBox(height: 12),
      MarketButton(
          label: _saving
              ? _t('Importing...', 'Inaingiza...')
              : _t('Import ${lines.length} reviewed lines',
                  'Ingiza mistari ${lines.length} iliyokaguliwa'),
          icon: Icons.download_done_rounded,
          onTap: _saving || lines.isEmpty ? null : _import),
    ]);
  }

  void _detect() {
    final raw = _input.text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (raw.isEmpty) {
      return _notice(_t('Paste at least one statement line.',
          'Bandika angalau mstari mmoja wa taarifa.'));
    }
    final separator = raw.first.contains('\t')
        ? '\t'
        : raw.first.contains(';')
            ? ';'
            : ',';
    final parsed = raw
        .map((line) => line
            .split(separator)
            .map((cell) => cell.trim().replaceAll(RegExp(r'^"|"$'), ''))
            .toList())
        .toList();
    final headersPresent = parsed.first.any((cell) => RegExp(
            r'date|tarehe|description|details|amount|kiasi|debit|credit|reference|rejea',
            caseSensitive: false)
        .hasMatch(cell));
    final headers = headersPresent
        ? parsed.first
        : List.generate(parsed.first.length,
            (i) => _t('Column ${i + 1}', 'Safu wima ${i + 1}'));
    int? find(String terms) {
      final index = headers.indexWhere(
          (header) => RegExp(terms, caseSensitive: false).hasMatch(header));
      return index < 0 ? null : index;
    }

    setState(() {
      _headers = headers;
      _rows = headersPresent ? parsed.skip(1).toList() : parsed;
      _date = find(r'date|tarehe') ?? 0;
      _description = find(r'description|details|narration|maelezo') ??
          (headers.length > 1 ? 1 : null);
      _amount = find(r'amount|kiasi|value') ?? (headers.length > 2 ? 2 : null);
      _debit = find(r'debit|withdraw|out');
      _credit = find(r'credit|deposit|in');
      _reference = find(r'reference|ref|receipt|rejea');
      _step = 1;
    });
  }

  _StatementLine? _makeLine(List<String> row) {
    String cell(int? index) =>
        index == null || index < 0 || index >= row.length ? '' : row[index];
    final date = DateTime.tryParse(cell(_date));
    final description = cell(_description);
    final amount = _amount == null
        ? _money(cell(_credit)) - _money(cell(_debit))
        : _money(cell(_amount));
    if (date == null || description.isEmpty || amount == 0) return null;
    return _StatementLine(date, description, amount, cell(_reference));
  }

  double _money(String value) {
    var clean = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (clean.contains(',') && !clean.contains('.')) {
      clean = clean.replaceAll(',', '.');
    }
    if (clean.contains(',') && clean.contains('.')) {
      clean = clean.replaceAll(',', '');
    }
    return double.tryParse(clean) ?? 0;
  }

  Future<void> _import() async {
    final lines = _preview;
    setState(() => _saving = true);
    try {
      final store = context.read<PosLocalStore>();
      for (final line in lines) {
        await store.addBankTransaction(BankTransaction(
            date: line.date,
            description: line.description,
            amount: line.amount,
            reference: line.reference,
            accountName: _sw ? 'Benki' : 'Bank'));
      }
      if (!mounted) return;
      showMarketNotice(context,
          title: _t('Import complete', 'Uingizaji umekamilika'),
          message: _t(
              '${lines.length} reviewed line${lines.length == 1 ? '' : 's'} imported',
              'Mistari ${lines.length} iliyokaguliwa imeingizwa'),
          type: MarketNoticeType.success);
      Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) {
        _notice(_t('The statement could not be imported. Please try again.',
            'Taarifa haikuweza kuingizwa. Tafadhali jaribu tena.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String message) => showMarketNotice(context,
      title: _t('Statement import', 'Uingizaji wa taarifa'),
      message: message,
      type: MarketNoticeType.warning);
  String _dateText(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _StatementLine {
  const _StatementLine(
      this.date, this.description, this.amount, this.reference);
  final DateTime date;
  final String description;
  final double amount;
  final String reference;
}
