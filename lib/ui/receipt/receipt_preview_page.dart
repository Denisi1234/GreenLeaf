import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../shell/app_shell.dart';
import '../widgets/app_design.dart';
import '../widgets/app_image.dart';
import '../widgets/market_bottom_nav.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'receipt_document.dart';
import 'receipt_pdf_service.dart';

class ReceiptPreviewPage extends StatefulWidget {
  const ReceiptPreviewPage({super.key, required this.order});
  final CompletedOrder order;
  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  late final ReceiptDocument _receipt;
  Future<Uint8List>? _pdf;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<PosLocalStore>();
    final profile = store.profile;
    _receipt = ReceiptDocument(
        order: widget.order,
        storeName: profile.storeName,
        storeAddress: profile.physicalAddress,
        storePhone: profile.contactNumber,
        storeTaxId: profile.taxId,
        storeLogoPath: profile.logoPath,
        currency: profile.currency,
        settings: store.receiptSettings);
  }

  Future<Uint8List> _bytes() async {
    try {
      return await (_pdf ??= ReceiptPdfService.buildReceiptBytes(_receipt));
    } catch (_) {
      _pdf = null;
      rethrow;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted)
        showMarketNotice(context,
            title: 'Receipt action failed',
            message: 'Please try again. The saved sale has not been removed.',
            type: MarketNoticeType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _fileName =>
      'receipt_${widget.order.receiptNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';

  Future<void> _share() async {
    await Printing.sharePdf(bytes: await _bytes(), filename: _fileName);
  }

  Future<void> _print() async {
    final bytes = await _bytes();
    await Printing.layoutPdf(name: _fileName, onLayout: (_) async => bytes);
  }

  Future<void> _download() async {
    Directory? directory;
    try {
      directory = await getDownloadsDirectory();
    } catch (_) {/* Documents is the supported fallback. */}
    directory ??= await getApplicationDocumentsDirectory();
    await directory.create(recursive: true);
    final file = File('${directory.path}${Platform.pathSeparator}$_fileName');
    await file.writeAsBytes(await _bytes(), flush: true);
    if (mounted)
      showMarketNotice(context, title: 'Receipt saved', message: file.path);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _receipt.toText()));
    if (mounted)
      showMarketNotice(context,
          title: 'Copied', message: 'Receipt details copied to clipboard.');
  }

  Future<void> _sms() async {
    var phone = '';
    for (final customer in context.read<PosLocalStore>().customers) {
      if (customer.name.trim().toLowerCase() ==
          widget.order.customerName?.trim().toLowerCase()) {
        phone = customer.phone;
        break;
      }
    }
    final uri = Uri(
        scheme: 'sms',
        path: phone,
        query: 'body=${Uri.encodeComponent(_receipt.toText())}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
      throw StateError('SMS unavailable');
  }

  Future<void> _whatsApp() async {
    final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(_receipt.toText())}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
      throw StateError('WhatsApp unavailable');
  }

  Future<void> _changeSale({required bool edit}) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title:
                  Text(edit ? 'Reopen sale for editing?' : 'Void this sale?'),
              content: Text(edit
                  ? 'The original sale will be voided and its items returned to the cart for editing.'
                  : 'This will void the recorded sale and return its items to stock.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                        backgroundColor:
                            edit ? AppColors.ink : AppColors.dangerDeep),
                    child: Text(edit ? 'Reopen sale' : 'Void sale')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    final store = context.read<PosLocalStore>();
    if (edit) {
      await store.reopenOrderForEdit(widget.order.id);
    } else {
      await store.voidOrder(widget.order.id);
    }
    if (mounted) _newSale();
  }

  void _newSale() => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
          builder: (_) => const AppShell(initialTab: MarketTab.sales)),
      (_) => false);

  void _option(String option) {
    _run(switch (option) {
      'download' => _download,
      'copy' => _copy,
      'sms' => _sms,
      'whatsapp' => _whatsApp,
      'edit' => () => _changeSale(edit: true),
      _ => () => _changeSale(edit: false),
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(title: const Text('Receipt'), actions: [
          PopupMenuButton<String>(
            tooltip: 'Receipt options',
            enabled: !_busy,
            onSelected: _option,
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'download', child: Text('Download PDF')),
              const PopupMenuItem(
                  value: 'copy', child: Text('Copy receipt text')),
              const PopupMenuItem(value: 'sms', child: Text('Open in SMS')),
              const PopupMenuItem(
                  value: 'whatsapp', child: Text('Open in WhatsApp')),
              if (!_receipt.isVoided) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                    value: 'edit', child: Text('Reopen for editing')),
                const PopupMenuItem(
                    value: 'void',
                    child: Text('Void sale',
                        style: TextStyle(color: AppColors.dangerDeep))),
              ],
            ],
          ),
          const SizedBox(width: 8),
        ]),
        body: SafeArea(
            top: false,
            child: ManagementViewport(
                maxWidth: 1000,
                child: Column(children: [
                  if (_busy) const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                              child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: ReceiptPaper(receipt: _receipt),
                          )))),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border:
                            Border(top: BorderSide(color: AppColors.border))),
                    child: LayoutBuilder(
                        builder: (context, constraints) =>
                            Wrap(spacing: 12, runSpacing: 10, children: [
                              OutlinedButton.icon(
                                  onPressed: _busy ? null : () => _run(_print),
                                  icon: const Icon(Icons.print_outlined,
                                      size: 19),
                                  label: const Text('Print')),
                              OutlinedButton.icon(
                                  onPressed: _busy ? null : () => _run(_share),
                                  icon: const Icon(Icons.share_outlined,
                                      size: 19),
                                  label: const Text('Share PDF')),
                              FilledButton.icon(
                                  onPressed: _busy ? null : _newSale,
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.ink),
                                  icon: const Icon(Icons.add_rounded, size: 19),
                                  label: const Text('New sale')),
                            ])),
                  ),
                ]))),
      ));
}

class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({super.key, required this.receipt});
  final ReceiptDocument receipt;
  @override
  Widget build(BuildContext context) => WorkspacePanel(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (receipt.storeLogoPath?.isNotEmpty == true) ...[
            Image(
                image: appImageProvider(context, receipt.storeLogoPath!),
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            const SizedBox(width: 14),
          ],
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(receipt.businessName, style: AppTypography.h2),
                if (receipt.settings.showStoreContact &&
                    receipt.storeAddress.trim().isNotEmpty)
                  Text(receipt.storeAddress, style: AppTypography.bodySmall),
                if (receipt.settings.showStoreContact &&
                    receipt.storePhone.trim().isNotEmpty)
                  Text(receipt.storePhone, style: AppTypography.bodySmall),
                if (receipt.settings.showTaxId &&
                    receipt.storeTaxId.trim().isNotEmpty)
                  Text('TIN: ${receipt.storeTaxId}',
                      style: AppTypography.bodySmall),
              ])),
        ]),
        const SizedBox(height: 16),
        Align(
            alignment: Alignment.centerLeft,
            child: WorkspaceStatus(
                label: receipt.statusLabel,
                color: receipt.isVoided
                    ? AppColors.dangerDeep
                    : receipt.isCredit
                        ? AppColors.textBody
                        : AppColors.successDeep)),
        if (receipt.settings.header.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(receipt.settings.header, style: AppTypography.bodyMedium)
        ],
        const Divider(height: 32),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 460 ? 2 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
          return Wrap(spacing: 16, runSpacing: 14, children: [
            for (final item in receipt.metadata)
              SizedBox(
                  width: width,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.key, style: AppTypography.label),
                        const SizedBox(height: 3),
                        Text(item.value, style: AppTypography.bodySmall),
                      ]))
          ]);
        }),
        const Divider(height: 32),
        for (final line in receipt.order.lines)
          Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.itemName,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(
                                  '${line.quantity} × ${receipt.money(line.unitPriceValue)}',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.textMuted))),
                          const SizedBox(width: 12),
                          Flexible(
                              child: Text(receipt.money(line.lineTotal),
                                  textAlign: TextAlign.right,
                                  style: AppTypography.bodySmall
                                      .copyWith(fontWeight: FontWeight.w700))),
                        ]),
                  ])),
        const Divider(height: 16),
        for (final total in receipt.totals)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                Expanded(
                    child: Text(total.key,
                        style: total.key == 'Total'
                            ? AppTypography.sectionHeader
                            : AppTypography.bodySmall)),
                const SizedBox(width: 16),
                Flexible(
                    child: Text(total.value,
                        textAlign: TextAlign.right,
                        style: total.key == 'Total'
                            ? AppTypography.h3
                            : AppTypography.bodySmall)),
              ])),
        const Divider(height: 32),
        Text(receipt.footer,
            textAlign: TextAlign.center,
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
      ]));
}
