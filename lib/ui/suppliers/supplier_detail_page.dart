import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'receiving_page.dart';
import 'supplier_form_page.dart';

/// Supplier detail: profile, balance, and receiving history.
class SupplierDetailPage extends StatelessWidget {
  const SupplierDetailPage({super.key, required this.supplierId});

  final int? supplierId;

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    Supplier? supplier;
    if (supplierId != null) {
      for (final s in store.suppliers) {
        if (s.id == supplierId) {
          supplier = s;
          break;
        }
      }
    }

    if (supplier == null) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: ManagementViewport(
            maxWidth: 1280,
            child: SafeArea(
              child: Column(
                children: [
                  MarketPageHeader(
                    title: t('Supplier', 'Msambazaji'),
                    transparentBackButton: true,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        MarketSurfaceCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            t('Supplier not found.', 'Msambazaji hajapatikana.'),
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      );
    }

    final s = supplier;
    final balance = store.supplierBalance(s.id ?? 0);
    final history = store.receivings.where((r) => r.supplierId == s.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final receivedTotal = history.fold<double>(0, (sum, r) => sum + r.total);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: s.name,
                  subtitle: t('Supplier details', 'Taarifa za msambazaji'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('Current payable', 'Deni la sasa'),
                                style: AppTypography.label
                                    .copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              _money(balance),
                              style: AppTypography.h1.copyWith(
                                fontSize: 28,
                                color: balance > 0
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _kv(
                                    t('Opening balance', 'Deni la kuanzia'),
                                    _money(s.openingBalance),
                                    s.openingBalance > 0
                                        ? AppColors.danger
                                        : AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _kv(
                                    t('Goods received', 'Zilizopokelewa'),
                                    _money(receivedTotal),
                                    receivedTotal > 0
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _kv(
                              t('Receiving records', 'Rekodi za upokeaji'),
                              '${history.length}',
                              AppColors.ink,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _info(t('Phone', 'Simu'),
                                s.phone.trim().isEmpty ? '—' : s.phone.trim()),
                            _info(t('Email', 'Barua pepe'),
                                s.email.trim().isEmpty ? '—' : s.email.trim()),
                            _info(
                                t('Address', 'Anwani'),
                                s.address.trim().isEmpty
                                    ? '—'
                                    : s.address.trim()),
                            if (s.notes.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(
                                  height: 1, color: AppColors.divider),
                              const SizedBox(height: 8),
                              Text(t('Notes', 'Maelezo'),
                                  style: AppTypography.label
                                      .copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                s.notes.trim(),
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textBody, height: 1.45),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: MarketButton(
                              label: t('Edit', 'Hariri'),
                              icon: Icons.edit_outlined,
                              isPrimary: false,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) =>
                                      SupplierFormPage(supplier: s),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MarketButton(
                              label: t('Receive goods', 'Pokea bidhaa'),
                              icon: Icons.move_to_inbox_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) =>
                                      ReceivingPage(presetSupplier: s),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t('Receiving history', 'Historia ya upokeaji'),
                        style: AppTypography.sectionHeader
                            .copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      if (history.isEmpty)
                        MarketSurfaceCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            t('No goods received from this supplier yet.',
                                'Hakuna bidhaa zilizopokelewa kutoka kwa msambazaji huyu bado.'),
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        )
                      else
                        MarketSurfaceCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < history.length; i++) ...[
                                _HistoryRow(
                                    receiving: history[i], isSwahili: sw),
                                if (i != history.length - 1)
                                  const Divider(
                                      height: 1, color: AppColors.divider),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  static Widget _kv(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTypography.helperText.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall
              .copyWith(fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  static Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.receiving, required this.isSwahili});
  final Receiving receiving;
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    final d = receiving.date.toLocal();
    final stamp =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiving.invoiceNo.trim().isEmpty
                      ? (isSwahili ? 'Upokeaji' : 'Receiving')
                      : receiving.invoiceNo.trim(),
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$stamp • ${receiving.itemCount} ${isSwahili ? 'vipande' : 'units'} • ${receiving.lines.length} ${isSwahili ? 'bidhaa' : 'items'}',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            SupplierDetailPage._money(receiving.total),
            style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
