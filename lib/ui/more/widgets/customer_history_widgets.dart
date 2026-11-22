import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/pos_order_models.dart';
import '../../models/customer_data.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'customer_detail_models.dart';

class CustomerContactActions extends StatelessWidget {
  const CustomerContactActions({
    super.key,
    required this.customer,
    required this.strings,
  });

  final CustomerData customer;
  final AppStrings strings;

  Future<void> _open(
    BuildContext context,
    String scheme,
    String fallbackMsg,
  ) async {
    final uri = Uri.parse(scheme);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        showMarketNotice(
          context,
          title: customerDual(strings, 'Cannot open', 'Imeshindwa kufungua'),
          message: fallbackMsg,
          type: MarketNoticeType.warning,
        );
      }
    } catch (_) {
      if (context.mounted) {
        showMarketNotice(
          context,
          title: customerDual(strings, 'Cannot open', 'Imeshindwa kufungua'),
          message: fallbackMsg,
          type: MarketNoticeType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = customer.phone.replaceAll(RegExp(r'\s+'), '');
    final hasPhone = phone.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: CustomerActionTile(
            icon: Icons.call_rounded,
            label: customerDual(strings, 'Call', 'Piga'),
            enabled: hasPhone,
            onTap: hasPhone
                ? () => _open(
                    context,
                    'tel:$phone',
                    customerDual(strings, 'Phone dialer unavailable',
                        'Simu haipatikani'))
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomerActionTile(
            icon: Icons.message_rounded,
            label: customerDual(strings, 'SMS', 'Ujumbe'),
            enabled: hasPhone,
            onTap: hasPhone
                ? () => _open(context, 'sms:$phone',
                    customerDual(strings, 'SMS app unavailable', 'Ujumbe haupatikani'))
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomerActionTile(
            icon: Icons.chat_bubble_rounded,
            label: customerDual(strings, 'WhatsApp', 'WhatsApp'),
            enabled: hasPhone,
            onTap: hasPhone
                ? () {
                    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                    _open(
                        context,
                        'https://wa.me/$cleaned',
                        customerDual(strings, 'WhatsApp unavailable',
                            'WhatsApp haipatikani'));
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class CustomerActionTile extends StatelessWidget {
  const CustomerActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.kpiSky : AppColors.textLight;
    final bg = enabled ? AppColors.kpiSkyBg : AppColors.surface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.helperText.copyWith(
                  color: color,
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

class CustomerStatsGrid extends StatelessWidget {
  const CustomerStatsGrid({
    super.key,
    required this.totalSpent,
    required this.orderCount,
    required this.averageOrder,
    required this.lastOrder,
    required this.strings,
  });

  final double totalSpent;
  final int orderCount;
  final double averageOrder;
  final DateTime? lastOrder;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomerStatCard(
            label: customerDual(strings, 'Total spent', 'Jumla'),
            value: formatCustomerMoney(totalSpent, compact: true),
            icon: Icons.payments_outlined,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomerStatCard(
            label: customerDual(strings, 'Orders', 'Oda'),
            value: '$orderCount',
            icon: Icons.receipt_long_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomerStatCard(
            label: customerDual(strings, 'Avg order', 'Wastani'),
            value: formatCustomerMoney(averageOrder, compact: true),
            icon: Icons.trending_up_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomerStatCard(
            label: customerDual(strings, 'Last visit', 'Mara ya mwisho'),
            value: lastOrder == null
                ? '—'
                : DateFormat('MMM d').format(lastOrder!),
            icon: Icons.event_outlined,
            color: AppColors.toneTeal,
          ),
        ),
      ],
    );
  }
}

class CustomerStatCard extends StatelessWidget {
  const CustomerStatCard({
    super.key,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerInfoBlock extends StatelessWidget {
  const CustomerInfoBlock({
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
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

class CustomerOrdersSection extends StatelessWidget {
  const CustomerOrdersSection({
    super.key,
    required this.orders,
    required this.strings,
  });

  final List<CompletedOrder> orders;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final visible = orders.take(25).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarketSectionHeader(
          title: customerDual(strings, 'Order history', 'Historia ya oda'),
          trailing: Text(
            customerDual(
              strings,
              '${orders.length} order${orders.length == 1 ? '' : 's'}',
              '${orders.length} oda',
            ),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          MarketSurfaceCard(
            padding: const EdgeInsets.all(24),
            borderColor: AppColors.border,
            radius: AppRadius.standard,
            showShadow: true,
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: AppColors.textLight, size: 32),
                const SizedBox(height: 8),
                Text(
                  customerDual(strings, 'No orders yet', 'Hakuna oda bado'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customerDual(
                      strings,
                      'Completed sales linked to this customer appear here.',
                      'Mauzo yaliyokamilika ya mteja huyu yanaonekana hapa.'),
                  textAlign: TextAlign.center,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...visible.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CustomerOrderTile(order: order),
              )),
        if (orders.length > 25)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              customerDual(strings, '+ ${orders.length - 25} more orders',
                  '+ oda ${orders.length - 25} zaidi'),
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class CustomerOrderTile extends StatelessWidget {
  const CustomerOrderTile({super.key, required this.order});

  final CompletedOrder order;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.kpiSkyBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: AppColors.kpiSky, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.date} · ${order.time}',
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
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
                formatCustomerMoney(order.total, compact: true),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                order.paymentMethod,
                style: AppTypography.helperText.copyWith(
                  color: AppColors.textLight,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
