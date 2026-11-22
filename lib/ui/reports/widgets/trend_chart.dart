import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/common/market_empty_state.dart';
import '../models/report_models.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.maxValue,
    this.label = 'Revenue',
    this.color,
  });

  final List<TrendPoint> points;
  final double maxValue;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _emptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(label),
          style: AppTypography.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: CustomPaint(
            size: Size.infinite,
            painter: _TrendPainter(
              points: points,
              maxValue: maxValue,
              color: color ?? AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _TrendLabels(points: points),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return MarketEmptyState(
      showCard: false,
      icon: Icons.show_chart_rounded,
      title: context.tr('No data for this period'),
      message: context.tr(
        'Record sales or transactions in this period to see trend charts.',
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.maxValue,
    required this.color,
  });

  final List<TrendPoint> points;
  final double maxValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minimum = points
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a < b ? a : b);
    final maximum = points
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final extent = maximum - minimum;
    final scale = extent > 0 ? extent : 1.0;
    double yFor(double value) => extent == 0
        ? size.height * 0.92
        : size.height * 0.08 + (maximum - value) / scale * size.height * 0.84;
    double xFor(int index) => points.length == 1
        ? size.width / 2
        : index * size.width / (points.length - 1);
    final baseline = yFor(0);
    canvas.drawLine(
        Offset(0, baseline),
        Offset(size.width, baseline),
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 1);
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = Offset(xFor(index), yFor(points[index].value));
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    if (points.length > 1) {
      final area = Path.from(path)
        ..lineTo(size.width, baseline)
        ..lineTo(0, baseline)
        ..close();
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.06));
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
    for (var index = 0; index < points.length; index++) {
      final point = Offset(xFor(index), yFor(points[index].value));
      canvas.drawCircle(point, 4, Paint()..color = color);
      canvas.drawCircle(point, 2, Paint()..color = AppColors.surface);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _TrendPainter &&
        (oldDelegate.points != points ||
            oldDelegate.maxValue != maxValue ||
            oldDelegate.color != color);
  }
}

class _TrendLabels extends StatelessWidget {
  const _TrendLabels({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final limit = (constraints.maxWidth / 80).floor().clamp(2, 8);
        final count = points.length.clamp(1, limit);
        final labels = [
          for (var index = 0; index < count; index++)
            points[count == 1
                ? 0
                : (index * (points.length - 1) / (count - 1)).round()]
        ];
        return Row(children: [
          for (final point in labels)
            Expanded(
                child: Tooltip(
              message: '${point.label}: ${point.displayValue}',
              child: Text(point.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.helperText
                      .copyWith(fontSize: 10, color: AppColors.textMuted)),
            ))
        ]);
      });
}
