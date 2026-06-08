import 'package:flutter/material.dart';

import '../../service/pos_order_models.dart';
import '../shell/app_shell.dart';
import '../widgets/market_bottom_nav.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'receipt_preview_page.dart';

class ReceiptSuccessPage extends StatefulWidget {
  const ReceiptSuccessPage({
    super.key,
    required this.order,
  });

  final CompletedOrder order;

  @override
  State<ReceiptSuccessPage> createState() => _ReceiptSuccessPageState();
}

class _ReceiptSuccessPageState extends State<ReceiptSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _checkProgress;

  CompletedOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(curve);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _checkProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => const AppShell(
          initialTab: MarketTab.reports,
        ),
      ),
      (route) => false,
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
                    FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: SizedBox(
                          width: 74,
                          height: 74,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF67BE68),
                                    width: 3,
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _checkProgress,
                                builder: (context, child) {
                                  final bounce = 1 +
                                      (0.08 *
                                          (1 - (_checkProgress.value - 1).abs())
                                              .clamp(0.0, 1.0));
                                  return Transform.scale(
                                    scale: bounce,
                                    child: CustomPaint(
                                      size: const Size(54, 54),
                                      painter: _CheckMarkPainter(
                                        progress: _checkProgress.value,
                                        color: const Color(0xFF67BE68),
                                        strokeWidth: 5,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (order.discountAmount != null &&
                        order.discountAmount! > 0) ...[
                      Text(
                        'Total: TSH${_amount(order.total + order.discountAmount!)}',
                        style: const TextStyle(
                          color: Color(0xFF7A859C),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Discount: -TSH${_amount(order.discountAmount!)}',
                        style: const TextStyle(
                          color: Color(0xFFE66C73),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RECEIPT',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.id,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'ITEMS',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_itemCount',
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    MarketButton(
                      label: 'VIEW RECEIPT',
                      color: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      borderColor: Colors.transparent,
                      height: 48,
                      radius: 8,
                      paddingHorizontal: 0,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      onTap: () => _openReceipt(context),
                    ),
                    const SizedBox(height: 12),
                    MarketButton(
                      label: 'NEW SALE',
                      color: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      borderColor: Colors.transparent,
                      height: 48,
                      radius: 8,
                      paddingHorizontal: 0,
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

class _CheckMarkPainter extends CustomPainter {
  _CheckMarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.26, size.height * 0.53);
    final p2 = Offset(size.width * 0.43, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.34);

    final firstSegmentLength = (p2 - p1).distance;
    final secondSegmentLength = (p3 - p2).distance;
    final totalLength = firstSegmentLength + secondSegmentLength;
    final drawLength = totalLength * progress.clamp(0.0, 1.0);

    final path = Path()..moveTo(p1.dx, p1.dy);
    if (drawLength <= firstSegmentLength) {
      final t = drawLength / firstSegmentLength;
      path.lineTo(
        Offset.lerp(p1, p2, t)!.dx,
        Offset.lerp(p1, p2, t)!.dy,
      );
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (drawLength - firstSegmentLength) / secondSegmentLength;
      path.lineTo(
        Offset.lerp(p2, p3, t.clamp(0.0, 1.0))!.dx,
        Offset.lerp(p2, p3, t.clamp(0.0, 1.0))!.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
