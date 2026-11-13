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

  bool get _isSwahili =>
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String sw) => _isSwahili ? sw : en;

  @override
  void dispose() {
    _floatController.dispose();
    _registerController.dispose();
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _flatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.point_of_sale_outlined,
                      color: AppColors.ink, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Open register shift', 'Fungua zamu ya kasha'),
                          style: AppTypography.h3.copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t(
                            'Count opening cash, record drawer movements during the day, and close with a full cash-up reconciliation.',
                            'Hesabu pesa ya kuanzia, rekodi mienendo ya kasha, na funga kwa uhesabuji kamili.',
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MarketFormField(
                label: _t('Register name', 'Jina la kasha'),
                hintText:
                    _t('e.g. Front Counter, Register 1', 'mf. Kaunta, Kasha 1'),
                controller: _registerController,
              ),
              const SizedBox(height: 14),
              MarketFormField(
                label: _t('Opening float (TSh)', 'Pesa ya kuanzia (TSh)'),
                hintText: '0',
                controller: _floatController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.payments_outlined, size: 18),
              ),
              const SizedBox(height: 20),
              MarketButton(
                label: _t('Open Register', 'Fungua Kasha'),
                icon: Icons.lock_open_rounded,
                onTap: () => _openShift(store),
              ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle(_t('Shift history', 'Historia ya zamu')),
          const SizedBox(height: 8),
          _flatCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              children: [
                for (var i = 0; i < history.length && i < 20; i++) ...[
                  _ShiftRow(
                    shift: history[i],
                    summary: store.cashUpFor(history[i]),
                    isSwahili: _isSwahili,
                    onTap: () => _openShiftDetail(store, history[i]),
                  ),
                  if (i != history.length - 1 && i != 19)
                    const Divider(height: 1, color: AppColors.divider),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOpenState(PosLocalStore store, RegisterShift shift) {
    final summary = store.cashUpFor(shift);
    final sales = _shiftSales(store, shift);
    final breakdown = _paymentBreakdown(sales);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _flatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.register,
                          style: AppTypography.h3.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_t('Opened', 'Ilifunguliwa')} ${_fmtDateTime(shift.openedAt)} • ${shift.openedBy.isEmpty ? _t('Cashier', 'Mhudumu') : shift.openedBy}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _t('Open', 'Wazi'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _t('Expected in drawer', 'Inayotarajiwa kazini'),
                style: AppTypography.label,
              ),
              const SizedBox(height: 4),
              Text(
                _money(summary.expected),
                style: AppTypography.h1.copyWith(
                  fontSize: 30,
                  color: summary.expected >= 0
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _t('Opening float + cash sales + cash in − payouts/drops',
                    'Pesa ya kuanzia + mauzo ya taslimu + iliyoingia − iliyotoka'),
                style:
                    AppTypography.helperText.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _flatCard(
          child: Column(
            children: [
              _line(_t('Opening float', 'Pesa ya kuanzia'), summary.openingFloat),
              _line(_t('Cash sales', 'Mauzo ya taslimu'), summary.cashSales),
              _line(_t('Cash in', 'Pesa kuingia'), summary.cashIn),
              _line(_t('Payouts & drops', 'Malipo na amana'), -summary.cashOut),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              _line(_t('Expected in drawer', 'Inayotarajiwa'), summary.expected,
                  strong: true),
              _line(_t('Transactions (shift)', 'Miamala (zamu)'),
                  sales.length.toDouble(),
                  money: false),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _flatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                  _t('Sales by payment method', 'Mauzo kwa njia ya malipo'),
                  inCard: true),
              const SizedBox(height: 10),
              if (breakdown.isEmpty)
                Text(
                  _t('No completed sales in this shift yet.',
                      'Hakuna mauzo yaliyokamilika bado.'),
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                )
              else
                for (final e in breakdown.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(e.key,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textBody)),
                        ),
                        Text(_money(e.value),
                            style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle(_t('Drawer actions', 'Vitendo vya kasha')),
        const SizedBox(height: 8),
        _flatCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _actionTile(
                icon: Icons.add_circle_outline_rounded,
                title: _t('Cash in', 'Pesa kuingia'),
                subtitle: _t('Add cash to the drawer', 'Ongeza pesa kazini'),
                onTap: () => _openMovementPage(store, CashMovementType.cashIn),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _actionTile(
                icon: Icons.remove_circle_outline_rounded,
                title: _t('Payout', 'Malipo'),
                subtitle: _t('Cash paid out from drawer', 'Pesa iliyotolewa kazini'),
                onTap: () => _openMovementPage(store, CashMovementType.payout),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _actionTile(
                icon: Icons.savings_outlined,
                title: _t('Safe drop / bank deposit', 'Amana salama / benki'),
                subtitle: _t('Move cash to safe or bank', 'Hamisha pesa salama au benki'),
                onTap: () => _openMovementPage(store, CashMovementType.drop),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MarketButton(
          label: _t('Close register & cash up', 'Funga kasha na hesabu'),
          icon: Icons.lock_outline_rounded,
          color: AppColors.ink,
          onTap: () => _openClosePage(store, shift),
        ),
        const SizedBox(height: 20),
        _sectionTitle(_t('Drawer movements', 'Mienendo ya kasha')),
        const SizedBox(height: 8),
        _flatCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: shift.movements.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _t(
                      'No manual movements recorded. Cash sales are tracked automatically.',
                      'Hakuna mienendo ya mkono. Mauzo ya taslimu yanafuatiliwa kiotomatiki.',
                    ),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted, height: 1.45),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < shift.movements.reversed.length; i++) ...[
                      _MovementRow(
                        movement: shift.movements.reversed.toList()[i],
                        isSwahili: _isSwahili,
                        onDelete: () => _deleteMovement(
                            store, shift.movements.reversed.toList()[i]),
                      ),
                      if (i != shift.movements.length - 1)
                        const Divider(height: 1, color: AppColors.divider),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _flatCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return MarketSurfaceCard(
      padding: padding,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: child,
    );
  }

  Widget _sectionTitle(String text, {bool inCard = false}) {
    return Text(
      text,
      style: (inCard ? AppTypography.label : AppTypography.sectionHeader)
          .copyWith(color: AppColors.ink),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.standard),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ink, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.bodyMain
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, double value,
      {bool strong = false, bool money = true}) {
    final isNeg = value < 0;
    final display =
        money ? _money(value) : value.abs().toStringAsFixed(0);
    Color valueColor;
    if (!money) {
      valueColor = strong ? AppColors.ink : AppColors.textBody;
    } else if (isNeg) {
      valueColor = AppColors.danger;
    } else if (value > 0) {
      valueColor = strong ? AppColors.ink : AppColors.success;
    } else {
      valueColor = AppColors.textMuted;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            display,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
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
    final entries = out.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(entries);
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
      _notify(_t('Opening float cannot be negative', 'Pesa ya kuanzia haiwezi kuwa hasi'),
          error: true);
      return;
    }
    final shift = await store.startShift(
      register: _registerController.text.trim().isEmpty
          ? 'Register 1'
          : _registerController.text.trim(),
      openedBy:
          store.profile.ownerName.isEmpty ? 'Cashier' : store.profile.ownerName,
      openingFloat: float,
    );
    if (!mounted) return;
    if (shift == null) {
      _notify(_t('A register is already open', 'Kasha tayari liko wazi'),
          error: true);
      return;
    }
    _floatController.clear();
    _notify(_t('Register opened', 'Kasha limefunguliwa'));
  }

  Future<void> _openMovementPage(
      PosLocalStore store, CashMovementType type) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _CashMovementPage(
          type: type,
          isSwahili: _isSwahili,
          onSave: (amount, reason) => store.addCashMovement(
            type: type,
            amount: amount,
            reason: reason,
            recordedBy: store.profile.ownerName.isEmpty
                ? 'Cashier'
                : store.profile.ownerName,
          ),
        ),
      ),
    );
    if (saved == true && mounted) {
      _notify(_t('${type.localized(_isSwahili)} recorded',
          '${type.localized(_isSwahili)} imerekodiwa'));
    }
  }

  Future<void> _openClosePage(PosLocalStore store, RegisterShift shift) async {
    final closed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _CloseShiftPage(
          shift: shift,
          summary: store.cashUpFor(shift),
          isSwahili: _isSwahili,
          onClose: (counted, notes) => store.closeShift(
            shift.id!,
            countedCash: counted,
            closedBy: store.profile.ownerName.isEmpty
                ? 'Cashier'
                : store.profile.ownerName,
            notes: notes,
          ),
        ),
      ),
    );
    if (closed == true && mounted) {
      _notify(_t('Shift closed', 'Zamu imefungwa'));
    }
  }

  Future<void> _openShiftDetail(PosLocalStore store, RegisterShift shift) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ShiftDetailPage(
          shift: shift,
          summary: store.cashUpFor(shift),
          isSwahili: _isSwahili,
        ),
      ),
    );
  }

  Future<void> _deleteMovement(
      PosLocalStore store, CashMovement movement) async {
    if (movement.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_t('Remove movement?', 'Ondoa mienendo?')),
        content: Text(
          _t('Remove this recorded cash movement from the open shift.',
              'Ondoa rekodi hii ya pesa kwenye zamu iliyo wazi.'),
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

  static String _fmtDateTime(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }
}

class _ShiftRow extends StatelessWidget {
  const _ShiftRow({
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
    final opened = shift.openedAt.toLocal();
    final stamp = _CashRegisterPageState._fmtDateTime(opened);
    final balanced = summary.variance.abs() < 0.5;
    final status = shift.isOpen
        ? (isSwahili ? 'Wazi' : 'Open')
        : (balanced
            ? (isSwahili ? 'Sawa' : 'Balanced')
            : '${isSwahili ? 'Tofauti' : 'Variance'} ${_CashRegisterPageState._money(summary.variance)}');
    final statusColor = shift.isOpen
        ? AppColors.success
        : (balanced ? AppColors.textMuted : AppColors.danger);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.register,
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$stamp • ${shift.openedBy.isEmpty ? '—' : shift.openedBy}',
                    style: AppTypography.helperText
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!shift.isOpen)
                  Text(
                    _CashRegisterPageState._money(summary.counted),
                    style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                Text(
                  status,
                  style: AppTypography.helperText.copyWith(
                      color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
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
    final color = outflow ? AppColors.danger : AppColors.success;
    final at = movement.at.toLocal();
    final time =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final subtitle = [
      if (movement.reason.trim().isNotEmpty) movement.reason.trim(),
      if (movement.recordedBy.trim().isNotEmpty) movement.recordedBy.trim(),
      time,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.type.localized(isSwahili),
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
                    color: color, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onDelete,
                child: Text(
                  isSwahili ? 'Ondoa' : 'Remove',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-page form for recording a cash in / payout / safe drop movement.
class _CashMovementPage extends StatefulWidget {
  const _CashMovementPage({
    required this.type,
    required this.isSwahili,
    required this.onSave,
  });

  final CashMovementType type;
  final bool isSwahili;
  final Future<void> Function(double amount, String reason) onSave;

  @override
  State<_CashMovementPage> createState() => _CashMovementPageState();
}

class _CashMovementPageState extends State<_CashMovementPage> {
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
        return _t('Float top-up, change fund...', 'Kuongeza float, fedha ya chenji...');
      case CashMovementType.payout:
        return _t('Supplier, transport, petty expense...', 'Msambazaji, usafiri, matumizi madogo...');
      case CashMovementType.drop:
        return _t('Safe drop, bank deposit reference...', 'Amana salama, rejea ya benki...');
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
      body: SafeArea(
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
                          label: _t('Reason / reference', 'Sababu / kumbukumbu'),
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
    );
  }
}

/// Full-page cash-up and shift close flow.
class _CloseShiftPage extends StatefulWidget {
  const _CloseShiftPage({
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
  State<_CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<_CloseShiftPage> {
  late final TextEditingController _countedController;
  final TextEditingController _notesController = TextEditingController();
  static const _denoms = <int>[10000, 5000, 2000, 1000, 500, 200, 100, 50];
  late final Map<int, TextEditingController> _counts;
  bool _saving = false;

  String _t(String en, String sw) => widget.isSwahili ? sw : en;

  @override
  void initState() {
    super.initState();
    _countedController = TextEditingController(
        text: widget.summary.expected.toStringAsFixed(0));
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
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: _t('Close register & cash up', 'Funga kasha na hesabu'),
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
                        _row(_t('Cash sales', 'Mauzo ya taslimu'), s.cashSales),
                        _row(_t('Cash in', 'Pesa kuingia'), s.cashIn),
                        _row(_t('Payouts & drops', 'Malipo na amana'),
                            -s.cashOut),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: AppColors.divider),
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
                      style:
                          AppTypography.sectionHeader.copyWith(color: AppColors.ink)),
                  const SizedBox(height: 8),
                  _card(child: _denomGrid()),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _applyDenoms,
                      icon: const Icon(Icons.calculate_outlined, size: 16),
                      label: Text(_t(
                          'Use denomination total', 'Tumia jumla ya hesabu')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarketFormField(
                          label: _t('Counted cash (TSh)', 'Pesa iliyohesabiwa (TSh)'),
                          hintText: s.expected.toStringAsFixed(0),
                          controller: _countedController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
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
                        : _t('Confirm close shift', 'Thibitisha kufunga zamu'),
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
    );
  }

  Widget _card({required Widget child}) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      showShadow: false,
      borderColor: AppColors.border,
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
      text = _t('Over by ${_CashRegisterPageState._money(variance)}',
          'Ziada ${_CashRegisterPageState._money(variance)}');
    } else {
      color = AppColors.danger;
      text = _t('Short by ${_CashRegisterPageState._money(variance.abs())}',
          'Upungufu ${_CashRegisterPageState._money(variance.abs())}');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.standard),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.textBody),
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

/// Full-page shift detail / history view.
class _ShiftDetailPage extends StatelessWidget {
  const _ShiftDetailPage({
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
    final status = shift.isOpen
        ? _t('Open', 'Wazi')
        : (balanced ? _t('Balanced', 'Sawa') : _t('Variance', 'Tofauti'));

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: shift.register,
              subtitle:
                  '$status • ${_t('Opened', 'Ilifunguliwa')} ${_CashRegisterPageState._fmtDateTime(shift.openedAt)}',
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _info(_t('Opened by', 'Ilifunguliwa na'),
                            shift.openedBy.isEmpty ? '—' : shift.openedBy),
                        _info(_t('Opened at', 'Muda wa kufungua'),
                            _CashRegisterPageState._fmtDateTime(shift.openedAt)),
                        if (shift.closedAt != null)
                          _info(_t('Closed at', 'Muda wa kufunga'),
                              _CashRegisterPageState._fmtDateTime(shift.closedAt!)),
                        if (shift.closedBy.trim().isNotEmpty)
                          _info(_t('Closed by', 'Ilifungwa na'),
                              shift.closedBy.trim()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      children: [
                        _moneyRow(_t('Opening float', 'Pesa ya kuanzia'),
                            summary.openingFloat),
                        _moneyRow(_t('Cash sales', 'Mauzo ya taslimu'),
                            summary.cashSales),
                        _moneyRow(
                            _t('Cash in', 'Pesa kuingia'), summary.cashIn),
                        _moneyRow(_t('Payouts & drops', 'Malipo na amana'),
                            -summary.cashOut),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: AppColors.divider),
                        ),
                        _moneyRow(_t('Expected in drawer', 'Inayotarajiwa'),
                            summary.expected,
                            strong: true),
                        if (!shift.isOpen) ...[
                          _moneyRow(_t('Counted cash', 'Iliyohesabiwa'),
                              summary.counted),
                          _moneyRow(_t('Variance', 'Tofauti'), summary.variance,
                              strong: true,
                              color: balanced
                                  ? AppColors.success
                                  : AppColors.danger),
                        ],
                      ],
                    ),
                  ),
                  if (shift.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('Closing notes', 'Maelezo ya kufunga'),
                              style: AppTypography.label),
                          const SizedBox(height: 6),
                          Text(
                            shift.notes.trim(),
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textBody, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (shift.movements.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_t('Movements', 'Mienendo'),
                        style: AppTypography.sectionHeader
                            .copyWith(color: AppColors.ink)),
                    const SizedBox(height: 8),
                    _card(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Column(
                        children: [
                          for (var i = 0; i < shift.movements.length; i++) ...[
                            _detailMovementRow(shift.movements[i]),
                            if (i != shift.movements.length - 1)
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
      ),
    );
  }

  Widget _card(
      {required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) {
    return MarketSurfaceCard(
      padding: padding,
      showShadow: false,
      borderColor: AppColors.border,
      child: child,
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double value,
      {bool strong = false, Color? color}) {
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

  Widget _detailMovementRow(CashMovement m) {
    final outflow = m.type.isOutflow;
    final color = outflow ? AppColors.danger : AppColors.success;
    final parts = <String>[
      m.type.localized(isSwahili),
      if (m.reason.trim().isNotEmpty) m.reason.trim(),
      if (m.recordedBy.trim().isNotEmpty) m.recordedBy.trim(),
      _CashRegisterPageState._fmtDateTime(m.at),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              parts.join(' • '),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textBody, height: 1.4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${outflow ? '-' : '+'}${_CashRegisterPageState._money(m.amount)}',
            style: AppTypography.bodySmall
                .copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
