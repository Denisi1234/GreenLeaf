import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../models/customer_data.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'customer_models.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _formatMoney(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.stats,
    required this.strings,
    required this.onTap,
  });

  final CustomerData customer;
  final CustomerStats stats;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spent = stats.spent + customer.totalSpent;
    final orders = stats.orders + customer.totalOrders;
    final points = (spent / 1000).round();
    final tier = tierForSpend(spent);
    final hasDebt = customer.debitBalance > 0;

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
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRadius.sharp)),
                ),
                child: Text(
                  customer.initials,
                  style: AppTypography.cardHeader.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMain.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tier.background,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            tier.label(strings),
                            style: TextStyle(
                              color: tier.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MetricChip(
                          icon: Icons.receipt_long_rounded,
                          label: _dual(strings, 'orders', 'oda'),
                          value: '$orders',
                          color: AppColors.textBody,
                        ),
                        const SizedBox(width: 6),
                        _MetricChip(
                          icon: Icons.payments_outlined,
                          label: _dual(strings, 'spent', 'matumizi'),
                          value: _formatMoney(spent, compact: true),
                          color: AppColors.textBody,
                        ),
                        if (hasDebt) ...[
                          const SizedBox(width: 6),
                          _MetricChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: _dual(strings, 'due', 'deni'),
                            value: _formatMoney(customer.debitBalance,
                                compact: true),
                            color: AppColors.ink,
                          ),
                        ],
                      ],
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
                    '$points',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    _dual(strings, 'POINTS', 'ALAMA'),
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textLight, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: const BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '$value $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerEmptyState extends StatelessWidget {
  const CustomerEmptyState({
    super.key,
    required this.strings,
    required this.filtered,
    required this.onAdd,
    required this.onReset,
  });

  final AppStrings strings;
  final bool filtered;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return MarketEmptyState(
      icon: filtered ? Icons.search_off_rounded : Icons.people_outline_rounded,
      title: filtered
          ? _dual(strings, 'No matching customers', 'Hakuna wateja')
          : _dual(strings, 'No customers yet', 'Hakuna wateja bado'),
      message: filtered
          ? _dual(
              strings,
              'Try a different name, phone or filter to see customers.',
              'Jaribu jina, simu au kichujio kingine kuona wateja.',
            )
          : _dual(
              strings,
              'Add your first customer to start tracking sales and credit.',
              'Ongeza mteja wako wa kwanza kufuatilia mauzo na mkopo.',
            ),
      actionLabel: filtered
          ? _dual(strings, 'Clear filters', 'Ondoa vichujio')
          : _dual(strings, 'Add customer', 'Ongeza mteja'),
      actionIcon: filtered ? Icons.filter_alt_off_rounded : Icons.add_rounded,
      onAction: filtered ? onReset : onAdd,
    );
  }
}

class AddCustomerButton extends StatelessWidget {
  const AddCustomerButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        splashColor: AppColors.primaryDeep.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
