import 'package:flutter/material.dart';

import '../../service/pos_local_store.dart';
import '../../service/register_shift_model.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/register_models.dart';

class ShiftDetailPage extends StatelessWidget {
  const ShiftDetailPage({
    super.key,
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
      body: ManagementViewport(
        maxWidth: 1280,
        child: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: shift.register,
                subtitle:
                    '$status • ${_t('Opened', 'Ilifunguliwa')} ${formatRegisterDateTime(shift.openedAt)}',
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
                          _info(
                              _t('Opened at', 'Muda wa kufungua'),
                              formatRegisterDateTime(shift.openedAt)),
                          if (shift.closedAt != null)
                            _info(
                                _t('Closed at', 'Muda wa kufunga'),
                                formatRegisterDateTime(shift.closedAt!)),
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
                            child:
                                Divider(height: 1, color: AppColors.divider),
                          ),
                          _moneyRow(_t('Expected in drawer', 'Inayotarajiwa'),
                              summary.expected,
                              strong: true),
                          if (!shift.isOpen) ...[
                            _moneyRow(_t('Counted cash', 'Iliyohesabiwa'),
                                summary.counted),
                            _moneyRow(
                                _t('Variance', 'Tofauti'), summary.variance,
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
                            for (var i = 0;
                                i < shift.movements.length;
                                i++) ...[
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
      radius: 0,
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
            formatRegisterMoney(value),
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
      formatRegisterDateTime(m.at),
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
            '${outflow ? '-' : '+'}${formatRegisterMoney(m.amount)}',
            style: AppTypography.bodySmall
                .copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
