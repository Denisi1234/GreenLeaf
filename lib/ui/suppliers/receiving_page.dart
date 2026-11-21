import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'new_receiving_page.dart';
import 'widgets/receiving_row.dart';

/// Goods received register: lists stock-in documents and opens receiving flow.
class ReceivingPage extends StatefulWidget {
  const ReceivingPage({super.key, this.presetSupplier});

  final Supplier? presetSupplier;

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  static Widget _flatCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return MarketSurfaceCard(
      padding: padding,
      showShadow: false,
      borderColor: AppColors.border,
      radius: 0,
      child: child,
    );
  }

  static Future<void> _confirmDelete(BuildContext context, Receiving receiving) async {
    if (receiving.id == null) return;
    final store = context.read<PosLocalStore>();
    final sw = store.languageCode == 'sw';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title: Text(sw ? 'Futa upokeaji?' : 'Delete receiving record?'),
        content: Text(
          sw
              ? 'Rekodi itaondolewa. Hifadhi iliyoongezwa haitarejeshwa kiotomatiki.'
              : 'The record will be removed. Stock added by this delivery will not be reversed automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(sw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.standard),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.deleteReceiving(receiving.id!);
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: sw ? 'Upokeaji Umefutwa' : 'Receiving Deleted',
      message: sw
          ? 'Rekodi ya upokeaji imefutwa'
          : 'Receiving record deleted successfully',
      type: MarketNoticeType.success,
    );
  }

  @override
  State<ReceivingPage> createState() => _ReceivingPageState();
}

class _ReceivingPageState extends State<ReceivingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final receivings = store.receivings;
    final totalValue = receivings.fold<double>(
      0,
      (sum, receiving) => sum + receiving.total,
    );
    final totalUnits = receivings.fold<int>(
      0,
      (sum, receiving) => sum + receiving.itemCount,
    );
    final now = DateTime.now();
    final thisMonthReceivings = receivings.where((r) =>
        r.date.year == now.year && r.date.month == now.month).toList();
    final thisMonthTotal = thisMonthReceivings.fold<double>(
      0,
      (sum, receiving) => sum + receiving.total,
    );

    final filtered = _query.isEmpty
        ? receivings
        : receivings.where((r) {
            final q = _query.toLowerCase();
            return r.supplierName.toLowerCase().contains(q) ||
                r.invoiceNo.toLowerCase().contains(q) ||
                r.lines.any((l) => l.productName.toLowerCase().contains(q));
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: t('Goods received', 'Bidhaa zilizopokelewa'),
                  subtitle: t('Deliveries, stock-in records, and supplier purchase orders',
                      'Usambazaji, rekodi za kuingiza mzigo na manunuzi ya wasambazaji'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      LayoutBuilder(
                        builder: (context, metricConstraints) {
                          final columns =
                              metricConstraints.maxWidth >= 760 ? 4 : 2;
                          final width = (metricConstraints.maxWidth -
                                  (columns - 1) * 12) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: width,
                                child: WorkspaceMetric(
                                  label: t('Total received value', 'Jumla ya thamani'),
                                  value: ReceivingPage._money(totalValue),
                                  icon: Icons.inventory_2_outlined,
                                  sharp: true,
                                  borderless: true,
                                  backgroundColor: const Color(0xFFD1FAE5),
                                  color: const Color(0xFF047857),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: WorkspaceMetric(
                                  label: t('Total deliveries', 'Idadi ya upokeaji'),
                                  value: '${receivings.length}',
                                  icon: Icons.local_shipping_outlined,
                                  sharp: true,
                                  borderless: true,
                                  backgroundColor: const Color(0xFFE0F2FE),
                                  color: const Color(0xFF0369A1),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: WorkspaceMetric(
                                  label: t('Total units added', 'Jumla ya vipande'),
                                  value: '$totalUnits',
                                  icon: Icons.all_inbox_rounded,
                                  sharp: true,
                                  borderless: true,
                                  backgroundColor: const Color(0xFFFCE7F3),
                                  color: const Color(0xFFBE185D),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: WorkspaceMetric(
                                  label: t('This month value', 'Thamani mwezi huu'),
                                  value: ReceivingPage._money(thisMonthTotal),
                                  icon: Icons.calendar_today_outlined,
                                  sharp: true,
                                  borderless: true,
                                  backgroundColor: const Color(0xFFFEF3C7),
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MarketButton(
                              label: t('New receiving', 'Upokeaji mpya'),
                              icon: Icons.add_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => NewReceivingPage(
                                      presetSupplier: widget.presetSupplier),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MarketSearchField(
                        controller: _searchController,
                        hintText: t('Search by supplier, invoice #, product...',
                            'Tafuta kwa msambazaji, ankara, au bidhaa...'),
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        radius: 0,
                        showShadow: false,
                        backgroundColor: AppColors.surface,
                      ),
                      const SizedBox(height: 12),
                      if (receivings.isEmpty)
                        ReceivingEmptyState(
                          isSwahili: sw,
                          isFiltered: false,
                          onNew: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => NewReceivingPage(
                                  presetSupplier: widget.presetSupplier),
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        ReceivingEmptyState(
                          isSwahili: sw,
                          isFiltered: true,
                          onNew: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => NewReceivingPage(
                                  presetSupplier: widget.presetSupplier),
                            ),
                          ),
                          onClearFilter: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      else
                        ReceivingPage._flatCard(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Column(
                            children: [
                              for (var i = 0; i < filtered.length; i++) ...[
                                ReceivingRow(
                                  receiving: filtered[i],
                                  isSwahili: sw,
                                  onDelete: () => ReceivingPage._confirmDelete(
                                      context, filtered[i]),
                                ),
                                if (i != filtered.length - 1)
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
}
