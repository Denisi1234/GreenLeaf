import 'package:flutter/material.dart';

import '../app_design.dart';

class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.showDot = false,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: AppShadows.soft,
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: foreground, size: 20)),
            if (showDot)
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MarketHeaderActionButtons extends StatelessWidget {
  const MarketHeaderActionButtons({
    super.key,
    this.onNotificationTap,
    this.onSettingsTap,
    this.showSettings = false,
    this.notificationBackground = AppColors.surface,
    this.notificationForeground = AppColors.textMain,
    this.notificationBorderColor = AppColors.border,
    this.showNotificationDot = false,
    this.spacing = AppSpacing.sm,
  });

  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;
  final bool showSettings;
  final Color notificationBackground;
  final Color notificationForeground;
  final Color notificationBorderColor;
  final bool showNotificationDot;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HeaderActionButton(
          icon: Icons.notifications_none_rounded,
          background: notificationBackground,
          foreground: notificationForeground,
          borderColor: notificationBorderColor,
          showDot: showNotificationDot,
          onTap: onNotificationTap,
        ),
        if (showSettings || onSettingsTap != null) ...[
          SizedBox(width: spacing),
          HeaderActionButton(
            icon: Icons.settings_outlined,
            background: notificationBackground,
            foreground: notificationForeground,
            borderColor: notificationBorderColor,
            onTap: onSettingsTap,
          ),
        ],
      ],
    );
  }
}
