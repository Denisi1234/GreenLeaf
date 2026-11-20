import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../shell/app_shell.dart';
import '../widgets/app_design.dart';
import '../widgets/market_bottom_nav.dart';
import '../widgets/workspace_widgets.dart';
import 'receipt_document.dart';
import 'receipt_preview_page.dart';

class ReceiptSuccessPage extends StatelessWidget {
  const ReceiptSuccessPage({super.key, required this.order});
  final CompletedOrder order;
  void _newSale(BuildContext context) =>
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
              builder: (_) => const AppShell(initialTab: MarketTab.sales)),
          (_) => false);
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<PosLocalStore>().profile;
    final receipt = ReceiptDocument(
        order: order, languageCode: context.strings.languageCode, storeName: profile.storeName, currency: profile.currency);
    return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: WorkspacePanel(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      receipt.isCredit
                                          ? Icons.receipt_long_outlined
                                          : Icons.check_circle_outline_rounded,
                                      size: 52,
                                      color: receipt.isCredit
                                          ? AppColors.ink
                                          : AppColors.successDeep),
                                  const SizedBox(height: 20),
                                  Text(receipt.statusLabel,
                                      style: AppTypography.h2,
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  Text(
                                      receipt.isCredit
                                          ? context.tr('The sale is recorded. Payment remains due from the customer.')
                                          : context.tr('The sale has been saved. Your receipt is ready.'),
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodySmall),
                                  const SizedBox(height: 24),
                                  FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(receipt.money(order.total),
                                          style: AppTypography.h1
                                              .copyWith(fontSize: 32))),
                                  const SizedBox(height: 8),
                                  Text(
                                      context.tr('{p0} units • {p1}', args: {'p0': receipt.units, 'p1': receipt.paymentLabel}),
                                      style: AppTypography.bodySmall),
                                  const Divider(height: 32),
                                  _Detail(
                                      label: context.tr('Receipt'), value: order.receiptNo),
                                  _Detail(
                                      label: context.tr('Date'),
                                      value:
                                          '${order.date} ${order.time}'.trim()),
                                  if (order.customerName?.isNotEmpty == true)
                                    _Detail(
                                        label: context.tr('Customer'),
                                        value: order.customerName!),
                                  if (receipt.isCash)
                                    _Detail(
                                        label: context.tr('Change due'),
                                        value: receipt.money(order.changeDue)),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: () => _newSale(context),
                                        style: FilledButton.styleFrom(
                                            backgroundColor:
                                                AppColors.successDeep),
                                        icon: const Icon(Icons.add_rounded),
                                        label:  Text(context.tr('New sale')),
                                      )),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.of(context)
                                            .push(MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ReceiptPreviewPage(
                                                        order: order))),
                                        icon: const Icon(
                                            Icons.receipt_long_outlined),
                                        label:  Text(context.tr('View receipt')),
                                      )),
                                ])),
                      )))),
        ));
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: AppTypography.label)),
        const SizedBox(width: 16),
        Flexible(
            flex: 2,
            child: Text(value,
                style: AppTypography.bodySmall, textAlign: TextAlign.right)),
      ]));
}
