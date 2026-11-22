import 'package:aza_pos/l10n/app_localization.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_design.dart';
import 'market_notice.dart';

enum MarketButtonVariant {
  primary,
  secondary,
  success,
  danger,
  ghost,
}

/// Unified button component across the entire application.
/// Provides consistent touch targets, typography, loading state spinner,
/// color variants, and error handling.
class MarketButton extends StatefulWidget {
  const MarketButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = MarketButtonVariant.primary,
    this.isPrimary = true,
    this.isFullWidth = true,
    this.color,
    this.foregroundColor,
    this.borderColor,
    this.height = 48,
    this.radius = AppRadius.pill,
    this.paddingHorizontal = AppSpacing.xl,
    this.boxShadow,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w700,
    this.iconSize = 18,
    this.iconSpacing = AppSpacing.sm,
  });

  /// Factory constructor for a primary action button
  factory MarketButton.primary({
    Key? key,
    required String label,
    required FutureOr<void> Function()? onTap,
    IconData? icon,
    bool isFullWidth = true,
    double height = 48,
  }) {
    return MarketButton(
      key: key,
      label: label,
      onTap: onTap,
      icon: icon,
      variant: MarketButtonVariant.primary,
      isFullWidth: isFullWidth,
      height: height,
    );
  }

  /// Factory constructor for a success/complete action button
  factory MarketButton.success({
    Key? key,
    required String label,
    required FutureOr<void> Function()? onTap,
    IconData? icon,
    bool isFullWidth = true,
    double height = 48,
  }) {
    return MarketButton(
      key: key,
      label: label,
      onTap: onTap,
      icon: icon,
      variant: MarketButtonVariant.success,
      isFullWidth: isFullWidth,
      height: height,
    );
  }

  /// Factory constructor for a secondary/outlined button
  factory MarketButton.secondary({
    Key? key,
    required String label,
    required FutureOr<void> Function()? onTap,
    IconData? icon,
    bool isFullWidth = true,
    double height = 48,
  }) {
    return MarketButton(
      key: key,
      label: label,
      onTap: onTap,
      icon: icon,
      variant: MarketButtonVariant.secondary,
      isFullWidth: isFullWidth,
      height: height,
    );
  }

  /// Factory constructor for a danger/destructive action button
  factory MarketButton.danger({
    Key? key,
    required String label,
    required FutureOr<void> Function()? onTap,
    IconData? icon,
    bool isFullWidth = true,
    double height = 48,
  }) {
    return MarketButton(
      key: key,
      label: label,
      onTap: onTap,
      icon: icon,
      variant: MarketButtonVariant.danger,
      isFullWidth: isFullWidth,
      height: height,
    );
  }

  final String label;
  final FutureOr<void> Function()? onTap;
  final IconData? icon;
  final MarketButtonVariant variant;
  final bool isPrimary;
  final bool isFullWidth;
  final Color? color;
  final Color? foregroundColor;
  final Color? borderColor;
  final double height;
  final double radius;
  final double paddingHorizontal;
  final List<BoxShadow>? boxShadow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double iconSize;
  final double iconSpacing;

  @override
  State<MarketButton> createState() => _MarketButtonState();
}

class _MarketButtonState extends State<MarketButton> {
  bool _running = false;

  Future<void> _invoke() async {
    if (_running || widget.onTap == null) return;
    setState(() => _running = true);
    try {
      await widget.onTap!();
    } catch (error) {
      if (mounted) {
        showMarketNotice(
          context,
          title: context.tr('Action could not complete'),
          message: error is StateError
              ? error.message.toString()
              : context.tr('Please try again. Your form is still available.'),
          type: MarketNoticeType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  (Color bg, Color fg, Color? border) _resolveColors() {
    if (widget.color != null || widget.foregroundColor != null) {
      return (
        widget.color ?? AppColors.primary,
        widget.foregroundColor ?? Colors.white,
        widget.borderColor,
      );
    }

    // If explicit legacy isPrimary was passed as false and variant is default
    if (!widget.isPrimary && widget.variant == MarketButtonVariant.primary) {
      return (AppColors.surfaceSecondary, AppColors.textBody, null);
    }

    switch (widget.variant) {
      case MarketButtonVariant.primary:
        return (AppColors.primary, Colors.white, null);
      case MarketButtonVariant.success:
        return (AppColors.successDeep, Colors.white, null);
      case MarketButtonVariant.danger:
        return (AppColors.dangerDeep, Colors.white, null);
      case MarketButtonVariant.secondary:
        return (AppColors.surface, AppColors.textBody, AppColors.border);
      case MarketButtonVariant.ghost:
        return (Colors.transparent, AppColors.textBody, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null || _running;
    final (bg, fg, border) = _resolveColors();
    final textHeight =
        MediaQuery.textScalerOf(context).scale(widget.fontSize ?? 14) * 2.4 +
            16;
    final effectiveHeight =
        textHeight > widget.height ? textHeight : widget.height;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: widget.boxShadow,
      ),
      child: SizedBox(
        height: effectiveHeight,
        width: widget.isFullWidth ? double.infinity : null,
        child: FilledButton(
          onPressed: disabled ? null : _invoke,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: _running ? bg : AppColors.border,
            disabledForegroundColor: _running ? fg : AppColors.textLight,
            padding: EdgeInsets.symmetric(horizontal: widget.paddingHorizontal),
            minimumSize: Size(0, effectiveHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            side: border != null ? BorderSide(color: border) : BorderSide.none,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_running) ...[
                SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                ),
                SizedBox(width: widget.iconSpacing),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.iconSize, color: fg),
                SizedBox(width: widget.iconSpacing),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMain.copyWith(
                    color: disabled && !_running ? AppColors.textLight : fg,
                    fontSize: widget.fontSize ?? 14,
                    fontWeight: widget.fontWeight ?? FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
