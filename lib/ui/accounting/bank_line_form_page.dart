import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/reconciliation_models.dart';

class BankLineFormPage extends StatefulWidget {
  const BankLineFormPage({super.key});

  @override
  State<BankLineFormPage> createState() => _BankLineFormPageState();
}

class _BankLineFormPageState extends State<BankLineFormPage> {
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
                        title: _t('Transaction details', 'Taarifa za muamala'),
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
                                    onTap: () => setState(() => _inflow = true),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _typeToggle(
                                    label: _t('Money out', 'Pesa imetoka'),
                                    selected: !_inflow,
                                    color: AppColors.danger,
                                    onTap: () => setState(() => _inflow = false),
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
                              hintText: _t('e.g. M-Pesa deposit, bank transfer',
                                  'mf. Amana ya M-Pesa, uhamisho wa benki'),
                              controller: _description,
                              validator: (v) => (v == null || v.trim().isEmpty)
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
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                      top: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: MarketButton(
                        label: _t('Cancel', 'Ghairi'),
                        color: AppColors.kpiDangerBg,
                        foregroundColor: AppColors.kpiDanger,
                        borderColor: null,
                        radius: 0,
                        onTap: _saving
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: MarketButton(
                        label: _saving
                            ? _t('Saving...', 'Inahifadhi...')
                            : _t('Save statement line',
                                'Hifadhi mstari wa taarifa'),
                        icon: Icons.check_rounded,
                        variant: MarketButtonVariant.primary,
                        borderColor: null,
                        radius: 0,
                        height: 48,
                        onTap: _saving ? null : _save,
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
    return ReconciliationCard(
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
