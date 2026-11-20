import 'package:flutter/material.dart';

import '../../service/register_shift_model.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';

class CashMovementPage extends StatefulWidget {
  const CashMovementPage({
    super.key,
    required this.type,
    required this.isSwahili,
    required this.onSave,
  });

  final CashMovementType type;
  final bool isSwahili;
  final Future<void> Function(double amount, String reason) onSave;

  @override
  State<CashMovementPage> createState() => _CashMovementPageState();
}

class _CashMovementPageState extends State<CashMovementPage> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _saving = false;

  String _t(String en, String sw) => widget.isSwahili ? sw : en;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String get _title => widget.type.localized(widget.isSwahili);

  String get _subtitle {
    switch (widget.type) {
      case CashMovementType.cashIn:
        return _t('Add cash to the drawer (e.g. float top-up).',
            'Ongeza pesa kazini (mf. kuongeza float).');
      case CashMovementType.payout:
        return _t('Record cash paid out from the drawer.',
            'Rekodi pesa iliyotolewa kutoka kazini.');
      case CashMovementType.drop:
        return _t('Record cash moved to a safe or bank deposit.',
            'Rekodi pesa iliyohamishwa salama au benki.');
    }
  }

  String get _hint {
    switch (widget.type) {
      case CashMovementType.cashIn:
        return _t('Float top-up, change fund...',
            'Kuongeza float, fedha ya chenji...');
      case CashMovementType.payout:
        return _t('Supplier, transport, petty expense...',
            'Msambazaji, usafiri, matumizi madogo...');
      case CashMovementType.drop:
        return _t('Safe drop, bank deposit reference...',
            'Amana salama, rejea ya benki...');
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      showMarketNotice(
        context,
        title: _t('Amount required', 'Kiasi kinahitajika'),
        message: _t('Enter a valid amount greater than zero.',
            'Weka kiasi sahihi zaidi ya sifuri.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(amount, _reasonController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                title: _title,
                subtitle: _subtitle,
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(16),
                      showShadow: false,
                      borderColor: AppColors.border,
                      radius: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarketFormField(
                            label: _t('Amount (TSh)', 'Kiasi (TSh)'),
                            hintText: '0',
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            prefixIcon:
                                const Icon(Icons.payments_outlined, size: 18),
                          ),
                          const SizedBox(height: 16),
                          MarketFormField(
                            label: _t(
                                'Reason / reference', 'Sababu / kumbukumbu'),
                            hintText: _hint,
                            controller: _reasonController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MarketButton(
                      label: _saving
                          ? _t('Saving...', 'Inahifadhi...')
                          : _t('Save movement', 'Hifadhi'),
                      icon: Icons.check_rounded,
                      onTap: _saving ? null : _save,
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
}
