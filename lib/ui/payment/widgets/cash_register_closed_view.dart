import 'package:flutter/material.dart';
import '../../../service/register_shift_model.dart';
import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'register_kpi_metrics.dart';
import 'register_row_tiles.dart';

class CashRegisterClosedView extends StatelessWidget {
  const CashRegisterClosedView({
    super.key,
    required this.store,
    required this.registerController,
    required this.floatController,
    required this.isSwahili,
    required this.onOpenShift,
    required this.onOpenShiftDetail,
  });

  final PosLocalStore store;
  final TextEditingController registerController;
  final TextEditingController floatController;
  final bool isSwahili;
  final void Function(PosLocalStore store) onOpenShift;
  final void Function(PosLocalStore store, RegisterShift shift) onOpenShiftDetail;

  String _t(String en, String sw) => isSwahili ? sw : en;

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

  @override
  Widget build(BuildContext context) {
    final history = store.registerShifts;
    final totalVariance = history
        .where((s) => s.closedAt != null)
        .fold<double>(0, (sum, s) => sum + store.cashUpFor(s).variance);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        RegisterClosedKpiMetrics(
          shifts: history,
          totalVariance: totalVariance,
          isSwahili: isSwahili,
        ),
        const SizedBox(height: 16),
        _flatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.point_of_sale_outlined, color: AppColors.ink, size: 22),
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
                hintText: _t('e.g. Front Counter, Register 1', 'mf. Kaunta, Kasha 1'),
                controller: registerController,
                fillColor: AppColors.pageBackground,
              ),
              const SizedBox(height: 14),
              MarketFormField(
                label: _t('Opening float (TSh)', 'Pesa ya kuanzia (TSh)'),
                hintText: '0',
                controller: floatController,
                fillColor: AppColors.pageBackground,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.payments_outlined, size: 18),
              ),
              const SizedBox(height: 20),
              MarketButton(
                label: _t('Open Register', 'Fungua Kasha'),
                icon: Icons.lock_open_rounded,
                onTap: () => onOpenShift(store),
              ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              _t('Shift history', 'Historia ya zamu'),
              style: AppTypography.h3.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          _flatCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              children: [
                for (var i = 0; i < history.length && i < 20; i++) ...[
                  ShiftRowTile(
                    shift: history[i],
                    summary: store.cashUpFor(history[i]),
                    isSwahili: isSwahili,
                    onTap: () => onOpenShiftDetail(store, history[i]),
                  ),
                  if (i != history.length - 1 && i != 19)
                    Divider(height: 1, color: AppColors.divider),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
