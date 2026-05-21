import 'package:flutter/material.dart';

import '../../service/pos_order_models.dart';
import '../widgets/app_design.dart';
import 'receipt_preview_page.dart';

class ReceiptSuccessPage extends StatelessWidget {
  const ReceiptSuccessPage({
    super.key,
    required this.order,
  });

  final CompletedOrder order;

  int get _itemCount =>
      order.lines.fold<int>(0, (sum, line) => sum + line.quantity);

  String _amount(double value) {
    final whole = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  void _openReceipt(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReceiptPreviewPage(order: order),
      ),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(height: 8, color: const Color(0xFF355BD8)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF67BE68),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 42,
                        color: Color(0xFF67BE68),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'TSH${_amount(order.total)}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(flex: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'RECEIPT ID: ${order.id}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'ITEM COUNT: $_itemCount',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      label: 'GET RECEIPT',
                      color: const Color(0xFF67BE68),
                      onTap: () => _openReceipt(context),
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      label: 'NEW SALE',
                      color: const Color(0xFF476ADB),
                      onTap: () => _startNewSale(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: color,
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
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
