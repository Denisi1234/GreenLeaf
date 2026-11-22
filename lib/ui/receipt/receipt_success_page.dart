import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/esc_pos_receipt_builder.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../../service/thermal_printer_service.dart';
import '../shell/app_shell.dart';
import '../widgets/app_design.dart';
import '../widgets/market_bottom_nav.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'receipt_document.dart';
import 'receipt_preview_page.dart';
import 'thermal_printer_picker_sheet.dart';

class ReceiptSuccessPage extends StatelessWidget {
  const ReceiptSuccessPage({super.key, required this.order});
  final CompletedOrder order;
  void _newSale(BuildContext context) =>
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
              builder: (_) => const AppShell(initialTab: MarketTab.sales)),
          (_) => false);

  Future<void> _thermalPrint(
    BuildContext context,
    ReceiptDocument receipt,
  ) async {
    final store = context.read<PosLocalStore>();
    var prefs = store.storePreferences;
    var address = prefs.thermalPrinterAddress.trim();
    if (address.isEmpty) {
      final picked = await showThermalPrinterPicker(context);
      if (picked == null || !context.mounted) return;
      address = picked.address;
      prefs = prefs.copyWith(
        thermalPrinterName: picked.name,
        thermalPrinterAddress: picked.address,
      );
      await store.setStorePreferences(prefs);
    }
    try {
      await ThermalPrinterService.instance.printReceipt(
        receipt: receipt,
        address: address,
        paperWidth: ThermalPaperWidth.fromMm(prefs.thermalPaperWidthMm),
        openCashDrawer: prefs.openCashDrawerOnPrint,
      );
      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: context.tr('Receipt sent'),
        message: context.tr('Printed on Bluetooth thermal printer.'),
        type: MarketNoticeType.success,
      );
    } catch (error) {
      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: context.tr('Print failed'),
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final profile = store.profile;
    final receipt = ReceiptDocument(
        order: order,
        languageCode: context.strings.languageCode,
        storeName: profile.storeName,
        storeAddress: profile.physicalAddress,
        storePhone: profile.contactNumber,
        storeTaxId: profile.taxId,
        storeLogoPath: profile.logoPath,
        currency: profile.currency,
        settings: store.receiptSettings);
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
                                      height: 48,
                                      child: FilledButton.icon(
                                        onPressed: () => _newSale(context),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.button),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add_rounded),
                                        label: Text(
                                          context.tr('New sale'),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      )),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _thermalPrint(context, receipt),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColors.kpiSkyBg,
                                          foregroundColor: AppColors.kpiSky,
                                          side: BorderSide.none,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.button),
                                          ),
                                        ),
                                        icon: const Icon(Icons.print_rounded),
                                        label: Text(
                                          context.tr('Thermal print'),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      )),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.of(context)
                                            .push(MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ReceiptPreviewPage(
                                                        order: order))),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.kpiVioletBg,
                                          foregroundColor: AppColors.kpiViolet,
                                          side: BorderSide.none,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.button),
                                          ),
                                        ),
                                        icon: const Icon(
                                            Icons.receipt_long_outlined),
                                        label: Text(
                                          context.tr('View receipt'),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
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
