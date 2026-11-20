import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/accounting_common_widgets.dart';

class JournalEntryPage extends StatefulWidget {
  const JournalEntryPage({super.key});

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final _memoController = TextEditingController();
  final List<JournalDraftLine> _lines = [
    JournalDraftLine(),
    JournalDraftLine(),
  ];

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  static String _formatMoney(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

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
      body: ManagementViewport(
        maxWidth: 1280,
        child: SafeArea(
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
                    LedgerCard(
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
                        child: JournalLineCard(
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
                      onTap: () =>
                          setState(() => _lines.add(JournalDraftLine())),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LedgerCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_t('Debit', 'Deni')} ${_formatMoney(debit)}   •   ${_t('Credit', 'Mkopo')} ${_formatMoney(credit)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: balanced
                                        ? AppColors.ink
                                        : AppColors.danger,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  balanced
                                      ? _t('Balanced', 'Imelingana')
                                      : '${_t('Difference', 'Tofauti')} ${_formatMoney((debit - credit).abs())}',
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
      ),
    );
  }

  Future<void> _save(PosLocalStore store) async {
    final valid = _lines
        .where((line) =>
            line.accountId != null || line.debit != 0 || line.credit != 0)
        .toList();
    if (valid.length < 2 ||
        valid.any((line) =>
            line.accountId == null ||
            !line.debit.isFinite ||
            !line.credit.isFinite ||
            line.debit < 0 ||
            line.credit < 0 ||
            (line.debit > 0) == (line.credit > 0))) {
      showMarketNotice(context,
          title: _t('Check journal lines', 'Kagua mistari ya daftari'),
          message: _t(
              'Use at least two lines. Each line needs an account and either a debit or a credit.',
              'Tumia angalau mistari miwili. Kila mstari unahitaji akaunti na deni au mkopo.'),
          type: MarketNoticeType.warning);
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

class JournalDraftLine {
  int? accountId;
  double debit = 0;
  double credit = 0;
}

class JournalLineCard extends StatelessWidget {
  const JournalLineCard({
    super.key,
    required this.index,
    required this.draft,
    required this.accounts,
    required this.isSwahili,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final JournalDraftLine draft;
  final List<Account> accounts;
  final bool isSwahili;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  String _t(String en, String swahili) => isSwahili ? swahili : en;

  @override
  Widget build(BuildContext context) {
    return LedgerCard(
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
                borderSide: BorderSide(color: AppColors.primary, width: 1.4),
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
