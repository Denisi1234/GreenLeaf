import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../../service/debit_entry_model.dart';
import 'create_customer_page.dart';
import 'record_payment_sheet.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _formatMoney(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

class CustomerDetailsPage extends StatelessWidget {
  const CustomerDetailsPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Selector<PosLocalStore, CustomerData?>(
      selector: (_, store) {
        for (final customer in store.customers) {
          if (customer.id == customerId) return customer;
        }
        return null;
      },
      builder: (context, customer, _) {
        final strings =
            AppStrings.of(context.watch<PosLocalStore>().languageCode);
        if (customer == null) {
          return Scaffold(
            backgroundColor: AppColors.pageBackground,
            body: ManagementViewport(
                maxWidth: 1280,
                child: SafeArea(
                  child: Column(
                    children: [
                      MarketPageHeader(
                        title: _dual(
                            strings, 'Customer details', 'Maelezo ya mteja'),
                        showBorder: false,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _dual(strings, 'Customer no longer exists',
                                'Mteja haipo tena'),
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          );
        }

        return _CustomerDetailsView(customer: customer);
      },
    );
  }
}

class _CustomerDetailsView extends StatelessWidget {
  const _CustomerDetailsView({required this.customer});

  final CustomerData customer;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final orders = store.ordersForCustomer(customer.name);
    final totalSpent =
        orders.fold<double>(0, (sum, order) => sum + order.total);
    final averageOrder = orders.isEmpty ? 0.0 : totalSpent / orders.length;
    final lastOrder = _latestOrder(orders);
    final points = ((totalSpent + customer.totalSpent) / 1000).round();
    final tier = _tierForSpend(totalSpent + customer.totalSpent);
    final ledger = store.debitEntriesFor(customer.id);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                MarketPageHeader(
                  title: _dual(strings, 'Customer details', 'Maelezo ya mteja'),
                  subtitle: _dual(strings, 'Profile, credit and order history',
                      'Wasifu, mkopo na historia ya oda'),
                  showBorder: false,
                  actions: [
                    IconButton(
                      tooltip: _dual(strings, 'Edit', 'Hariri'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CreateCustomerPage(existing: customer),
                        ),
                      ),
                      icon:
                          const Icon(Icons.edit_outlined, color: AppColors.ink),
                    ),
                    IconButton(
                      tooltip: _dual(strings, 'Delete', 'Futa'),
                      onPressed: () => _confirmDelete(context, customer, store),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                    children: [
                      _HeroCard(
                        customer: customer,
                        tier: tier,
                        points: points,
                        strings: strings,
                      ),
                      if (customer.debitBalance > 0 || ledger.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DebitSection(
                          customer: customer,
                          entries: ledger,
                          strings: strings,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _ContactActions(customer: customer, strings: strings),
                      const SizedBox(height: 16),
                      _StatsGrid(
                        totalSpent: totalSpent,
                        orderCount: orders.length,
                        averageOrder: averageOrder,
                        lastOrder: lastOrder,
                        strings: strings,
                      ),
                      if (customer.address.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InfoBlock(
                          icon: Icons.location_on_outlined,
                          label: _dual(strings, 'Address', 'Anwani'),
                          value: customer.address.trim(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _OrdersSection(orders: orders, strings: strings),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  static DateTime? _latestOrder(List<CompletedOrder> orders) {
    DateTime? latest;
    for (final order in orders) {
      final date = DateTime.tryParse(order.dateTime);
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    return latest;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerData customer,
    PosLocalStore store,
  ) async {
    final strings = AppStrings.of(store.languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          _dual(strings, 'Delete customer?', 'Futa mteja?'),
          style: AppTypography.cardHeader,
        ),
        content: Text(
          _dual(
            strings,
            'Remove ${customer.name} from your customer list. Past orders are kept.',
            'Ondoa ${customer.name} kwenye orodha ya wateja. Oda za zamani zitabaki.',
          ),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(_dual(strings, 'Delete', 'Futa')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await store.deleteCustomer(customer.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

enum _Tier { none, bronze, silver, gold, platinum }

_Tier _tierForSpend(double spent) {
  if (spent >= 2000000) return _Tier.platinum;
  if (spent >= 750000) return _Tier.gold;
  if (spent >= 250000) return _Tier.silver;
  if (spent > 0) return _Tier.bronze;
  return _Tier.none;
}

extension on _Tier {
  String label(AppStrings strings) => switch (this) {
        _Tier.none => _dual(strings, 'New', 'Mpya'),
        _Tier.bronze => 'Bronze',
        _Tier.silver => 'Silver',
        _Tier.gold => 'Gold',
        _Tier.platinum => 'Platinum',
      };

  Color get color => switch (this) {
        _Tier.none => AppColors.textMuted,
        _Tier.bronze => AppColors.warningDeep,
        _Tier.silver => AppColors.textBody,
        _Tier.gold => AppColors.warning,
        _Tier.platinum => AppColors.primaryDeep,
      };

  Color get background => switch (this) {
        _Tier.none => AppColors.surfaceSecondary,
        _Tier.bronze => AppColors.warningLight,
        _Tier.silver => AppColors.surfaceHover,
        _Tier.gold => AppColors.warningLight,
        _Tier.platinum => AppColors.primaryLight,
      };
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.customer,
    required this.tier,
    required this.points,
    required this.strings,
  });

  final CustomerData customer;
  final _Tier tier;
  final int points;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  customer.initials,
                  style: AppTypography.cardHeader.copyWith(
                    color: AppColors.textMuted,
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
                        _Pill(
                          label: tier.label(strings),
                          color: tier.color,
                          background: tier.background,
                        ),
                        if (customer.tags.isEmpty)
                          _Pill(
                            label: _dual(strings, 'No tags', 'Hakuna lebo'),
                            color: AppColors.textMuted,
                            background: AppColors.surfaceSecondary,
                          )
                        else
                          for (final tag in customer.tags)
                            _Pill(
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
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.call_outlined,
            label: _dual(strings, 'Phone', 'Simu'),
            value: customer.phone.trim().isEmpty
                ? _dual(strings, 'Not provided', 'Haijawekwa')
                : customer.phone,
          ),
          _DetailRow(
            icon: Icons.alternate_email_rounded,
            label: _dual(strings, 'Email', 'Barua pepe'),
            value: customer.email.trim().isEmpty
                ? _dual(strings, 'Not provided', 'Haijawekwa')
                : customer.email.trim(),
          ),
          _DetailRow(
            icon: Icons.event_outlined,
            label: _dual(strings, 'Customer since', 'Mteja tangu'),
            value: DateFormat('MMM d, yyyy').format(customer.createdAt),
          ),
          _DetailRow(
            icon: Icons.star_outline_rounded,
            label: _dual(strings, 'Loyalty points', 'Alama za uaminifu'),
            value: '$points',
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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
        borderRadius: BorderRadius.circular(AppRadius.pill),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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

class _DebitSection extends StatelessWidget {
  const _DebitSection({
    required this.customer,
    required this.entries,
    required this.strings,
  });

  final CustomerData customer;
  final List<DebitEntry> entries;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final charges = entries
        .where((entry) => !entry.isPayment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final paid = entries
        .where((entry) => entry.isPayment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final recent = entries.take(4).toList();
    final hasDebt = customer.debitBalance > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color:
                hasDebt ? AppColors.surfaceSecondary : AppColors.successLight,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: (hasDebt ? AppColors.ink : AppColors.success)
                  .withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasDebt
                        ? Icons.account_balance_wallet_outlined
                        : Icons.verified_rounded,
                    color: hasDebt ? AppColors.ink : AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasDebt
                          ? _dual(
                              strings, 'Outstanding credit', 'Deni la mteja')
                          : _dual(
                              strings, 'Account settled', 'Deni limekamilika'),
                      style: AppTypography.bodySmall.copyWith(
                        color: hasDebt ? AppColors.ink : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (hasDebt)
                    _DebitAction(
                      label: _dual(strings, 'Receive', 'Pokea'),
                      onTap: () => _receive(context),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatMoney(customer.debitBalance),
                style: AppTypography.h2.copyWith(
                  color: hasDebt ? AppColors.ink : AppColors.success,
                  fontSize: 22,
                ),
              ),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${_dual(strings, 'Charged', 'Deni')}: ${_formatMoney(charges)}   ·   ${_dual(strings, 'Paid', 'Malipo')}: ${_formatMoney(paid)}',
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final entry in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _LedgerRow(entry: entry, strings: strings),
            ),
          if (entries.length > recent.length)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _dual(
                    strings,
                    '+ ${entries.length - recent.length} earlier entries',
                    '+ rekodi ${entries.length - recent.length} za awali'),
                style: AppTypography.helperText.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _dual(strings, 'No credit activity recorded yet.',
                  'Hakuna shughuli ya mkopo iliyorekodiwa.'),
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _receive(BuildContext context) async {
    final strings = this.strings;
    final result = await showRecordPaymentSheet(context, customer: customer);
    if (result == null || !context.mounted) return;

    final store = context.read<PosLocalStore>();
    final applied = await store.recordDebtPayment(
      customerId: customer.id,
      amount: result.amount,
      note: result.note,
    );
    if (!context.mounted) return;

    if (applied == null) {
      showMarketNotice(
        context,
        title: _dual(strings, 'Payment not applied', 'Malipo hayajatumika'),
        message: _dual(
          strings,
          'The amount must be between 1 and the outstanding balance.',
          'Kiasi lazima kiwe kati ya 1 na deni lililobaki.',
        ),
        type: MarketNoticeType.warning,
      );
      return;
    }

    showMarketNotice(
      context,
      title: _dual(strings, 'Payment recorded', 'Malipo yamerekodiwa'),
      message: _dual(
        strings,
        '${_formatMoney(result.amount)} received. Balance ${_formatMoney(applied.debitBalance)}.',
        '${_formatMoney(result.amount)} yamepokelewa. Deni ${_formatMoney(applied.debitBalance)}.',
      ),
    );
  }
}

class _DebitAction extends StatelessWidget {
  const _DebitAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payments_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
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

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.strings});

  final DebitEntry entry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color = isPayment ? AppColors.success : AppColors.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            isPayment ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.localized(strings.isSwahili),
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.note.trim().isNotEmpty)
                  Text(
                    entry.note.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.textLight,
                      fontSize: 9.5,
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
                '${isPayment ? '-' : '+'}${_formatMoney(entry.amount)}',
                style: AppTypography.helperText.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                DateFormat('MMM d').format(entry.createdAt),
                style: AppTypography.helperText.copyWith(
                  color: AppColors.textLight,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({required this.customer, required this.strings});

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
          title: _dual(strings, 'Cannot open', 'Imeshindwa kufungua'),
          message: fallbackMsg,
          type: MarketNoticeType.warning,
        );
      }
    } catch (_) {
      if (context.mounted) {
        showMarketNotice(
          context,
          title: _dual(strings, 'Cannot open', 'Imeshindwa kufungua'),
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
          child: _ActionTile(
            icon: Icons.call_rounded,
            label: _dual(strings, 'Call', 'Piga'),
            enabled: hasPhone,
            onTap: hasPhone
                ? () => _open(
                    context,
                    'tel:$phone',
                    _dual(strings, 'Phone dialer unavailable',
                        'Simu haipatikani'))
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.message_rounded,
            label: _dual(strings, 'SMS', 'Ujumbe'),
            enabled: hasPhone,
            onTap: hasPhone
                ? () => _open(context, 'sms:$phone',
                    _dual(strings, 'SMS app unavailable', 'Ujumbe haupatikani'))
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.chat_bubble_rounded,
            label: _dual(strings, 'WhatsApp', 'WhatsApp'),
            enabled: hasPhone,
            onTap: hasPhone
                ? () {
                    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                    _open(
                        context,
                        'https://wa.me/$cleaned',
                        _dual(strings, 'WhatsApp unavailable',
                            'WhatsApp haipatikani'));
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
    final color = enabled ? AppColors.ink : AppColors.textLight;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.border),
          ),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
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
          child: _StatCard(
            label: _dual(strings, 'Total spent', 'Jumla'),
            value: _formatMoney(totalSpent, compact: true),
            icon: Icons.payments_outlined,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: _dual(strings, 'Orders', 'Oda'),
            value: '$orderCount',
            icon: Icons.receipt_long_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: _dual(strings, 'Avg order', 'Wastani'),
            value: _formatMoney(averageOrder, compact: true),
            icon: Icons.trending_up_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: _dual(strings, 'Last visit', 'Mara ya mwisho'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      showShadow: false,
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

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
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
      showShadow: false,
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

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({required this.orders, required this.strings});

  final List<CompletedOrder> orders;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final visible = orders.take(25).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarketSectionHeader(
          title: _dual(strings, 'Order history', 'Historia ya oda'),
          trailing: Text(
            _dual(
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
            showShadow: false,
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: AppColors.textLight, size: 32),
                const SizedBox(height: 8),
                Text(
                  _dual(strings, 'No orders yet', 'Hakuna oda bado'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dual(
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
                child: _OrderTile(order: order),
              )),
        if (orders.length > 25)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _dual(strings, '+ ${orders.length - 25} more orders',
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

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final CompletedOrder order;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: false,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(Icons.receipt_rounded,
                color: AppColors.textMuted, size: 16),
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
                _formatMoney(order.total, compact: true),
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
