import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../../service/receipt_settings.dart';
import '../models/product_item.dart';
import '../shell/app_shell.dart';
import '../widgets/app_design.dart';
import '../widgets/market_bottom_nav.dart';
import '../widgets/market_shared_widgets.dart';
import 'receipt_pdf_service.dart';

class ReceiptPreviewPage extends StatefulWidget {
  const ReceiptPreviewPage({
    super.key,
    required this.order,
  });

  final CompletedOrder order;

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  static const MethodChannel _shareChannel = MethodChannel('trackmauzo/share');

  File? _preparedPdf;
  bool _isPreparing = false;
  late final AppProfileData _profile;
  late final ReceiptSettings _receiptSettings;

  String get _storeAddress =>
      _receiptSettings.showStoreContact ? _profile.physicalAddress.trim() : '';
  String get _storePhone =>
      _receiptSettings.showStoreContact ? _profile.contactNumber.trim() : '';

  List<OrderLineItem> get _pdfItems => widget.order.lines
      .map(
        (line) => OrderLineItem(
          product: line.product,
          quantity: line.quantity,
        ),
      )
      .toList();

  double get _subtotal =>
      widget.order.lines.fold(0, (sum, line) => sum + line.lineTotal);

  @override
  void initState() {
    super.initState();
    final store = context.read<PosLocalStore>();
    _profile = store.profile;
    _receiptSettings = store.receiptSettings;
    _preparePdf();
  }

  String _money(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'TSh${buffer.toString()}.$decimal';
  }

  String _cleanValue(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Future<File> _createPdf() {
    return ReceiptPdfService.createReceiptPdf(
      items: _pdfItems,
      total: widget.order.total,
      cashTendered: widget.order.cashTendered,
      changeDue: widget.order.changeDue,
      receiptNumber: widget.order.id,
      cashier: widget.order.cashierName,
      register: widget.order.register,
      date: widget.order.date,
      time: widget.order.time,
      customerName: widget.order.customerName,
      discountAmount: widget.order.discountAmount,
      discountLabel: widget.order.discountLabel,
      storeName: _profile.storeName,
      storeAddress: _storeAddress,
      storePhone: _storePhone,
      storeTaxId: _profile.taxId,
      paymentMethod: widget.order.paymentMethod,
      header: _receiptSettings.header,
      footer: _receiptSettings.footer,
      showTaxId: _receiptSettings.showTaxId,
      showOrderNumber: _receiptSettings.showOrderNumber,
      showDateTime: _receiptSettings.showDateTime,
      showCashier: _receiptSettings.showCashier,
      showCustomer: _receiptSettings.showCustomer,
      showPaymentMethod: _receiptSettings.showPaymentMethod,
      showItemCount: _receiptSettings.showItemCount,
      showDiscount: _receiptSettings.showDiscount,
    );
  }

  Future<void> _preparePdf() async {
    if (_isPreparing) return;
    setState(() => _isPreparing = true);

    try {
      final pdfFile = await _createPdf();
      if (!mounted) return;
      setState(() {
        _preparedPdf = pdfFile;
        _isPreparing = false;
      });
    } catch (error) {
      debugPrint('Failed to pre-generate PDF: $error');
      if (!mounted) return;
      setState(() => _isPreparing = false);
    }
  }

  Future<File?> _ensurePdf() async {
    File? pdfFile = _preparedPdf;
    if (pdfFile != null) return pdfFile;

    if (_isPreparing) {
      _showNotice(
        title: 'Preparing Receipt',
        message: 'One moment while we finish the PDF...',
      );
      var attempts = 0;
      while (_isPreparing && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
      pdfFile = _preparedPdf;
    }

    if (pdfFile != null) return pdfFile;

    try {
      pdfFile = await _createPdf();
      if (!mounted) return null;
      setState(() => _preparedPdf = pdfFile);
      return pdfFile;
    } catch (_) {
      if (!mounted) return null;
      _showNotice(
        title: 'Receipt Error',
        message: 'Receipt PDF could not be prepared',
        type: MarketNoticeType.warning,
      );
      return null;
    }
  }

  void _showNotice({
    required String title,
    required String message,
    MarketNoticeType type = MarketNoticeType.success,
  }) {
    if (!mounted) return;
    showMarketNotice(
      context,
      title: title,
      message: message,
      type: type,
    );
  }

  String _buildWhatsAppMessage() {
    final storeName = _cleanValue(_profile.storeName, 'Store');
    final storeAddress = _storeAddress;
    final storePhone = _storePhone;
    final buffer = StringBuffer()
      ..writeln('━━━━━ *${storeName.toUpperCase()}* ━━━━━')
      ..writeln('📄 *Receipt:* #${widget.order.id}')
      ..writeln('📅 *Date:* ${widget.order.date}')
      ..writeln('');

    if (storeAddress.isNotEmpty) {
      buffer.writeln('📍 $storeAddress');
    }
    if (storePhone.isNotEmpty) {
      buffer.writeln('📞 Tel: $storePhone');
    }
    if (storeAddress.isNotEmpty || storePhone.isNotEmpty) {
      buffer.writeln('');
    }

    if (widget.order.customerName != null &&
        widget.order.customerName!.trim().isNotEmpty) {
      buffer.writeln('👤 *Customer:* ${widget.order.customerName}');
      buffer.writeln('');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    for (final line in widget.order.lines) {
      buffer.writeln(
        '• ${line.itemName} (x${line.quantity}) — ${_money(line.lineTotal)}',
      );
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Subtotal: ${_money(_subtotal)}');

    if (widget.order.discountAmount != null &&
        widget.order.discountAmount! > 0) {
      buffer.writeln(
          '${widget.order.discountLabel ?? 'Discount'}: -${_money(widget.order.discountAmount!)}');
    }

    buffer.writeln('💰 *Total: ${_money(widget.order.total)}*');
    buffer.writeln('');
    buffer.writeln('Cash Tendered: ${_money(widget.order.cashTendered)}');
    buffer.writeln('Change Due: ${_money(widget.order.changeDue)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '✨ *${_cleanValue(_receiptSettings.footer, 'Thank you for your business!')}*',
    );

    return buffer.toString();
  }

  Future<void> _shareToWhatsApp() async {
    try {
      final pdfFile = await _ensurePdf();
      if (pdfFile == null) return;

      final message = _buildWhatsAppMessage();

      var customShared = false;
      if (Platform.isAndroid) {
        try {
          customShared = await _shareChannel.invokeMethod<bool>(
                'shareReceiptToWhatsApp',
                <String, Object?>{
                  'filePath': pdfFile.path,
                  'text': message,
                },
              ) ??
              false;
        } catch (error) {
          debugPrint('Custom WhatsApp share failed: $error');
        }
      }

      if (customShared) {
        _showNotice(
          title: 'WhatsApp Ready',
          message: 'Receipt PDF opened in WhatsApp',
        );
        return;
      }

      final webUri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}',
      );
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        _showNotice(
          title: 'WhatsApp Opened',
          message: 'WhatsApp opened with receipt details',
        );
        return;
      }

      _showNotice(
        title: 'Share Unavailable',
        message: 'WhatsApp could not be opened on this device',
        type: MarketNoticeType.warning,
      );
    } on PlatformException catch (error) {
      _showNotice(
        title: 'Share Failed',
        message: error.message ?? 'Receipt could not be shared',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<void> _sharePdf() async {
    try {
      final pdfFile = await _ensurePdf();
      if (pdfFile == null) return;
      final pdfBytes = await pdfFile.readAsBytes();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'receipt_${widget.order.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.pdf',
      );
    } catch (error, stack) {
      debugPrint('Share PDF error: $error\n$stack');
      _showNotice(
        title: 'Share Failed',
        message: 'Could not share receipt: ${error.toString()}',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<void> _printReceipt() async {
    final pdfFile = await _ensurePdf();
    if (pdfFile == null) return;
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _downloadReceipt() async {
    final pdfFile = await _ensurePdf();
    if (pdfFile == null || !mounted) return;

    try {
      final targetFile = await _saveReceiptPdf(pdfFile, widget.order.id);
      _showNotice(
        title: 'Receipt Downloaded',
        message: 'Saved to ${targetFile.path}',
      );
    } catch (_) {
      _showNotice(
        title: 'Download Failed',
        message: 'Receipt PDF could not be saved',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<File> _saveReceiptPdf(File sourceFile, String receiptNumber) async {
    final safeName = receiptNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final fileName = 'receipt_$safeName.pdf';

    final targetDirectories = <Directory>[];

    if (Platform.isAndroid) {
      targetDirectories.add(Directory('/storage/emulated/0/Download'));
    }

    final downloadsDirectory = await getDownloadsDirectory();
    if (downloadsDirectory != null) {
      targetDirectories.add(downloadsDirectory);
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    targetDirectories.add(
      Directory(path.join(documentsDirectory.path, 'downloaded_receipts')),
    );

    for (final directory in targetDirectories) {
      try {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final targetFile = File(path.join(directory.path, fileName));
        await sourceFile.copy(targetFile.path);
        return targetFile;
      } catch (_) {
        continue;
      }
    }

    throw const FileSystemException('No writable download directory found');
  }

  void _showPlaceholderAction(BuildContext context, String label) {
    showMarketNotice(
      context,
      title: label,
      message: '$label is not connected yet',
      type: MarketNoticeType.warning,
    );
  }

  void _startNewSale() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => const AppShell(
          initialTab: MarketTab.sales,
        ),
      ),
      (route) => false,
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDanger ? AppColors.danger : AppColors.primary,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeName = _cleanValue(_profile.storeName, 'Store receipt');

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: 'Receipt',
              subtitle: '#${widget.order.id}',
              trailing: Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  IconButton(
                    onPressed: _sharePdf,
                    icon: const Icon(Icons.share_outlined,
                        color: AppColors.textMedium),
                  ),
                  IconButton(
                    onPressed: () => _showPlaceholderAction(context, 'SMS'),
                    icon: const Icon(Icons.sms_outlined,
                        color: AppColors.textMedium),
                  ),
                  IconButton(
                    onPressed: _shareToWhatsApp,
                    icon: const Icon(Icons.chat_outlined,
                        color: AppColors.textMedium),
                  ),
                  IconButton(
                    onPressed: _downloadReceipt,
                    icon: const Icon(Icons.download_outlined,
                        color: AppColors.textMedium),
                  ),
                  IconButton(
                    onPressed: _printReceipt,
                    icon: const Icon(Icons.print_outlined,
                        color: AppColors.textMedium),
                  ),
                  IconButton(
                    onPressed: () => _showPlaceholderAction(context, 'More'),
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TopActionButton(
                    label: 'RETURN',
                    color: AppColors.ink,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  _TopActionButton(
                    label: 'DELETE',
                    color: AppColors.danger,
                    onTap: () async {
                      final store = context.read<PosLocalStore>();
                      final confirmed = await _showConfirmDialog(
                        context,
                        title: 'Delete Order?',
                        message:
                            'This will permanently remove the order and restore product stock.',
                        actionLabel: 'Delete',
                        isDanger: true,
                      );
                      if (confirmed == true && mounted) {
                        await store.voidOrder(widget.order.id);
                        if (!mounted) return;
                        _startNewSale();
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  _TopActionButton(
                    label: 'EDIT',
                    color: AppColors.ink,
                    onTap: () async {
                      final store = context.read<PosLocalStore>();
                      final confirmed = await _showConfirmDialog(
                        context,
                        title: 'Edit Order?',
                        message:
                            'The current order will be voided, and its items will be re-added to your cart for editing.',
                        actionLabel: 'Edit',
                      );
                      if (confirmed == true && mounted) {
                        await store.reopenOrderForEdit(widget.order.id);
                        if (!mounted) return;
                        _startNewSale();
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 94),
                child: _ReceiptPaper(
                  storeName: storeName,
                  storeAddress: _storeAddress,
                  storePhone: _storePhone,
                  storeTaxId: _profile.taxId,
                  header: _receiptSettings.header,
                  footer: _cleanValue(
                    _receiptSettings.footer,
                    'THANK YOU FOR YOUR BUSINESS',
                  ),
                  receiptNumber: widget.order.id,
                  date: widget.order.date,
                  time: widget.order.time,
                  cashier: widget.order.cashierName,
                  paymentMethod: widget.order.paymentMethod,
                  settings: _receiptSettings,
                  items: widget.order.lines,
                  subtotal: _subtotal,
                  customerName: widget.order.customerName,
                  discountAmount: widget.order.discountAmount,
                  discountLabel: widget.order.discountLabel,
                  grandTotal: widget.order.total,
                  cashReceived: widget.order.cashTendered,
                  changeAmount: widget.order.changeDue,
                  money: _money,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
              child: GestureDetector(
                onTap: _startNewSale,
                child: Container(
                  width: double.infinity,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'New Sale',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MarketSurfaceCard(
        padding: EdgeInsets.zero,
        backgroundColor: color,
        borderColor: const Color(0xFFE5E7EB),
        radius: 6,
        child: SizedBox(
          width: 82,
          height: 34,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.storeTaxId,
    required this.header,
    required this.footer,
    required this.receiptNumber,
    required this.date,
    required this.time,
    required this.cashier,
    required this.paymentMethod,
    required this.settings,
    required this.items,
    required this.subtotal,
    this.customerName,
    this.discountAmount,
    this.discountLabel,
    required this.grandTotal,
    required this.cashReceived,
    required this.changeAmount,
    required this.money,
  });

  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeTaxId;
  final String header;
  final String footer;
  final String receiptNumber;
  final String date;
  final String time;
  final String cashier;
  final String paymentMethod;
  final ReceiptSettings settings;
  final List<OrderLine> items;
  final double subtotal;
  final String? customerName;
  final double? discountAmount;
  final String? discountLabel;
  final double grandTotal;
  final double cashReceived;
  final double changeAmount;
  final String Function(double value) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header.trim().isNotEmpty) ...[
            Text(
              header,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (storeAddress.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        storeAddress,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (storePhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        storePhone,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (settings.showTaxId && storeTaxId.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'TIN: $storeTaxId',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'RECEIPT',
                    style: TextStyle(
                      color: Color(0xFFF4B8B8),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (settings.showOrderNumber)
                    Text(
                      '#$receiptNumber',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1.5,
            color: AppColors.ink,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 4,
            children: [
              if (settings.showDateTime)
                _MetaLine(label: 'Date', value: '$date · $time'),
              if (settings.showPaymentMethod)
                _MetaLine(label: 'Payment', value: paymentMethod),
              if (settings.showCashier)
                _MetaLine(label: 'Cashier', value: cashier),
              if (settings.showCustomer &&
                  customerName != null &&
                  customerName!.trim().isNotEmpty)
                _MetaLine(label: 'Customer', value: customerName!),
              if (settings.showItemCount)
                _MetaLine(
                  label: 'Items',
                  value:
                      '${items.fold<int>(0, (sum, line) => sum + line.quantity)}',
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _TableHeader(
            cells: ['ITEM', 'QTY', 'PRICE', 'TOTAL'],
            alignments: [
              TextAlign.left,
              TextAlign.center,
              TextAlign.right,
              TextAlign.right,
            ],
            flexes: [6, 2, 3, 4],
          ),
          ...items.map(
            (line) => _TableRow(
              cells: [
                line.itemName,
                '${line.quantity}',
                money(line.unitPriceValue),
                money(line.lineTotal),
              ],
              alignments: const [
                TextAlign.left,
                TextAlign.center,
                TextAlign.right,
                TextAlign.right,
              ],
              flexes: const [6, 2, 3, 4],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _SummaryLine(label: 'Subtotal', value: money(subtotal)),
          if (settings.showDiscount &&
              discountAmount != null &&
              discountAmount! > 0)
            _SummaryLine(
              label: discountLabel ?? 'Discount',
              value: '- ${money(discountAmount!)}',
              valueColor: AppColors.textBody,
            ),
          const SizedBox(height: 8),
          _SummaryLine(
            label: 'Total Amount',
            value: money(grandTotal),
            isBold: true,
            fontSize: 16,
            labelColor: const Color(0xFF111111),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9), indent: 40),
          ),
          _SummaryLine(
            label: 'Cash Tendered',
            value: money(cashReceived),
            fontSize: 13,
          ),
          _SummaryLine(
            label: 'Change Due',
            value: money(changeAmount),
            valueColor: const Color(0xFF111111),
            isBold: true,
            fontSize: 14,
          ),
          const SizedBox(height: 32),
          Text(
            footer,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.cells,
    required this.alignments,
    required this.flexes,
  });

  final List<String> cells;
  final List<TextAlign> alignments;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(cells.length, (index) {
          return Expanded(
            flex: flexes[index],
            child: Text(
              cells[index],
              textAlign: alignments[index],
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.cells,
    required this.alignments,
    required this.flexes,
  });

  final List<String> cells;
  final List<TextAlign> alignments;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: List.generate(cells.length, (index) {
          return Expanded(
            flex: flexes[index],
            child: Text(
              cells[index],
              textAlign: alignments[index],
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: index == cells.length - 1
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
    this.labelColor,
    this.fontSize,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  final Color? labelColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? const Color(0xFF64748B),
                  fontSize: fontSize ?? 13,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF111111),
                fontSize: fontSize ?? 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
