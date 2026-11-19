import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/product_item.dart';
import '../app_design.dart';
import '../app_image.dart';

class AnimatedCartToken extends StatelessWidget {
  const AnimatedCartToken({
    super.key,
    required this.type,
    this.imagePath,
    this.compact = false,
  });

  final ProductArtType type;
  final String? imagePath;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return Container(
      width: compact ? 32 : 48,
      height: compact ? 32 : 48,
      padding: hasImage ? EdgeInsets.zero : EdgeInsets.all(compact ? 4 : 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              child: Image(
                image: appImageProvider(context, imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => FittedBox(
                  fit: BoxFit.contain,
                  child: ProductArt(type: type),
                ),
              ),
            )
          : FittedBox(
              fit: BoxFit.contain,
              child: ProductArt(type: type),
            ),
    );
  }
}

class ProductArt extends StatelessWidget {
  const ProductArt({super.key, required this.type});

  final ProductArtType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ProductArtType.aquafina:
        return const _BottleArt();
      case ProductArtType.coke:
        return const _CanArt();
      case ProductArtType.lays:
        return const _ChipsBagArt();
      case ProductArtType.galaxy:
        return const _ChocolateArt();
      case ProductArtType.kelloggs:
        return const _CerealBoxArt();
      case ProductArtType.dove:
        return const _SoapBoxArt();
      case ProductArtType.colgate:
        return const _ToothpasteArt();
      case ProductArtType.dettol:
        return const _PumpBottleArt();
      case ProductArtType.tide:
        return const _DetergentBagArt();
    }
  }
}

class _BottleArt extends StatelessWidget {
  const _BottleArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 122,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 20,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.sharp),
              ),
            ),
          ),
          Positioned(
            top: 10,
            child: Container(
              width: 44,
              height: 104,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF9FCFF), Color(0xFFF3F4F6)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.rounded),
                border: Border.all(color: AppColors.primarySoft),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _BottleRibsPainter()),
                  ),
                  Center(
                    child: Container(
                      width: 34,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeep,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'Aqua',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanArt extends StatelessWidget {
  const _CanArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 112,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primaryBright,
            AppColors.primary
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.standard),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFD7D7D7),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.standard)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFD7D7D7),
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.standard)),
              ),
            ),
          ),
          Positioned(
            left: 28,
            top: 18,
            bottom: 18,
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: const Text(
                'Coca-Cola',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            bottom: 14,
            child: Transform.rotate(
              angle: 0.22,
              child: Container(
                width: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipsBagArt extends StatelessWidget {
  const _ChipsBagArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 108,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primarySoft, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            right: 12,
            top: 26,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryDeep,
                borderRadius: BorderRadius.circular(AppRadius.rounded),
              ),
              child: const Center(
                child: Text(
                  "Lay's",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 22,
            right: 22,
            bottom: 14,
            child: Text(
              'Classic',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChocolateArt extends StatelessWidget {
  const _ChocolateArt();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.02,
      child: Container(
        width: 86,
        height: 34,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF9F5F0), Color(0xFFF4B9B9)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 8,
              top: 8,
              child: Text(
                'Galaxy',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 2,
              child: Container(
                width: 42,
                height: 18,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.ink, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomRight: Radius.circular(AppRadius.sharp),
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

class _CerealBoxArt extends StatelessWidget {
  const _CerealBoxArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 102,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: const Color(0xFFE4E6EA)),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 8,
            left: 10,
            child: Text(
              "Kellogg's",
              style: TextStyle(
                color: AppColors.primaryDeep,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Positioned(
            top: 30,
            left: 18,
            child: Text(
              'CORN\nFLAKES',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Text(
                  'flakes',
                  style: TextStyle(
                    color: AppColors.primaryDeep,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoapBoxArt extends StatelessWidget {
  const _SoapBoxArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFEFF), Color(0xFFF0F4FB)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: const Stack(
        children: [
          Positioned(
            top: 8,
            left: 12,
            child: Text(
              'Dove',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            right: 12,
            child: Divider(color: AppColors.primary, thickness: 4),
          ),
        ],
      ),
    );
  }
}

class _ToothpasteArt extends StatelessWidget {
  const _ToothpasteArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDeep, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: const Row(
        children: [
          SizedBox(width: 8),
          Text(
            'Colgate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PumpBottleArt extends StatelessWidget {
  const _PumpBottleArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 110,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 34,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(AppRadius.sharp),
              ),
            ),
          ),
          Positioned(
            top: 10,
            child: Container(
              width: 18,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(AppRadius.sharp),
              ),
            ),
          ),
          Positioned(
            top: 22,
            child: Container(
              width: 52,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF3F4F6), Color(0xFF111111)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.rounded),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF111111),
                  child: Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetergentBagArt extends StatelessWidget {
  const _DetergentBagArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 108,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBright, AppColors.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'Tide',
              style: TextStyle(
                color: AppColors.primaryDeep,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottleRibsPainter extends CustomPainter {
  const _BottleRibsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x88F1A8A8)
      ..strokeWidth = 1;
    for (double y = 16; y < size.height - 12; y += 12) {
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
