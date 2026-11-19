import '../widgets/app_design.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OnboardingThemeArt {
  salesTracker,
  stockManager,
  reportsInsights,
}

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.art,
    this.size = 280,
  });

  final OnboardingThemeArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OnboardingArtPainter(art: art),
        size: Size(size, size),
      ),
    );
  }
}

class _OnboardingArtPainter extends CustomPainter {
  _OnboardingArtPainter({required this.art});

  final OnboardingThemeArt art;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft ground shadow / base platform
    final shadowPaint = Paint()
      ..color = const Color(0xFFF0FDF4).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.88),
        width: w * 0.82,
        height: h * 0.16,
      ),
      shadowPaint,
    );

    final softGlowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.46), w * 0.42, softGlowPaint);

    switch (art) {
      case OnboardingThemeArt.salesTracker:
        _drawSalesTracker(canvas, w, h);
        break;
      case OnboardingThemeArt.stockManager:
        _drawStockManager(canvas, w, h);
        break;
      case OnboardingThemeArt.reportsInsights:
        _drawReportsInsights(canvas, w, h);
        break;
    }
  }

  void _drawSalesTracker(Canvas canvas, double w, double h) {
    // 1. Digital dashboard card / screen in background
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.52, h * 0.44),
          width: w * 0.68,
          height: h * 0.52),
      const Radius.circular(18),
    );
    final cardPaint = Paint()..color = const Color(0xFFF1F5F9);
    final cardStroke = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(cardRect, cardPaint);
    canvas.drawRRect(cardRect, cardStroke);

    // Screen content lines & graph
    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    canvas.drawLine(
        Offset(w * 0.26, h * 0.28), Offset(w * 0.46, h * 0.28), linePaint);
    canvas.drawLine(
        Offset(w * 0.26, h * 0.33), Offset(w * 0.40, h * 0.33), linePaint);

    // Sales bar charts inside screen
    final chartColors = [
      AppColors.primaryLight,
      AppColors.primaryBright,
      AppColors.primary,
      AppColors.primaryDeep,
    ];
    final barWidth = w * 0.055;
    final heights = [h * 0.14, h * 0.20, h * 0.16, h * 0.24];
    for (int i = 0; i < 4; i++) {
      final barX = w * 0.26 + (i * (barWidth + w * 0.03));
      final barH = heights[i];
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, h * 0.62 - barH, barWidth, barH),
        const Radius.circular(6),
      );
      final p = Paint()..color = chartColors[i];
      canvas.drawRRect(r, p);
    }

    // Mini floating badge / POS tag
    final tagRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.60, h * 0.24, w * 0.22, h * 0.10),
      const Radius.circular(10),
    );
    final tagPaint = Paint()..color = const Color(0xFF111111);
    canvas.drawRRect(tagRRect, tagPaint);

    final tagLine = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    canvas.drawLine(
        Offset(w * 0.64, h * 0.29), Offset(w * 0.76, h * 0.29), tagLine);

    // 2. Character 1 (Store Clerk / Sales Guy standing on left)
    _drawHumanClerk(canvas, w * 0.36, h * 0.48, scale: 0.95);

    // 3. Character 2 (Customer / Partner standing on right)
    _drawHumanCustomer(canvas, w * 0.72, h * 0.50, scale: 0.92);
  }

  void _drawStockManager(Canvas canvas, double w, double h) {
    // Inventory boxes / shelves
    final boxPaint1 = Paint()..color = AppColors.primarySoft;
    final boxPaint2 = Paint()..color = AppColors.primaryDeep;
    final boxPaint3 = Paint()..color = AppColors.primary;
    final linePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2.0;

    // Large storage crates
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.48, w * 0.26, h * 0.24),
          const Radius.circular(10)),
      boxPaint1,
    );
    canvas.drawLine(
        Offset(w * 0.18, h * 0.60), Offset(w * 0.44, h * 0.60), linePaint);
    canvas.drawLine(
        Offset(w * 0.31, h * 0.48), Offset(w * 0.31, h * 0.72), linePaint);

    // Green featured stock crate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.24, h * 0.28, w * 0.20, h * 0.18),
          const Radius.circular(8)),
      boxPaint2,
    );

    // Small floating checkmark box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.62, h * 0.26, w * 0.20, h * 0.18),
          const Radius.circular(10)),
      boxPaint3,
    );
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final checkPath = Path()
      ..moveTo(w * 0.67, h * 0.35)
      ..lineTo(w * 0.71, h * 0.39)
      ..lineTo(w * 0.78, h * 0.31);
    canvas.drawPath(checkPath, checkPaint);

    // Person managing inventory with clipboard/tablet
    _drawHumanClerk(canvas, w * 0.54, h * 0.46, scale: 1.0);
  }

  void _drawReportsInsights(Canvas canvas, double w, double h) {
    // Large curved analytics trend card
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.42),
          width: w * 0.72,
          height: h * 0.50),
      const Radius.circular(20),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Trend line with gradient dots
    final trendPath = Path()
      ..moveTo(w * 0.22, h * 0.50)
      ..cubicTo(w * 0.32, h * 0.52, w * 0.38, h * 0.38, w * 0.48, h * 0.40)
      ..cubicTo(w * 0.58, h * 0.42, w * 0.64, h * 0.28, w * 0.78, h * 0.26);

    final trendPaint = Paint()
      ..color = AppColors.primaryDeep
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(trendPath, trendPaint);

    // Trend fill under the curve
    final fillPath = Path.from(trendPath)
      ..lineTo(w * 0.78, h * 0.58)
      ..lineTo(w * 0.22, h * 0.58)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // Data points
    final dotPaint = Paint()..color = AppColors.primaryDeep;
    final dotWhite = Paint()..color = Colors.white;
    for (final point in [
      Offset(w * 0.22, h * 0.50),
      Offset(w * 0.48, h * 0.40),
      Offset(w * 0.78, h * 0.26),
    ]) {
      canvas.drawCircle(point, 6, dotPaint);
      canvas.drawCircle(point, 3, dotWhite);
    }

    // Characters analyzing reports
    _drawHumanCustomer(canvas, w * 0.34, h * 0.50, scale: 0.94);
    _drawHumanClerk(canvas, w * 0.68, h * 0.48, scale: 0.96);
  }

  void _drawHumanClerk(Canvas canvas, double cx, double cy,
      {double scale = 1.0}) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    final skinPaint = Paint()..color = const Color(0xFFC9D9E2);
    final hairPaint = Paint()..color = AppColors.ink;
    final shirtPaint = Paint()..color = AppColors.primaryDeep;
    final pantsPaint = Paint()..color = AppColors.ink;
    final backpackPaint = Paint()..color = AppColors.primary;
    final shoesPaint = Paint()..color = AppColors.ink; // Shoes

    // Backpack
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-36, -34, 18, 54), const Radius.circular(8)),
      backpackPaint,
    );

    // Legs / Pants
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-16, 26, 12, 60), const Radius.circular(5)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(3, 26, 12, 60), const Radius.circular(5)),
      pantsPaint,
    );

    // Shoes
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-19, 82, 17, 9), const Radius.circular(4)),
      shoesPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(3, 82, 17, 9), const Radius.circular(4)),
      shoesPaint,
    );

    // Torso / Shirt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-20, -30, 38, 58), const Radius.circular(10)),
      shirtPaint,
    );

    // Head
    canvas.drawCircle(const Offset(-1, -44), 14, skinPaint);
    // Hair
    final hairPath = Path()
      ..addArc(Rect.fromCircle(center: const Offset(-1, -47), radius: 14),
          math.pi, math.pi)
      ..lineTo(13, -44)
      ..lineTo(-14, -44)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Arm holding clipboard or pointing
    final armPaint = Paint()
      ..color = AppColors.primaryDeep
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(16, -18), const Offset(28, 6), armPaint);
    canvas.drawCircle(const Offset(29, 9), 5, skinPaint);

    canvas.restore();
  }

  void _drawHumanCustomer(Canvas canvas, double cx, double cy,
      {double scale = 1.0}) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    final skinPaint = Paint()..color = const Color(0xFFD8E5EC);
    final hairPaint = Paint()..color = AppColors.ink;
    final shirtPaint = Paint()..color = AppColors.primary;
    final skirtPaint = Paint()..color = AppColors.primaryDeep;
    final shoesPaint = Paint()..color = AppColors.ink;

    // Legs
    final legPaint = Paint()
      ..color = const Color(0xFFD8E5EC)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-8, 38), const Offset(-8, 80), legPaint);
    canvas.drawLine(const Offset(8, 38), const Offset(8, 80), legPaint);

    // Shoes
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-8, 83), width: 15, height: 7),
      shoesPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(8, 83), width: 15, height: 7),
      shoesPaint,
    );

    // Skirt
    final skirtPath = Path()
      ..moveTo(-12, 10)
      ..lineTo(12, 10)
      ..lineTo(19, 42)
      ..lineTo(-19, 42)
      ..close();
    canvas.drawPath(skirtPath, skirtPaint);

    // Torso / Top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-13, -26, 26, 38), const Radius.circular(8)),
      shirtPaint,
    );

    // Head
    canvas.drawCircle(const Offset(0, -38), 13, skinPaint);

    // Ponytail hair
    canvas.drawCircle(const Offset(-4, -42), 12, hairPaint);
    final ponyPath = Path()
      ..moveTo(4, -40)
      ..quadraticBezierTo(20, -34, 16, -18)
      ..quadraticBezierTo(10, -22, 6, -30)
      ..close();
    canvas.drawPath(ponyPath, hairPaint);

    // Arm interacting with screen
    final armPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-12, -18), const Offset(-26, -2), armPaint);
    canvas.drawCircle(const Offset(-28, -1), 4, skinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OnboardingArtPainter oldDelegate) =>
      oldDelegate.art != art;
}
