import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../models/customer_data.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'customer_detail_models.dart';

class CustomerHeroCard extends StatelessWidget {
  const CustomerHeroCard({
    super.key,
    required this.customer,
    required this.tier,
    required this.points,
    required this.strings,
  });

  final CustomerData customer;
  final CustomerTier tier;
  final int points;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.kpiSkyBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  customer.initials,
                  style: AppTypography.cardHeader.copyWith(
                    color: AppColors.kpiSky,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h2.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        CustomerPill(
                          label: tier.label(strings),
                          color: tier.color,
                          background: tier.background,
                        ),
                        if (customer.tags.isEmpty)
                          CustomerPill(
                            label:
                                customerDual(strings, 'No tags', 'Hakuna lebo'),
                            color: AppColors.textMuted,
                            background: AppColors.surfaceSecondary,
                          )
                        else
                          for (final tag in customer.tags)
                            CustomerPill(
                              label: tag,
                              color: AppColors.primaryDeep,
                              background: AppColors.surfaceSecondary,
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          CustomerDetailRow(
            icon: Icons.call_outlined,
            label: customerDual(strings, 'Phone', 'Simu'),
            value: customer.phone.trim().isEmpty
                ? customerDual(strings, 'Not provided', 'Haijawekwa')
                : customer.phone,
          ),
          CustomerDetailRow(
            icon: Icons.alternate_email_rounded,
            label: customerDual(strings, 'Email', 'Barua pepe'),
            value: customer.email.trim().isEmpty
                ? customerDual(strings, 'Not provided', 'Haijawekwa')
                : customer.email.trim(),
          ),
          CustomerDetailRow(
            icon: Icons.event_outlined,
            label: customerDual(strings, 'Customer since', 'Mteja tangu'),
            value: DateFormat('MMM d, yyyy').format(customer.createdAt),
          ),
          CustomerDetailRow(
            icon: Icons.star_outline_rounded,
            label: customerDual(strings, 'Loyalty points', 'Alama za uaminifu'),
            value: '$points',
          ),
        ],
      ),
    );
  }
}

class CustomerPill extends StatelessWidget {
  const CustomerPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppCorners.control,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CustomerDetailRow extends StatelessWidget {
  const CustomerDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textLight),
          const SizedBox(width: 8),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
