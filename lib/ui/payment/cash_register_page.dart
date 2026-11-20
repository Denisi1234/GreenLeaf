import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../../service/register_shift_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'cash_movement_page.dart';
import 'close_shift_page.dart';
import 'shift_detail_page.dart';
import 'widgets/register_models.dart';
import 'widgets/register_row_tiles.dart';

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
  late final TextEditingController _registerController;

  bool get _isSwahili =>
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String sw) => _isSwahili ? sw : en;

  @override
  void initState() {
    super.initState();
    final prefName = context.read<PosLocalStore>().storePreferences.defaultRegisterName;
    _registerController = TextEditingController(text: prefName.isNotEmpty ? prefName : 'Register 1');
  }

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
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
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
          )),
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
                  ShiftRowTile(
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
                style: AppTypography.helperText
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _flatCard(
          child: Column(
            children: [
              _line(
                  _t('Opening float', 'Pesa ya kuanzia'), summary.openingFloat),
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
                subtitle:
                    _t('Cash paid out from drawer', 'Pesa iliyotolewa kazini'),
                onTap: () => _openMovementPage(store, CashMovementType.payout),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _actionTile(
                icon: Icons.savings_outlined,
                title: _t('Safe drop / bank deposit', 'Amana salama / benki'),
                subtitle: _t('Move cash to safe or bank',
                    'Hamisha pesa salama au benki'),
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
                    for (var i = 0;
                        i < shift.movements.reversed.length;
                        i++) ...[
                      MovementRowTile(
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
      borderRadius: BorderRadius.zero,
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
    final display = money ? _money(value) : value.abs().toStringAsFixed(0);
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
      _notify(
          _t('Opening float cannot be negative',
              'Pesa ya kuanzia haiwezi kuwa hasi'),
          error: true);
      return;
    }
    final regName = _registerController.text.trim().isEmpty
        ? 'Register 1'
        : _registerController.text.trim();

    // Persist register name across sessions on this device (OSPOS named terminal pattern)
    if (store.storePreferences.defaultRegisterName != regName) {
      await store.setStorePreferences(
        store.storePreferences.copyWith(defaultRegisterName: regName),
      );
    }

    final shift = await store.startShift(
      register: regName,
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
        builder: (_) => CashMovementPage(
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
        builder: (_) => CloseShiftPage(
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

  Future<void> _openShiftDetail(
      PosLocalStore store, RegisterShift shift) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ShiftDetailPage(
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




