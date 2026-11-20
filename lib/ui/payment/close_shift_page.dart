import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../service/pos_local_store.dart';
import '../../service/register_shift_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/register_models.dart';

class CloseShiftPage extends StatefulWidget {
  const CloseShiftPage({
    super.key,
    required this.shift,
    required this.summary,
    required this.isSwahili,
    required this.onClose,
  });

  final RegisterShift shift;
  final CashUpSummary summary;
  final bool isSwahili;
  final Future<void> Function(double counted, String notes) onClose;

  @override
  State<CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<CloseShiftPage> {
  late final TextEditingController _countedController;
  final TextEditingController _notesController = TextEditingController();
  static const _denoms = <int>[10000, 5000, 2000, 1000, 500, 200, 100, 50];
  late final Map<int, TextEditingController> _counts;
  bool _saving = false;

  String _t(String en, String sw) => widget.isSwahili ? sw : en;

  @override
  void initState() {
    super.initState();
    _countedController =
        TextEditingController(text: widget.summary.expected.toStringAsFixed(0));
    _counts = {for (final d in _denoms) d: TextEditingController(text: '0')};
  }

  @override
  void dispose() {
    _countedController.dispose();
    _notesController.dispose();
    for (final c in _counts.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _denomTotal {
    var total = 0.0;
    for (final d in _denoms) {
      final qty = int.tryParse(_counts[d]!.text.trim()) ?? 0;
      total += d * qty;
    }
    return total;
  }

  void _applyDenoms() {
    _countedController.text = _denomTotal.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _close() async {
    final counted = double.tryParse(_countedController.text.trim()) ?? 0;
    if (counted < 0) {
      showMarketNotice(
        context,
        title: _t('Invalid amount', 'Kiasi si sahihi'),
        message: _t('Counted cash cannot be negative.',
            'Pesa iliyohesabiwa haiwezi kuwa hasi.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onClose(counted, _notesController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counted = double.tryParse(_countedController.text.trim()) ?? 0;
    final variance = counted - widget.summary.expected;
    final balanced = variance.abs() < 0.5;
    final s = widget.summary;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
        maxWidth: 860,
        child: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title:
                    _t('Close register & cash up', 'Funga kasha na hesabu'),
                subtitle:
                    '${widget.shift.register} • ${_t('Count and confirm', 'Hesabu na thibitisha')}',
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    _card(
                      child: Column(
                        children: [
                          _row(_t('Opening float', 'Pesa ya kuanzia'),
                              s.openingFloat),
                          _row(_t('Cash sales', 'Mauzo ya taslimu'),
                              s.cashSales),
                          _row(_t('Cash in', 'Pesa kuingia'), s.cashIn),
                          _row(_t('Payouts & drops', 'Malipo na amana'),
                              -s.cashOut),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child:
                                Divider(height: 1, color: AppColors.divider),
                          ),
                          _row(_t('Expected in drawer', 'Inayotarajiwa'),
                              s.expected,
                              strong: true),
                          const SizedBox(height: 10),
                          _varianceBar(balanced, variance),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                        _t('Denomination count (optional)',
                            'Hesabu ya noti/sarafu (hiari)'),
                        style: AppTypography.sectionHeader
                            .copyWith(color: AppColors.ink)),
                    const SizedBox(height: 8),
                    _card(child: _denomGrid()),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _applyDenoms,
                        icon: const Icon(Icons.calculate_outlined, size: 16),
                        label: Text(_t('Use denomination total',
                            'Tumia jumla ya hesabu')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarketFormField(
                            label: _t('Counted cash (TSh)',
                                'Pesa iliyohesabiwa (TSh)'),
                            hintText: s.expected.toStringAsFixed(0),
                            controller: _countedController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          MarketFormField(
                            label: _t('Closing notes', 'Maelezo ya kufunga'),
                            hintText: _t(
                                'Variance reason, handover notes (optional)',
                                'Sababu ya tofauti, maelezo ya kukabidhi (hiari)'),
                            controller: _notesController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MarketButton(
                      label: _saving
                          ? _t('Closing...', 'Inafunga...')
                          : _t('Confirm close shift',
                              'Thibitisha kufunga zamu'),
                      icon: Icons.lock_outline_rounded,
                      color: AppColors.ink,
                      onTap: _saving ? null : _close,
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

  Widget _card({required Widget child}) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      showShadow: false,
      borderColor: AppColors.border,
      radius: 0,
      child: child,
    );
  }

  Widget _varianceBar(bool balanced, double variance) {
    final Color color;
    final String text;
    if (balanced) {
      color = AppColors.success;
      text = _t('Balanced — no variance', 'Sawa — hakuna tofauti');
    } else if (variance > 0) {
      color = AppColors.primaryDeep;
      text = _t('Over by ${formatRegisterMoney(variance)}',
          'Ziada ${formatRegisterMoney(variance)}');
    } else {
      color = AppColors.danger;
      text = _t('Short by ${formatRegisterMoney(variance.abs())}',
          'Upungufu ${formatRegisterMoney(variance.abs())}');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _row(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: strong ? AppColors.ink : AppColors.textMuted,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            formatRegisterMoney(value),
            style: AppTypography.bodySmall.copyWith(
              color: value < 0 ? AppColors.danger : AppColors.ink,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _denomGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        for (final d in _denoms)
          SizedBox(
            width: 150,
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    formatCurrency(d.toDouble()),
                    style: AppTypography.helperText.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.textBody),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _counts[d],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        hintText: '0',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      style: AppTypography.bodySmall,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
