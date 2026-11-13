import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../models/report_models.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.maxValue,
    this.label = 'Revenue',
    this.color = AppColors.primary,
  });

  final List<TrendPoint> points;
  final double maxValue;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _emptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _TrendLabels(points: points),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Text(
        'No data for this period',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
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

    final effectiveMax = maxValue > 0 ? maxValue : 1.0;
    final stepX = size.width / (points.length - 1).clamp(1, double.infinity);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y =
          size.height - (points[i].value / effectiveMax * size.height * 0.85);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y =
          size.height - (points[i].value / effectiveMax * size.height * 0.85);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }

    final gradientPath = Path.from(path);
    gradientPath.lineTo(size.width, size.height);
    gradientPath.lineTo(0, size.height);
    gradientPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.0),
      ],
    );
    canvas.drawPath(
      gradientPath,
      Paint()
        ..shader =
            gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: points.map((point) {
        return SizedBox(
          width: 50,
          child: Text(
            point.label,
            textAlign: TextAlign.center,
            style: AppTypography.helperText.copyWith(
              fontSize: 9,
              color: AppColors.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}
