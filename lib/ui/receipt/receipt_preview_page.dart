import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../receipt_brand_data.dart';
import '../../service/pos_order_models.dart';
import '../models/product_item.dart';
import '../widgets/app_design.dart';
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
  static const MethodChannel _shareChannel = MethodChannel('possystem/share');

  File? _preparedPdf;
  bool _isPreparing = false;

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
  double get _tax => 0;
  int get _itemTypeCount => widget.order.lines.length;
  int get _unitCount =>
      widget.order.lines.fold<int>(0, (sum, line) => sum + line.quantity);

  @override
  void initState() {
    super.initState();
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

  Future<void> _preparePdf() async {
    if (_isPreparing) return;
    setState(() => _isPreparing = true);

    try {
      final pdfFile = await ReceiptPdfService.createReceiptPdf(
        items: _pdfItems,
        total: widget.order.total,
        cashTendered: widget.order.cashTendered,
        changeDue: widget.order.changeDue,
        receiptNumber: widget.order.id,
        cashier: widget.order.cashierName,
        register: widget.order.register,
        date: widget.order.date,
        time: widget.order.time,
      );
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

  Future<File?> _ensurePdf(BuildContext context) async {
    File? pdfFile = _preparedPdf;
    if (pdfFile != null) return pdfFile;

    if (_isPreparing) {
      showMarketNotice(
        context,
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
      pdfFile = await ReceiptPdfService.createReceiptPdf(
        items: _pdfItems,
        total: widget.order.total,
        cashTendered: widget.order.cashTendered,
        changeDue: widget.order.changeDue,
        receiptNumber: widget.order.id,
        cashier: widget.order.cashierName,
        register: widget.order.register,
        date: widget.order.date,
        time: widget.order.time,
      );
      if (!mounted) return null;
      setState(() => _preparedPdf = pdfFile);
      return pdfFile;
    } catch (_) {
      if (!context.mounted) return null;
      showMarketNotice(
        context,
        title: 'Receipt Error',
        message: 'Receipt PDF could not be prepared',
        type: MarketNoticeType.warning,
      );
      return null;
    }
  }

  String _buildWhatsAppMessage() {
    final buffer = StringBuffer()
      ..writeln(ReceiptBrandData.storeName)
      ..writeln('Receipt ${widget.order.id}')
      ..writeln('Date: ${widget.order.date} ${widget.order.time}')
      ..writeln('');
    for (final line in widget.order.lines) {
      buffer.writeln(
        '${line.itemName} x${line.quantity} - ${_money(line.lineTotal)}',
      );
    }
    buffer
      ..writeln('')
      ..writeln('Total: ${_money(widget.order.total)}')
      ..writeln('Cash Received: ${_money(widget.order.cashTendered)}')
      ..writeln('Change Amount: ${_money(widget.order.changeDue)}');
    return buffer.toString();
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    try {
      final pdfFile = await _ensurePdf(context);
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
        if (!context.mounted) return;
        showMarketNotice(
          context,
          title: 'WhatsApp Ready',
          message: 'Receipt PDF opened in WhatsApp',
        );
        return;
      }

      final webUri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}',
      );
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        showMarketNotice(
          context,
          title: 'WhatsApp Opened',
          message: 'WhatsApp opened with receipt details',
        );
        return;
      }

      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: 'Share Unavailable',
        message: 'WhatsApp could not be opened on this device',
        type: MarketNoticeType.warning,
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: 'Share Failed',
        message: error.message ?? 'Receipt could not be shared',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    final pdfFile = await _ensurePdf(context);
    if (pdfFile == null) return;
    final pdfBytes = await pdfFile.readAsBytes();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'receipt_${widget.order.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.pdf',
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    final pdfFile = await _ensurePdf(context);
    if (pdfFile == null) return;
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    final pdfFile = await _ensurePdf(context);
    if (pdfFile == null || !context.mounted) return;

    try {
      final targetFile = await _saveReceiptPdf(pdfFile, widget.order.id);
      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: 'Receipt Downloaded',
        message: 'Saved to ${targetFile.path}',
      );
    } catch (_) {
      if (!context.mounted) return;
      showMarketNotice(
        context,
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

  void _startNewSale(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(18, 0, 18, 20),
        backgroundColor: Color(0xFF1E7A47),
        content: Text('Ready for a new sale'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF4C68D6)),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _sharePdf(context),
                    icon: const Icon(Icons.share, color: Color(0xFF4C68D6)),
                  ),
                  IconButton(
                    onPressed: () => _showPlaceholderAction(context, 'SMS'),
                    icon: const Icon(Icons.sms, color: Color(0xFF4C68D6)),
                  ),
                  IconButton(
                    onPressed: () => _shareToWhatsApp(context),
                    icon: const Icon(Icons.chat, color: Color(0xFF4C68D6)),
                  ),
                  IconButton(
                    onPressed: () => _downloadReceipt(context),
                    icon: const Icon(Icons.download, color: Color(0xFF4C68D6)),
                  ),
                  IconButton(
                    onPressed: () => _printReceipt(context),
                    icon: const Icon(Icons.print, color: Color(0xFF4C68D6)),
                  ),
                  IconButton(
                    onPressed: () => _showPlaceholderAction(context, 'More'),
                    icon: const Icon(Icons.more_vert, color: Color(0xFF4C68D6)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFD7D7D7)),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TopActionButton(
                    label: 'RETURN',
                    color: const Color(0xFF476ADB),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  _TopActionButton(
                    label: 'DELETE',
                    color: const Color(0xFFF24840),
                    onTap: () => _showPlaceholderAction(context, 'Delete'),
                  ),
                  const SizedBox(width: 6),
                  _TopActionButton(
                    label: 'EDIT',
                    color: const Color(0xFF476ADB),
                    onTap: () => _showPlaceholderAction(context, 'Edit'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 94),
                child: _ReceiptPaper(
                  phone: ReceiptBrandData.phone,
                  receiptNumber: widget.order.id,
                  date: widget.order.date,
                  time: widget.order.time,
                  paymentMethod: widget.order.paymentMethod,
                  itemTypes: _itemTypeCount,
                  unitCount: _unitCount,
                  amount: widget.order.total,
                  items: widget.order.lines,
                  subtotal: _subtotal,
                  tax: _tax,
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
                onTap: () => _startNewSale(context),
                child: Container(
                  width: double.infinity,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF67BE68),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
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
      child: Container(
        width: 82,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xFFCFD3DE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({
    required this.phone,
    required this.receiptNumber,
    required this.date,
    required this.time,
    required this.paymentMethod,
    required this.itemTypes,
    required this.unitCount,
    required this.amount,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.cashReceived,
    required this.changeAmount,
    required this.money,
  });

  final String phone;
  final String receiptNumber;
  final String date;
  final String time;
  final String paymentMethod;
  final int itemTypes;
  final int unitCount;
  final double amount;
  final List<OrderLine> items;
  final double subtotal;
  final double tax;
  final double grandTotal;
  final double cashReceived;
  final double changeAmount;
  final String Function(double value) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      child: Column(
        children: [
          Text(
            phone,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 100),
            child: Divider(height: 1, color: Color(0xFFD7D7D7)),
          ),
          Text(
            'Receipt# $receiptNumber',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Date : $date - $time',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          const _TableHeader(
            cells: ['P Mode', 'I#', 'U#', 'Amount'],
            alignments: [
              TextAlign.left,
              TextAlign.center,
              TextAlign.center,
              TextAlign.right,
            ],
            flexes: [4, 2, 2, 4],
          ),
          _TableRow(
            cells: [paymentMethod, '$itemTypes', '$unitCount', money(amount)],
            alignments: const [
              TextAlign.left,
              TextAlign.center,
              TextAlign.center,
              TextAlign.right,
            ],
            flexes: const [4, 2, 2, 4],
            isBold: true,
          ),
          const SizedBox(height: 18),
          const _TableHeader(
            cells: ['Name', 'Price', 'Qty', 'Total'],
            alignments: [
              TextAlign.left,
              TextAlign.left,
              TextAlign.center,
              TextAlign.right,
            ],
            flexes: [4, 3, 2, 4],
          ),
          ...items.map(
            (line) => _TableRow(
              cells: [
                line.itemName,
                money(line.unitPriceValue),
                '${line.quantity}',
                money(line.lineTotal),
              ],
              alignments: const [
                TextAlign.left,
                TextAlign.left,
                TextAlign.center,
                TextAlign.right,
              ],
              flexes: const [4, 3, 2, 4],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 2, color: Color(0xFF444444)),
          ),
          _SummaryLine(label: 'Subtotal', value: money(subtotal)),
          const SizedBox(height: 4),
          _SummaryLine(label: 'Tax (0%)', value: money(tax)),
          const SizedBox(height: 4),
          _SummaryLine(
            label: 'Grand Total',
            value: money(grandTotal),
            isBold: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFD7D7D7)),
          ),
          _SummaryLine(
            label: 'Cash Received',
            value: money(cashReceived),
            valueWidth: 160,
          ),
          const SizedBox(height: 4),
          _SummaryLine(
            label: 'Change Amount',
            value: money(changeAmount),
            valueWidth: 160,
          ),
          const SizedBox(height: 26),
          const Text(
            'Thank You! Visit again!',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Powered By Zobaze',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
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
      color: const Color(0xFFF0F0F0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: List.generate(cells.length, (index) {
          return Expanded(
            flex: flexes[index],
            child: Text(
              cells[index],
              textAlign: alignments[index],
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
    this.isBold = false,
  });

  final List<String> cells;
  final List<TextAlign> alignments;
  final List<int> flexes;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
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
    this.valueWidth = 140,
  });

  final String label;
  final String value;
  final bool isBold;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(
          width: valueWidth,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
