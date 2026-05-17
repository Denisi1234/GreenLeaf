import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../receipt_brand_data.dart';
import '../../service/pos_order_models.dart';
import '../models/product_item.dart';
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

  @override
  void initState() {
    super.initState();
    _preparePdf();
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

  String _buildWhatsAppMessage() {
    final buffer = StringBuffer()
      ..writeln(ReceiptBrandData.storeName)
      ..writeln('Receipt ${widget.order.id}')
      ..writeln('Date: ${widget.order.date}')
      ..writeln('Cashier: ${widget.order.cashierName}')
      ..writeln('');
    for (final line in widget.order.lines) {
      buffer.writeln(
        '${line.itemName} x${line.quantity} - TSH ${line.lineTotal.toStringAsFixed(0)}',
      );
    }
    buffer
      ..writeln('')
      ..writeln('Total: TSH ${widget.order.total.toStringAsFixed(0)}')
      ..writeln(
        'Cash Tendered: TSH ${widget.order.cashTendered.toStringAsFixed(0)}',
      )
      ..writeln('Change Due: TSH ${widget.order.changeDue.toStringAsFixed(0)}')
      ..writeln('')
      ..writeln('Thank you for shopping with us.');
    return buffer.toString();
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    try {
      File? pdfFile = _preparedPdf;

      if (pdfFile == null) {
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

        if (pdfFile == null) {
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
        }
      }

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
          title: 'PDF Shared',
          message: 'Receipt PDF opened in WhatsApp',
        );
        return;
      }

      try {
        final pdfBytes = await pdfFile.readAsBytes();
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename:
              'receipt_${widget.order.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.pdf',
        );
      } catch (error) {
        debugPrint('System PDF share failed: $error');
      }

      final webUri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}',
      );
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        showMarketNotice(
          context,
          title: 'WhatsApp Opened',
          message: 'WhatsApp opened with the receipt summary',
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
        message: error.message ?? 'Receipt PDF could not be shared',
        type: MarketNoticeType.warning,
      );
    } catch (_) {
      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: 'Unexpected Error',
        message: 'An error occurred while preparing the receipt',
        type: MarketNoticeType.warning,
      );
    }
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
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Row(
                    children: [
                      const SizedBox(width: 44),
                      const Expanded(
                        child: Text(
                          'Receipt Preview',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF202938),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE3E6EB)),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF202938),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 112),
                    child: _ReceiptPaper(
                      items: widget.order.lines,
                      total: widget.order.total,
                      cashTendered: widget.order.cashTendered,
                      changeDue: widget.order.changeDue,
                      receiptNumber: widget.order.id,
                      cashier: widget.order.cashierName,
                      register: widget.order.register,
                      date: widget.order.date,
                      time: widget.order.time,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Row(
                children: [
                  Expanded(
                    child: _ReceiptActionButton(
                      label: 'New Sale',
                      icon: Icons.add_shopping_cart_rounded,
                      isPrimary: true,
                      onTap: () => _startNewSale(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReceiptActionButton(
                      label: 'WhatsApp Receipt',
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => _shareToWhatsApp(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({
    required this.items,
    required this.total,
    required this.cashTendered,
    required this.changeDue,
    required this.receiptNumber,
    required this.cashier,
    required this.register,
    required this.date,
    required this.time,
  });

  final List<OrderLine> items;
  final double total;
  final double cashTendered;
  final double changeDue;
  final String receiptNumber;
  final String cashier;
  final String register;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF7F1),
                  borderRadius: BorderRadius.circular(31),
                ),
                child: const Center(child: ReceiptBrandMark()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReceiptBrandData.storeName,
                      style: const TextStyle(
                        color: Color(0xFF202938),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ReceiptBrandData.address,
                      style: const TextStyle(
                        color: Color(0xFF636B78),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ReceiptBrandData.phone,
                      style: const TextStyle(
                        color: Color(0xFF636B78),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          _ReceiptMetaRow(label: 'Receipt #:', value: receiptNumber),
          _ReceiptMetaRow(label: 'Date:', value: date),
          _ReceiptMetaRow(label: 'Time:', value: time),
          _ReceiptMetaRow(label: 'Cashier:', value: cashier),
          _ReceiptMetaRow(label: 'Register:', value: register),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text(
                    'Item',
                    style: TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Price',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Subtotal',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          if (items.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF7C8593),
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No items were passed to this receipt yet.',
                      style: TextStyle(
                        color: Color(0xFF5F6775),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map(
              (line) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: line.imagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(line.imagePath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              FittedBox(
                                            fit: BoxFit.contain,
                                            child: ProductArt(
                                              type: line.artType,
                                            ),
                                          ),
                                        ),
                                      )
                                    : FittedBox(
                                        fit: BoxFit.contain,
                                        child: ProductArt(type: line.artType),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.itemName,
                                      style: const TextStyle(
                                        color: Color(0xFF202938),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      line.itemSize,
                                      style: const TextStyle(
                                        color: Color(0xFF6E7684),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${line.quantity}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF202938),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'TSH ${line.unitPriceValue.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF202938),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'TSH ${line.lineTotal.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF202938),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EBEF)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _ReceiptAmountRow(label: 'Subtotal', value: total),
          const SizedBox(height: 6),
          _ReceiptAmountRow(label: 'Cash Tendered', value: cashTendered),
          const SizedBox(height: 6),
          _ReceiptAmountRow(label: 'Change Due', value: changeDue),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFD9DEE5)),
          ),
          _ReceiptAmountRow(
            label: 'Total',
            value: total,
            isLarge: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDECDD)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF2A7A46),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          color: Color(0xFF2A7A46),
                          fontSize: 11.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cash',
                        style: TextStyle(
                          color: Color(0xFF202938),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'TSH ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF202938),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF2A7A46),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thank you for your purchase!',
                    style: TextStyle(
                      color: Color(0xFF2A7A46),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'We appreciate your business.',
                    style: TextStyle(
                      color: Color(0xFF697180),
                      fontSize: 11.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptMetaRow extends StatelessWidget {
  const _ReceiptMetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF202938),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF202938),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptAmountRow extends StatelessWidget {
  const _ReceiptAmountRow({
    required this.label,
    required this.value,
    this.isLarge = false,
  });

  final String label;
  final double value;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF202938),
              fontSize: isLarge ? 14.8 : 12.8,
              fontWeight: isLarge ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          'TSH ${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: const Color(0xFF202938),
            fontSize: isLarge ? 14.8 : 12.8,
            fontWeight: isLarge ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReceiptActionButton extends StatelessWidget {
  const _ReceiptActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1E7A47) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E7A47)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : const Color(0xFF1E7A47),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF1E7A47),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiptBrandMark extends StatelessWidget {
  const ReceiptBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFF2A7A46),
          size: 30,
        ),
        Positioned(
          bottom: 10,
          child: Container(
            width: 17,
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2A7A46), width: 1.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
          ),
        ),
      ],
    );
  }
}
