import 'package:flutter/material.dart';
import '../../../service/register_shift_model.dart';
import '../../../service/pos_order_models.dart';
import '../../../service/pos_local_store.dart';
import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'register_kpi_metrics.dart';
import 'register_row_tiles.dart';

class CashRegisterOpenView extends StatelessWidget {
  const CashRegisterOpenView({
    super.key,
    required this.store,
    required this.shift,
    required this.isSwahili,
    required this.onOpenMovementPage,
    required this.onOpenClosePage,
    required this.onDeleteMovement,
  });

  final PosLocalStore store;
  final RegisterShift shift;
  final bool isSwahili;
  final void Function(PosLocalStore store, CashMovementType type) onOpenMovementPage;
  final void Function(PosLocalStore store, RegisterShift shift) onOpenClosePage;
  final void Function(PosLocalStore store, CashMovement movement) onDeleteMovement;

  String _t(String en, String sw) => isSwahili ? sw : en;
  String _money(double value) => 'TSh ${formatCurrency(value)}';

  String _fmtDateTime(DateTime dt) {
    final d = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}';
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
    final map = <String, double>{};
    for (final s in sales) {
      final method = s.paymentMethod.isEmpty ? 'Cash' : s.paymentMethod;
      map[method] = (map[method] ?? 0) + s.total;
    }
    return map;
  }

  Widget _flatCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return MarketSurfaceCard(
      padding: padding,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: child,
    );
  }

  Widget _line(String label, double value, {bool strong = false, bool money = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: strong ? AppColors.ink : AppColors.textBody,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            money ? _money(value) : value.toInt().toString(),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: strong ? AppColors.ink : AppColors.textBody,
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(icon, size: 20, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = store.cashUpFor(shift);
    final sales = _shiftSales(store, shift);
    final breakdown = _paymentBreakdown(sales);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        RegisterKpiMetrics(
          summary: summary,
          salesCount: sales.length,
          isSwahili: isSwahili,
        ),
        const SizedBox(height: 16),
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
                        Text(shift.register, style: AppTypography.h3.copyWith(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(
                          '${_t('Opened', 'Ilifunguliwa')} ${_fmtDateTime(shift.openedAt)} • ${shift.openedBy.isEmpty ? _t('Cashier', 'Mhudumu') : shift.openedBy}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      _t('Open', 'Wazi'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
              _line(_t('Expected in drawer', 'Inayotarajiwa'), summary.expected, strong: true),
              _line(_t('Transactions (shift)', 'Miamala (zamu)'), sales.length.toDouble(), money: false),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _flatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t('Sales by payment method', 'Mauzo kwa njia ya malipo'), style: AppTypography.h3.copyWith(fontSize: 15)),
              const SizedBox(height: 10),
              if (breakdown.isEmpty)
                Text(
                  _t('No completed sales in this shift yet.', 'Hakuna mauzo yaliyokamilika bado.'),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                )
              else
                for (final e in breakdown.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key, style: AppTypography.bodySmall.copyWith(color: AppColors.textBody))),
                        Text(_money(e.value), style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(_t('Drawer actions', 'Vitendo vya kasha'), style: AppTypography.h3.copyWith(fontSize: 16)),
        ),
        const SizedBox(height: 8),
        _flatCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _actionTile(
                icon: Icons.add_circle_outline_rounded,
                title: _t('Cash in', 'Pesa kuingia'),
                subtitle: _t('Add cash to the drawer', 'Ongeza pesa kazini'),
                onTap: () => onOpenMovementPage(store, CashMovementType.cashIn),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _actionTile(
                icon: Icons.remove_circle_outline_rounded,
                title: _t('Payout', 'Malipo'),
                subtitle: _t('Cash paid out from drawer', 'Pesa iliyotolewa kazini'),
                onTap: () => onOpenMovementPage(store, CashMovementType.payout),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _actionTile(
                icon: Icons.savings_outlined,
                title: _t('Safe drop / bank deposit', 'Amana salama / benki'),
                subtitle: _t('Move cash to safe or bank', 'Hamisha pesa salama au benki'),
                onTap: () => onOpenMovementPage(store, CashMovementType.drop),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MarketButton(
          label: _t('Close register & cash up', 'Funga kasha na hesabu'),
          icon: Icons.lock_outline_rounded,
          color: AppColors.primary,
          radius: 0,
          onTap: () => onOpenClosePage(store, shift),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(_t('Drawer movements', 'Mienendo ya kasha'), style: AppTypography.h3.copyWith(fontSize: 16)),
        ),
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
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, height: 1.45),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < shift.movements.reversed.length; i++) ...[
                      MovementRowTile(
                        movement: shift.movements.reversed.toList()[i],
                        isSwahili: isSwahili,
                        onDelete: () => onDeleteMovement(store, shift.movements.reversed.toList()[i]),
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
}
