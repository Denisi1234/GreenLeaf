import 'package:flutter/material.dart';

import '../app_design.dart';

class MarketPageHeader extends StatelessWidget {
  const MarketPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.actions,
    this.showBackButton = true,
    this.transparentBackButton = true,
    this.onBack,
    this.isGradient = false,
    this.transparent = false,
    this.showShadow = false,
    this.showBorder = true,
    this.centerTitle = true,
    this.titleSize,
    this.titleWeight,
    this.gradientColors,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool transparentBackButton;
  final VoidCallback? onBack;
  final bool isGradient;
  final bool transparent;
  final bool showShadow;
  final bool showBorder;
  final bool centerTitle;
  final double? titleSize;
  final FontWeight? titleWeight;
  final List<Color>? gradientColors;

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGradient = isGradient;
    final hasBackground = !transparent && !hasGradient;
    final effectiveColor = hasGradient ? Colors.white : AppColors.ink;
    final hasBorder = showBorder && !transparent && !hasGradient;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md,
          AppSpacing.pagePadding, AppSpacing.lg),
      decoration: BoxDecoration(
        color: hasBackground ? AppColors.surface : null,
        gradient: hasGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ??
                    const [AppColors.primary, AppColors.primaryDeep],
              )
            : null,
        borderRadius: hasGradient
            ? const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.extraRounded))
            : null,
        border: hasBorder
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
        boxShadow: showShadow ? AppShadows.soft : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: leading!,
              )
            else if (showBackButton)
              _BackButton(
                onTap: () => _handleBack(context),
                isGradient: hasGradient,
                transparent: transparentBackButton,
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Column(
                crossAxisAlignment: centerTitle
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3.copyWith(
                      color: effectiveColor,
                      fontSize: titleSize,
                      fontWeight: titleWeight,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      textAlign:
                          centerTitle ? TextAlign.center : TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: hasGradient
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (actions != null)
              Row(mainAxisSize: MainAxisSize.min, children: actions!)
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.onTap,
    required this.isGradient,
    this.transparent = false,
  });

  final VoidCallback onTap;
  final bool isGradient;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final foreground = isGradient ? Colors.white : AppColors.ink;

    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: transparent
              ? null
              : BoxDecoration(
                  color: isGradient
                      ? Colors.white.withValues(alpha: 0.16)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                  border: Border.all(
                    color: isGradient
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.border,
                  ),
                ),
          child: _LongArrowIcon(color: foreground, size: 26),
        ),
      ),
    );
  }
}

/// Left-pointing arrow with a long shaft, drawn as vector so it stays crisp at
/// the larger mobile-friendly size.
class _LongArrowIcon extends StatelessWidget {
  const _LongArrowIcon({required this.color, this.size = 26});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LongArrowPainter(
        color: color,
        strokeWidth: (size * 0.085).clamp(1.8, 3.0),
      ),
    );
  }
}

class _LongArrowPainter extends CustomPainter {
  const _LongArrowPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tip = Offset(size.width * 0.06, size.height * 0.5);

    canvas.drawLine(
      tip,
      Offset(size.width * 0.96, size.height * 0.5),
      paint,
    );

    final head = Path()
      ..moveTo(size.width * 0.36, size.height * 0.16)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(size.width * 0.36, size.height * 0.84);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_LongArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
