import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/debit_statement_service.dart';
import '../../../service/pos_local_store.dart';
import '../../models/customer_data.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _money(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

class DebtorCard extends StatelessWidget {
  const DebtorCard({
    super.key,
    required this.customer,
    required this.store,
    required this.strings,
    required this.onTap,
    required this.onSettle,
    required this.onReminder,
  });

  final CustomerData customer;
  final PosLocalStore store;
  final AppStrings strings;
  final VoidCallback onTap;
  final VoidCallback onSettle;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final entries = store.debitEntriesFor(customer.id);
    final charges = entries
        .where((entry) => !entry.isPayment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final paid = entries
        .where((entry) => entry.isPayment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final last = entries.isEmpty ? null : entries.first;
    final agingDays = DebitStatementService.getAgingDays(customer, store);
    final agingCategory = DebitStatementService.getAgingCategory(customer, store);

    Color agingBadgeBg;
    Color agingBadgeText;
    String agingBadgeLabel;

    switch (agingCategory) {
      case DebtAgingCategory.critical:
        agingBadgeBg = AppColors.kpiDangerBg;
        agingBadgeText = AppColors.kpiDanger;
        agingBadgeLabel = _dual(strings, '$agingDays days (Critical)', 'Siku $agingDays (Hatari)');
        break;
      case DebtAgingCategory.overdue:
        agingBadgeBg = AppColors.kpiAmberBg;
        agingBadgeText = AppColors.kpiAmber;
        agingBadgeLabel = _dual(strings, '$agingDays days (Overdue)', 'Siku $agingDays (Imechelewa)');
        break;
      case DebtAgingCategory.attention:
        agingBadgeBg = AppColors.kpiSkyBg;
        agingBadgeText = AppColors.kpiSky;
        agingBadgeLabel = _dual(strings, '$agingDays days', 'Siku $agingDays');
        break;
      case DebtAgingCategory.current:
      case DebtAgingCategory.settled:
        agingBadgeBg = AppColors.kpiSuccessBg;
        agingBadgeText = AppColors.kpiSuccess;
        agingBadgeLabel = _dual(strings, 'Recent (<7 days)', 'Mpya (<7d)');
        break;
    }

    return MarketSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRadius.sharp)),
                    ),
                    child: Text(
                      customer.initials,
                      style: AppTypography.cardHeader.copyWith(
                        color: AppColors.ink,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMain.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.phone.trim().isEmpty
                              ? _dual(strings, 'No phone', 'Hakuna simu')
                              : customer.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.helperText.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _money(customer.debitBalance, compact: true),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        _dual(strings, 'OWED', 'DENI'),
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: agingBadgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: agingBadgeText),
                    const SizedBox(width: 4),
                    Text(
                      '${_dual(strings, 'Debt age', 'Umri wa deni')}: $agingBadgeLabel',
                      style: AppTypography.helperText.copyWith(
                        color: agingBadgeText,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LedgerMetric(
                      label: _dual(strings, 'Charged', 'Deni'),
                      value: _money(charges, compact: true),
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LedgerMetric(
                      label: _dual(strings, 'Paid', 'Malipo'),
                      value: _money(paid, compact: true),
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LedgerMetric(
                      label: _dual(strings, 'Entries', 'Rekodi'),
                      value: '${entries.length}',
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
              if (last != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      last.isPayment
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 12,
                      color: last.isPayment ? AppColors.success : AppColors.ink,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${last.type.localized(strings.isSwahili)} · ${DateFormat('MMM d').format(last.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.kpiSkyBg,
                      foregroundColor: AppColors.kpiSky,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppCorners.control,
                      ),
                    ),
                    onPressed: onReminder,
                    child: const Icon(Icons.send_rounded, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.kpiVioletBg,
                        foregroundColor: AppColors.kpiViolet,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppCorners.control,
                        ),
                      ),
                      onPressed: onTap,
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: Text(
                        _dual(strings, 'Statement', 'Taarifa'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        highlightColor: Colors.transparent,
                        onTap: onSettle,
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _dual(strings, 'Receive', 'Pokea'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LedgerMetric extends StatelessWidget {
  const LedgerMetric({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
