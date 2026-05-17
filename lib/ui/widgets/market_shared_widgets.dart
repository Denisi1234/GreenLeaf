import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/product_item.dart';

class BackdropGlow extends StatelessWidget {
  const BackdropGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFEFC), Color(0xFFF8F7F3)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -20,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x22FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 140,
              right: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x18FFFFFF), Color(0x00FFFFFF)],
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

class ScrollHandle extends StatelessWidget {
  const ScrollHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 3,
        height: 118,
        decoration: BoxDecoration(
          color: const Color(0xFFD2D7DE),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

enum MarketNoticeType {
  success,
  warning,
}

void showMarketNotice(
  BuildContext context, {
  required String title,
  required String message,
  MarketNoticeType type = MarketNoticeType.success,
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  final accent = type == MarketNoticeType.success
      ? const Color(0xFF1E7A47)
      : const Color(0xFFB45309);
  final iconBg = type == MarketNoticeType.success
      ? const Color(0xFFEFF8F2)
      : const Color(0xFFFFF5E8);
  final icon = type == MarketNoticeType.success
      ? Icons.check_circle_rounded
      : Icons.error_outline_rounded;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 18,
      right: 18,
      top: MediaQuery.of(context).padding.top + 14,
      child: _MarketNoticeCard(
        title: title,
        message: message,
        accent: accent,
        iconBg: iconBg,
        icon: icon,
      ),
    ),
  );

  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2200)).then((_) {
    entry.remove();
  });
}

class _MarketNoticeCard extends StatelessWidget {
  const _MarketNoticeCard({
    required this.title,
    required this.message,
    required this.accent,
    required this.iconBg,
    required this.icon,
  });

  final String title;
  final String message;
  final Color accent;
  final Color iconBg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * -18),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF202938),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      width: compact ? 30 : 44,
      height: compact ? 30 : 44,
      padding: hasImage ? EdgeInsets.zero : EdgeInsets.all(compact ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
              child: Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
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
                color: const Color(0xFF2A6FD4),
                borderRadius: BorderRadius.circular(4),
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
                  colors: [Color(0xFFF9FCFF), Color(0xFFD6E4F3)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFB8CBE0)),
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
                        color: const Color(0xFF1357BC),
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
          colors: [Color(0xFFB30810), Color(0xFFFF3434), Color(0xFFC70F17)],
        ),
        borderRadius: BorderRadius.circular(14),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
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
                  borderRadius: BorderRadius.circular(99),
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
          colors: [Color(0xFFFEEB6B), Color(0xFFF9CF1E)],
        ),
        borderRadius: BorderRadius.circular(12),
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
                color: const Color(0xFFE32A1C),
                borderRadius: BorderRadius.circular(18),
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
                color: Color(0xFF5A4A10),
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
            colors: [Color(0xFFF9F5F0), Color(0xFFE6D7C7)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
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
                  color: Color(0xFF532D16),
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
                    colors: [Color(0xFF6E3F20), Color(0xFFD0A86B)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomRight: Radius.circular(8),
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
        borderRadius: BorderRadius.circular(6),
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
                color: Color(0xFFCC1E2C),
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
                color: Color(0xFF222831),
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
                color: const Color(0xFFF5E8A5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Text(
                  'flakes',
                  style: TextStyle(
                    color: Color(0xFF8E6D11),
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDEE3EC)),
      ),
      child: const Stack(
        children: [
          Positioned(
            top: 8,
            left: 12,
            child: Text(
              'Dove',
              style: TextStyle(
                color: Color(0xFF284E91),
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
            child: Divider(color: Color(0xFF3572C4), thickness: 4),
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
          colors: [Color(0xFFC3141B), Color(0xFF1C6BCE)],
        ),
        borderRadius: BorderRadius.circular(5),
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
                color: const Color(0xFF9FD776),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            top: 10,
            child: Container(
              width: 18,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF9FD776),
                borderRadius: BorderRadius.circular(8),
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
                  colors: [Color(0xFFF0FFF0), Color(0xFFCCEEB2)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF5AA73A),
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
          colors: [Color(0xFFFF591D), Color(0xFFF33209)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFF6C91A),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'Tide',
              style: TextStyle(
                color: Color(0xFF1756B3),
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
      ..color = const Color(0x88B3CAE6)
      ..strokeWidth = 1;
    for (double y = 16; y < size.height - 12; y += 12) {
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
