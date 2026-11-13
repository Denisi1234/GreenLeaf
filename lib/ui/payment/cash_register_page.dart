import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../../service/register_shift_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

/// Professional cash register: shift control, drawer movements, cash-up, and
/// reconciliation against sales recorded during the open shift.
class CashRegisterPage extends StatefulWidget {
  const CashRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CashRegisterPage> createState() => _CashRegisterPageState();
}

class _CashRegisterPageState extends State<CashRegisterPage> {
  final TextEditingController _floatController = TextEditingController();
  final TextEditingController _registerController =
      TextEditingController(text: 'Register 1');
  final TextEditingController _countedController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool get _isSwahili =>
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String sw) => _isSwahili ? sw : en;

  @override
  void dispose() {
    _floatController.dispose();
    _registerController.dispose();
    _countedController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final shift = store.openShift;

    final body = shift == null
        ? _buildClosedState(store)
        : _buildOpenState(store, shift);

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: _t('Cash Register', 'Kasha la Pesa'),
              subtitle: shift == null
                  ? _t('Register closed', 'Kasha limefungwa')
                  : '${shift.register} • ${_t('Open', 'Wazi')}',
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedState(PosLocalStore store) {
    final history = store.registerShifts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        MarketSurfaceCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.standard),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: AppColors.primaryDeep,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Open a register shift', 'Fungua zamu ya kasha'),
                          style: AppTypography.h3.copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _t(
                            'Count opening cash, track drawer movements, and cash up with full reconciliation at close.',
                            'Hesabu pesa ya kuanzia, fuatilia mienendo ya kasha, na funga kwa hesabu kamili.',
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              MarketFormField(
                label: _t('Register name', 'Jina la kasha'),
                hintText: _t('e.g. Front Counter, Register 1', 'mf. Kaunta, Kasha 1'),
                controller: _registerController,
              ),
              const SizedBox(height: AppSpacing.md),
              MarketFormField(
                label: _t('Opening float (TSh)', 'Pesa ya kuanzia (TSh)'),
                hintText: '0',
                controller: _floatController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.payments_outlined, size: 18),
              ),
              const SizedBox(height: AppSpacing.lg),
              MarketButton(
                label: _t('Open Register', 'Fungua Kasha'),
                icon: Icons.lock_open_rounded,
                onTap: () => _openShift(store),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _infoTips(),
        if (history.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          MarketSurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t('Shift history', 'Historia ya zamu'),
                        style: AppTypography.label,
                      ),
                    ),
                    Text(
                      _t('${history.length} total', 'Jumla ${history.length}'),
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final past in history.take(12))
                  _ShiftTile(
                    shift: past,
                    summary: store.cashUpFor(past),
                    isSwahili: _isSwahili,
                    onTap: () => _showShiftDetail(store, past),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoTips() {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.surfaceSecondary,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('Best practice', 'Mwongozo'),
              style: AppTypography.label.copyWith(color: AppColors.ink)),
          const SizedBox(height: 8),
          _tip(Icons.calculate_outlined,
              _t('Count the drawer before opening and after closing.', 'Hesabu kasha kabla ya kufungua na baada ya kufunga.')),
          _tip(Icons.receipt_long_outlined,
              _t('Record payouts, drops, and cash added during the shift.', 'Rekodi malipo, pesa zilizotolewa benki, na pesa zilizoongezwa.')),
          _tip(Icons.fact_check_outlined,
              _t('Cash sales are reconciled automatically from completed orders.', 'Mauzo ya taslimu huhesabiwa kiotomatiki kutoka oda zilizokamilika.')),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textBody, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenState(PosLocalStore store, RegisterShift shift) {
    final summary = store.cashUpFor(shift);
    final sales = _shiftSales(store, shift);
    final paymentBreakdown = _paymentBreakdown(sales);
    final txCount = sales.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _ShiftStatusBanner(shift: shift, isSwahili: _isSwahili),
        const SizedBox(height: AppSpacing.md),
        _ExpectedDrawerCard(summary: summary, isSwahili: _isSwahili),
        const SizedBox(height: AppSpacing.md),
        _MetricsGrid(
          summary: summary,
          txCount: txCount,
          isSwahili: _isSwahili,
        ),
        const SizedBox(height: AppSpacing.md),
        _PaymentBreakdownCard(
          breakdown: paymentBreakdown,
          isSwahili: _isSwahili,
        ),
        const SizedBox(height: AppSpacing.lg),
        _ActionRow(
          isSwahili: _isSwahili,
          onCashIn: () => _showMovementDialog(store, CashMovementType.cashIn),
          onPayout: () => _showMovementDialog(store, CashMovementType.payout),
          onDrop: () => _showMovementDialog(store, CashMovementType.drop),
        ),
        const SizedBox(height: AppSpacing.md),
        MarketButton(
          label: _t('Close Register & Cash Up', 'Funga Kasha na Hesabu'),
          icon: Icons.lock_outline_rounded,
          color: AppColors.ink,
          onTap: () => _showCloseDialog(store, shift),
        ),
        const SizedBox(height: AppSpacing.lg),
        _MovementsSection(
          shift: shift,
          isSwahili: _isSwahili,
          onDelete: (movement) => _deleteMovement(store, movement),
        ),
      ],
    );
  }

  List<CompletedOrder> _shiftSales(PosLocalStore store, RegisterShift shift) {
    final end = shift.endsAt;
    return store.orders.where((order) {
      if (order.status.trim().toLowerCase() == 'voided') return false;
      final at = DateTime.tryParse(order.dateTime);
      if (at == null) return false;
      return !at.isBefore(shift.openedAt) && !at.isAfter(end);
    }).toList();
  }

  Map<String, double> _paymentBreakdown(List<CompletedOrder> sales) {
    final out = <String, double>{};
    for (final order in sales) {
      final key = _paymentLabel(order.paymentMethod);
      out[key] = (out[key] ?? 0) + order.total;
    }
    return out;
  }

  String _paymentLabel(String method) {
    final v = method.trim().toLowerCase();
    if (v.contains('cash')) return _t('Cash', 'Taslimu');
    if (v.contains('card')) return _t('Card', 'Kadi');
    if (v.contains('credit') || v.contains('debt')) {
      return _t('Credit', 'Mkopo');
    }
    if (v.contains('mobile') ||
        v.contains('mpesa') ||
        v.contains('tigo') ||
        v.contains('airtel') ||
        v.contains('mixx')) {
      return _t('Mobile money', 'Pesa mtandao');
    }
    return method.trim().isEmpty ? _t('Other', 'Nyingine') : method.trim();
  }

  Future<void> _openShift(PosLocalStore store) async {
    final float = double.tryParse(_floatController.text.trim()) ?? 0;
    if (float < 0) {
      _notify(
        _t('Opening float cannot be negative', 'Pesa ya kuanzia haiwezi kuwa hasi'),
        error: true,
      );
      return;
    }
    final shift = await store.startShift(
      register: _registerController.text.trim().isEmpty
          ? 'Register 1'
          : _registerController.text.trim(),
      openedBy: store.profile.ownerName.isEmpty
          ? 'Cashier'
          : store.profile.ownerName,
      openingFloat: float,
    );
    if (!mounted) return;
    if (shift == null) {
      _notify(
        _t('A register is already open', 'Kasha tayari liko wazi'),
        error: true,
      );
      return;
    }
    _floatController.clear();
    _notify(_t('Register opened', 'Kasha limefunguliwa'));
  }

  Future<void> _showMovementDialog(
    PosLocalStore store,
    CashMovementType type,
  ) async {
    _amountController.clear();
    _reasonController.clear();
    final result = await showDialog<_MovementInput>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(type.localized(_isSwahili)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MarketFormField(
                label: _t('Amount (TSh)', 'Kiasi (TSh)'),
                hintText: '0',
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              MarketFormField(
                label: _t('Reason / reference', 'Sababu / kumbukumbu'),
                hintText: _movementHint(type),
                controller: _reasonController,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(_amountController.text.trim());
              if (value == null || value <= 0) return;
              Navigator.of(context).pop(
                _MovementInput(value, _reasonController.text.trim()),
              );
            },
            child: Text(_t('Save', 'Hifadhi')),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    await store.addCashMovement(
      type: type,
      amount: result.amount,
      reason: result.reason,
      recordedBy: store.profile.ownerName.isEmpty
          ? 'Cashier'
          : store.profile.ownerName,
    );
    if (!mounted) return;
    _notify(_t('${type.localized(_isSwahili)} recorded', '${type.localized(_isSwahili)} imerekodiwa'));
  }

  String _movementHint(CashMovementType type) {
    switch (type) {
      case CashMovementType.cashIn:
        return _t('Float top-up, change fund...', 'Kuongeza pesa, fedha ya chenji...');
      case CashMovementType.payout:
        return _t('Supplier payment, transport, petty expense...', 'Malipo ya msambazaji, usafiri, matumizi madogo...');
      case CashMovementType.drop:
        return _t('Safe drop, bank deposit...', 'Pesa kuhifadhiwa, amana benki...');
    }
  }

  Future<void> _deleteMovement(
    PosLocalStore store,
    CashMovement movement,
  ) async {
    if (movement.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_t('Remove movement?', 'Ondoa mienendo?')),
        content: Text(
          _t(
            'This removes the recorded cash movement from the open shift.',
            'Hii itaondoa rekodi ya pesa kwenye zamu iliyo wazi.',
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
            child: Text(_t('Remove', 'Ondoa')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.deleteCashMovement(movement.id!);
  }

  Future<void> _showCloseDialog(
    PosLocalStore store,
    RegisterShift shift,
  ) async {
    final summary = store.cashUpFor(shift);
    _countedController.text = summary.expected.toStringAsFixed(0);
    _notesController.clear();

    final result = await showModalBottomSheet<_CloseInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CloseRegisterSheet(
        summary: summary,
        countedController: _countedController,
        notesController: _notesController,
        isSwahili: _isSwahili,
      ),
    );
    if (result == null || !mounted) return;

    await store.closeShift(
      shift.id!,
      countedCash: result.counted,
      closedBy: store.profile.ownerName.isEmpty
          ? 'Cashier'
          : store.profile.ownerName,
      notes: result.notes,
    );
    if (!mounted) return;

    final variance = result.counted - summary.expected;
    final balanced = variance.abs() < 0.5;
    _notify(
      balanced
          ? _t('Shift closed — drawer balanced', 'Zamu imefungwa — kasha sawa')
          : _t(
              'Shift closed — variance ${_money(variance)}',
              'Zamu imefungwa — tofauti ${_money(variance)}',
            ),
      error: !balanced,
    );
  }

  Future<void> _showShiftDetail(PosLocalStore store, RegisterShift shift) async {
    final summary = store.cashUpFor(shift);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShiftDetailSheet(
        shift: shift,
        summary: summary,
        isSwahili: _isSwahili,
      ),
    );
  }

  void _notify(String message, {bool error = false}) {
    showMarketNotice(
      context,
      title: error
          ? _t('Attention', 'Angalizo')
          : _t('Cash register', 'Kasha la pesa'),
      message: message,
      type: error ? MarketNoticeType.warning : MarketNoticeType.success,
    );
  }

  static String _money(double value) {
    final negative = value < 0;
    final formatted = formatCurrency(value.abs());
    return '${negative ? '-' : ''}TSh $formatted';
  }
}

class _MovementInput {
  const _MovementInput(this.amount, this.reason);
  final double amount;
  final String reason;
}

class _CloseInput {
  const _CloseInput(this.counted, this.notes);
  final double counted;
  final String notes;
}

class _ShiftStatusBanner extends StatelessWidget {
  const _ShiftStatusBanner({required this.shift, required this.isSwahili});
  final RegisterShift shift;
  final bool isSwahili;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    final opened = shift.openedAt.toLocal();
    final since =
        '${opened.year}-${opened.month.toString().padLeft(2, '0')}-${opened.day.toString().padLeft(2, '0')} ${opened.hour.toString().padLeft(2, '0')}:${opened.minute.toString().padLeft(2, '0')}';
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.primaryLight,
      borderColor: AppColors.primarySoft,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.successBright,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${shift.register} • ${_t('Open shift', 'Zamu wazi')}',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_t('Opened', 'Ilifunguliwa')} $since • ${shift.openedBy.isEmpty ? _t('Cashier', 'Mhudumu') : shift.openedBy}',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.primaryDeep),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpectedDrawerCard extends StatelessWidget {
  const _ExpectedDrawerCard({required this.summary, required this.isSwahili});
  final CashUpSummary summary;
  final bool isSwahili;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Expected in drawer', 'Pesa inayotarajiwa kazini'),
            style: AppTypography.label,
          ),
          const SizedBox(height: 6),
          Text(
            _CashRegisterPageState._money(summary.expected),
            style: AppTypography.h1.copyWith(fontSize: 30, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Opening float + cash sales + cash in − payouts/drops',
              'Pesa ya kuanzia + mauzo ya taslimu + pesa iliyoingia − iliyotoka',
            ),
            style: AppTypography.helperText.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          _row(_t('Opening float', 'Pesa ya kuanzia'), summary.openingFloat),
          _row(_t('Cash sales', 'Mauzo ya taslimu'), summary.cashSales,
              accent: AppColors.success),
          _row(_t('Cash in', 'Pesa kuingia'), summary.cashIn,
              accent: AppColors.success),
          _row(_t('Payouts & drops', 'Malipo na amana'), -summary.cashOut,
              accent: AppColors.danger),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {Color? accent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted)),
          ),
          Text(
            _CashRegisterPageState._money(value),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: accent ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.summary,
    required this.txCount,
    required this.isSwahili,
  });
  final CashUpSummary summary;
  final int txCount;
  final bool isSwahili;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: _t('Transactions', 'Miamala'),
            value: '$txCount',
            icon: Icons.receipt_long_outlined,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MetricTile(
            label: _t('Net movement', 'Mabadiliko halisi'),
            value: _CashRegisterPageState._money(summary.cashIn - summary.cashOut),
            icon: Icons.swap_vert_rounded,
            color: (summary.cashIn - summary.cashOut) >= 0
                ? AppColors.success
                : AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(fontSize: 16, color: color),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.helperText
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _PaymentBreakdownCard extends StatelessWidget {
  const _PaymentBreakdownCard({
    required this.breakdown,
    required this.isSwahili,
  });
  final Map<String, double> breakdown;
  final bool isSwahili;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('Sales by payment method', 'Mauzo kwa njia ya malipo'),
              style: AppTypography.label),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(
              _t('No completed sales in this shift yet.', 'Hakuna mauzo yaliyokamilika katika zamu hii bado.'),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted),
            )
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textBody)),
                    ),
                    Text(
                      _CashRegisterPageState._money(e.value),
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isSwahili,
    required this.onCashIn,
    required this.onPayout,
    required this.onDrop,
  });
  final bool isSwahili;
  final VoidCallback onCashIn;
  final VoidCallback onPayout;
  final VoidCallback onDrop;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MarketButton(
                label: _t('Cash In', 'Pesa Kuingia'),
                icon: Icons.add_circle_outline_rounded,
                isPrimary: false,
                onTap: onCashIn,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MarketButton(
                label: _t('Payout', 'Malipo'),
                icon: Icons.remove_circle_outline_rounded,
                isPrimary: false,
                color: AppColors.dangerLight,
                foregroundColor: AppColors.danger,
                borderColor: AppColors.dangerBorder,
                onTap: onPayout,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MarketButton(
          label: _t('Safe Drop / Bank Deposit', 'Amana salama / Benki'),
          icon: Icons.savings_outlined,
          isPrimary: false,
          onTap: onDrop,
        ),
      ],
    );
  }
}

class _MovementsSection extends StatelessWidget {
  const _MovementsSection({
    required this.shift,
    required this.isSwahili,
    required this.onDelete,
  });
  final RegisterShift shift;
  final bool isSwahili;
  final void Function(CashMovement) onDelete;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    final movements = shift.movements.reversed.toList();
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_t('Drawer movements', 'Mienendo ya kasha'),
                    style: AppTypography.label),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${shift.movements.length}',
                  style: AppTypography.helperText
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (movements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _t(
                  'No manual movements recorded. Cash sales are tracked automatically.',
                  'Hakuna mienendo ya mkono. Mauzo ya taslimu yanafuatiliwa kiotomatiki.',
                ),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted, height: 1.4),
              ),
            )
          else
            for (final movement in movements)
              _MovementTile(
                movement: movement,
                isSwahili: isSwahili,
                onDelete: () => onDelete(movement),
              ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.movement,
    required this.isSwahili,
    required this.onDelete,
  });

  final CashMovement movement;
  final bool isSwahili;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final outflow = movement.type.isOutflow;
    final at = movement.at.toLocal();
    final time =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final icon = switch (movement.type) {
      CashMovementType.cashIn => Icons.south_west_rounded,
      CashMovementType.payout => Icons.north_east_rounded,
      CashMovementType.drop => Icons.savings_outlined,
    };
    final color = outflow ? AppColors.danger : AppColors.success;
    final bg = outflow ? AppColors.dangerLight : AppColors.successLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.standard),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.type.localized(isSwahili),
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 1),
                Text(
                  [
                    if (movement.reason.trim().isNotEmpty) movement.reason.trim(),
                    if (movement.recordedBy.trim().isNotEmpty)
                      movement.recordedBy.trim(),
                    time,
                  ].join(' • '),
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${outflow ? '-' : '+'}${_CashRegisterPageState._money(movement.amount)}',
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    isSwahili ? 'Ondoa' : 'Remove',
                    style: AppTypography.helperText
                        .copyWith(color: AppColors.textLight),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShiftTile extends StatelessWidget {
  const _ShiftTile({
    required this.shift,
    required this.summary,
    required this.isSwahili,
    required this.onTap,
  });

  final RegisterShift shift;
  final CashUpSummary summary;
  final bool isSwahili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = shift.isOpen;
    final balanced = summary.variance.abs() < 0.5;
    final opened = shift.openedAt.toLocal();
    final stamp =
        '${opened.year}-${opened.month.toString().padLeft(2, '0')}-${opened.day.toString().padLeft(2, '0')} ${opened.hour.toString().padLeft(2, '0')}:${opened.minute.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: open ? AppColors.primaryLight : AppColors.surfaceHover,
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Icon(
          open ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
          color: open ? AppColors.primaryDeep : AppColors.ink,
          size: 18,
        ),
      ),
      title: Text(
        shift.register,
        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '$stamp • ${shift.openedBy.isEmpty ? '—' : shift.openedBy}',
        style: AppTypography.helperText.copyWith(color: AppColors.textMuted),
      ),
      trailing: open
          ? Text(
              isSwahili ? 'Wazi' : 'Open',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _CashRegisterPageState._money(summary.counted),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  balanced
                      ? (isSwahili ? 'Sawa' : 'Balanced')
                      : '${isSwahili ? 'Tofauti' : 'Var'} ${_CashRegisterPageState._money(summary.variance)}',
                  style: AppTypography.helperText.copyWith(
                    color: balanced ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class _CloseRegisterSheet extends StatefulWidget {
  const _CloseRegisterSheet({
    required this.summary,
    required this.countedController,
    required this.notesController,
    required this.isSwahili,
  });

  final CashUpSummary summary;
  final TextEditingController countedController;
  final TextEditingController notesController;
  final bool isSwahili;

  @override
  State<_CloseRegisterSheet> createState() => _CloseRegisterSheetState();
}

class _CloseRegisterSheetState extends State<_CloseRegisterSheet> {
  static const _denoms = <int>[
    10000,
    5000,
    2000,
    1000,
    500,
    200,
    100,
    50,
  ];
  late final Map<int, TextEditingController> _counts;

  String _t(String en, String sw) => widget.isSwahili ? sw : en;

  @override
  void initState() {
    super.initState();
    _counts = {for (final d in _denoms) d: TextEditingController(text: '0')};
  }

  @override
  void dispose() {
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
    final total = _denomTotal;
    widget.countedController.text = total.toStringAsFixed(0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entered =
        double.tryParse(widget.countedController.text.trim()) ?? 0;
    final variance = entered - widget.summary.expected;
    final balanced = variance.abs() < 0.5;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(_t('Close register & cash up', 'Funga kasha na hesabu'),
                style: AppTypography.h3.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              _t('Count the drawer and confirm the closing amount.',
                  'Hesabu pesa kazini na thibitisha kiasi cha kufunga.'),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            _reconSummary(balanced, variance),
            const SizedBox(height: AppSpacing.lg),
            Text(_t('Denomination count (optional)', 'Hesabu ya noti/sarafu (hiari)'),
                style: AppTypography.label),
            const SizedBox(height: 8),
            _denomGrid(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _applyDenoms,
                icon: const Icon(Icons.calculate_outlined, size: 16),
                label: Text(_t('Use denomination total', 'Tumia jumla ya hesabu')),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            MarketFormField(
              label: _t('Counted cash (TSh)', 'Pesa iliyohesabiwa (TSh)'),
              hintText: widget.summary.expected.toStringAsFixed(0),
              controller: widget.countedController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            MarketFormField(
              label: _t('Closing notes', 'Maelezo ya kufunga'),
              hintText: _t('Variance reason, handover notes...', 'Sababu ya tofauti, maelezo ya kukabidhi...'),
              controller: widget.notesController,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: MarketButton(
                    label: _t('Cancel', 'Ghairi'),
                    isPrimary: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MarketButton(
                    label: _t('Close shift', 'Funga zamu'),
                    icon: Icons.lock_outline_rounded,
                    color: balanced ? AppColors.ink : AppColors.primaryDeep,
                    onTap: () => Navigator.of(context).pop(
                      _CloseInput(
                        entered,
                        widget.notesController.text.trim(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reconSummary(bool balanced, double variance) {
    final s = widget.summary;
    Color vColor;
    String vText;
    if (balanced) {
      vColor = AppColors.success;
      vText = _t('Balanced', 'Sawa');
    } else if (variance > 0) {
      vColor = AppColors.primaryDeep;
      vText = _t('Over by ${_CashRegisterPageState._money(variance)}',
          'Ziada ${_CashRegisterPageState._money(variance)}');
    } else {
      vColor = AppColors.danger;
      vText = _t('Short by ${_CashRegisterPageState._money(variance.abs())}',
          'Upungufu ${_CashRegisterPageState._money(variance.abs())}');
    }
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.surfaceSecondary,
      showShadow: false,
      child: Column(
        children: [
          _line(_t('Opening float', 'Pesa ya kuanzia'), s.openingFloat),
          _line(_t('Cash sales', 'Mauzo ya taslimu'), s.cashSales),
          _line(_t('Cash in', 'Pesa kuingia'), s.cashIn),
          _line(_t('Payouts & drops', 'Malipo na amana'), -s.cashOut),
          const Divider(height: 14),
          _line(_t('Expected in drawer', 'Inayotarajiwa'), s.expected,
              strong: true),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: balanced ? AppColors.successLight : AppColors.dangerLight,
              borderRadius: BorderRadius.circular(AppRadius.standard),
            ),
            child: Text(
              vText,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: vColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, double value, {bool strong = false}) {
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
            _CashRegisterPageState._money(value),
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
      spacing: 8,
      runSpacing: 8,
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                    ),
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
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        hintText: '0',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.standard),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.standard),
                          borderSide:
                              const BorderSide(color: AppColors.border),
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

class _ShiftDetailSheet extends StatelessWidget {
  const _ShiftDetailSheet({
    required this.shift,
    required this.summary,
    required this.isSwahili,
  });

  final RegisterShift shift;
  final CashUpSummary summary;
  final bool isSwahili;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    final balanced = summary.variance.abs() < 0.5;
    final opened = shift.openedAt.toLocal();
    final closed = shift.closedAt?.toLocal();
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${shift.register} • ${shift.status.localized(isSwahili)}',
                    style: AppTypography.h3.copyWith(fontSize: 18),
                  ),
                ),
                if (!shift.isOpen)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: balanced
                          ? AppColors.successLight
                          : AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      balanced
                          ? _t('Balanced', 'Sawa')
                          : _t('Variance', 'Tofauti'),
                      style: AppTypography.helperText.copyWith(
                        color: balanced ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${_t('Opened', 'Ilifunguliwa')}: ${fmt(opened)} • ${shift.openedBy}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted)),
            if (closed != null)
              Text('${_t('Closed', 'Ilifungwa')}: ${fmt(closed)} • ${shift.closedBy}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.lg),
            MarketSurfaceCard(
              padding: const EdgeInsets.all(14),
              backgroundColor: AppColors.surfaceSecondary,
              showShadow: false,
              child: Column(
                children: [
                  _row(_t('Opening float', 'Pesa ya kuanzia'),
                      summary.openingFloat),
                  _row(_t('Cash sales', 'Mauzo ya taslimu'),
                      summary.cashSales),
                  _row(_t('Cash in', 'Pesa kuingia'), summary.cashIn),
                  _row(_t('Payouts & drops', 'Malipo na amana'),
                      -summary.cashOut),
                  const Divider(height: 14),
                  _row(_t('Expected in drawer', 'Inayotarajiwa'),
                      summary.expected,
                      strong: true),
                  if (!shift.isOpen) ...[
                    _row(_t('Counted cash', 'Iliyohesabiwa'),
                        summary.counted),
                    _row(_t('Variance', 'Tofauti'), summary.variance,
                        strong: true,
                        color: balanced ? AppColors.success : AppColors.danger),
                  ],
                ],
              ),
            ),
            if (shift.notes.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_t('Closing notes', 'Maelezo ya kufunga'),
                  style: AppTypography.label),
              const SizedBox(height: 4),
              Text(shift.notes.trim(),
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textBody, height: 1.4)),
            ],
            if (shift.movements.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(_t('Movements', 'Mienendo'), style: AppTypography.label),
              const SizedBox(height: 6),
              for (final m in shift.movements)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            m.type.localized(isSwahili),
                            if (m.reason.trim().isNotEmpty) m.reason.trim(),
                          ].join(' • '),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textBody),
                        ),
                      ),
                      Text(
                        '${m.type.isOutflow ? '-' : '+'}${_CashRegisterPageState._money(m.amount)}',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: m.type.isOutflow
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            MarketButton(
              label: _t('Done', 'Imekamilika'),
              isPrimary: false,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool strong = false, Color? color}) {
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
            _CashRegisterPageState._money(value),
            style: AppTypography.bodySmall.copyWith(
              color: color ?? (value < 0 ? AppColors.danger : AppColors.ink),
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
