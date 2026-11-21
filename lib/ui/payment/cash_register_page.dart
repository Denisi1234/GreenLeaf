import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/register_shift_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'cash_movement_page.dart';
import 'close_shift_page.dart';
import 'shift_detail_page.dart';
import 'widgets/cash_register_closed_view.dart';
import 'widgets/cash_register_open_view.dart';

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
    return CashRegisterClosedView(
      store: store,
      registerController: _registerController,
      floatController: _floatController,
      isSwahili: _isSwahili,
      onOpenShift: _openShift,
      onOpenShiftDetail: _openShiftDetail,
    );
  }

  Widget _buildOpenState(PosLocalStore store, RegisterShift shift) {
    return CashRegisterOpenView(
      store: store,
      shift: shift,
      isSwahili: _isSwahili,
      onOpenMovementPage: _openMovementPage,
      onOpenClosePage: _openClosePage,
      onDeleteMovement: _deleteMovement,
    );
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
    final confirmed = await showMarketConfirmDialog(
      context,
      title: _t('Remove movement?', 'Ondoa mienendo?'),
      message: _t(
        'Remove this recorded cash movement from the open shift.',
        'Ondoa rekodi hii ya pesa kwenye zamu iliyo wazi.',
      ),
      confirmLabel: _t('Remove', 'Ondoa'),
      cancelLabel: _t('Cancel', 'Ghairi'),
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    await store.deleteCashMovement(movement.id!);
    if (!mounted) return;
    _notify(_t('Cash movement removed', 'Mienendo ya pesa imeondolewa'));
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




