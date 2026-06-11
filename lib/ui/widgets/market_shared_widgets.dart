import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../business_category_config.dart';
import 'app_design.dart';
import '../models/product_item.dart';
import '../home/sales_page.dart';
import '../products/product_management_page.dart';
import '../more/customers_page.dart';
import '../more/expenses_tracking_page.dart';
import '../more/help_support_page.dart';
import '../more/about_app_page.dart';
import '../../service/pos_local_store.dart';

String _dual(AppStrings strings, String english, String swahili) {
  return strings.isSwahili ? swahili : english;
}

class BackdropGlow extends StatelessWidget {
  const BackdropGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ColoredBox(color: AppColors.pageBackground),
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
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({
    super.key,
    this.iconColor = AppColors.ink,
    this.backgroundColor = Colors.transparent,
    this.borderColor = Colors.transparent,
    this.shadowColor = Colors.transparent,
  });

  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => InkWell(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        onTap: () => Scaffold.of(context).openDrawer(),
        child: SizedBox(
          width: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DrawerMenuLine(width: 30, color: iconColor),
              const SizedBox(height: 6),
              _DrawerMenuLine(width: 20, color: iconColor),
              const SizedBox(height: 6),
              _DrawerMenuLine(width: 30, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerMenuLine extends StatelessWidget {
  const _DrawerMenuLine({
    required this.width,
    required this.color,
  });

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

enum MarketNoticeType {
  success,
  warning,
  error,
}

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
                    color: AppColors.danger,
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
    required this.onDukaAiTap,
    this.onNotificationTap,
    this.aiBackground = AppColors.surface,
    this.aiForeground = AppColors.textMain,
    this.aiBorderColor = AppColors.border,
    this.notificationBackground = AppColors.surface,
    this.notificationForeground = AppColors.textMain,
    this.notificationBorderColor = AppColors.border,
    this.showNotificationDot = false,
    this.spacing = AppSpacing.sm,
  });

  final VoidCallback onDukaAiTap;
  final VoidCallback? onNotificationTap;
  final Color aiBackground;
  final Color aiForeground;
  final Color aiBorderColor;
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
          icon: Icons.smart_toy_outlined,
          background: aiBackground,
          foreground: aiForeground,
          borderColor: aiBorderColor,
          onTap: onDukaAiTap,
        ),
        SizedBox(width: spacing),
        HeaderActionButton(
          icon: Icons.notifications_none_rounded,
          background: notificationBackground,
          foreground: notificationForeground,
          borderColor: notificationBorderColor,
          showDot: showNotificationDot,
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}

class MarketPageHeader extends StatelessWidget {
  const MarketPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.actions,
    this.showBackButton = true,
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
              )
            else
              const SizedBox(width: 42),
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
              const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap, required this.isGradient});

  final VoidCallback onTap;
  final bool isGradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
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
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isGradient ? Colors.white : AppColors.ink,
          size: 18,
        ),
      ),
    );
  }
}

class MarketButton extends StatelessWidget {
  const MarketButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isPrimary = true,
    this.isFullWidth = true,
    this.color,
    this.foregroundColor,
    this.borderColor,
    this.height = 48,
    this.radius = AppRadius.button,
    this.paddingHorizontal = AppSpacing.xl,
    this.boxShadow,
    this.fontSize,
    this.fontWeight,
    this.iconSize = 18,
    this.iconSpacing = AppSpacing.sm,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
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
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? (isPrimary ? AppColors.primary : AppColors.surface);
    final effectiveForeground =
        foregroundColor ?? (isPrimary ? Colors.white : AppColors.textMain);
    final effectiveBorderColor =
        borderColor ?? (isPrimary ? null : AppColors.border);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(radius),
          border: effectiveBorderColor != null
              ? Border.all(color: effectiveBorderColor)
              : null,
          boxShadow: boxShadow ?? (isPrimary ? AppShadows.primary : null),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: effectiveForeground,
                size: iconSize,
              ),
              SizedBox(width: iconSpacing),
            ],
            Text(
              label,
              style: AppTypography.bodyMain.copyWith(
                color: effectiveForeground,
                fontSize: fontSize,
                fontWeight: fontWeight ?? FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketSearchField extends StatelessWidget {
  const MarketSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.onScanTap,
    this.height = 56,
    this.radius = AppRadius.input,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.iconColor = Colors.white,
    this.hintColor = AppColors.textLight,
    this.textColor = AppColors.textMain,
    this.leadingIcon = Icons.search_rounded,
    this.paddingHorizontal = AppSpacing.lg,
    this.iconSize = 20,
    this.showShadow = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onScanTap;
  final double height;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color hintColor;
  final Color textColor;
  final IconData leadingIcon;
  final double paddingHorizontal;
  final double iconSize;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: showShadow ? AppShadows.soft : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.sm),
          Icon(
            leadingIcon,
            size: iconSize,
            color: AppColors.textLight,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: AppTypography.bodyMain.copyWith(color: textColor),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: AppTypography.bodyMain
                    .copyWith(color: hintColor, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (hasValue && onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(
                Icons.cancel_rounded,
                size: 20,
                color: AppColors.textLight,
              ),
              splashRadius: 20,
            ),
          if (onScanTap != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: IconButton(
                onPressed: onScanTap,
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MarketSectionHeader extends StatelessWidget {
  const MarketSectionHeader({
    super.key,
    required this.title,
    required this.trailing,
    this.titleColor = AppColors.ink,
    this.titleSize,
    this.titleWeight,
  });

  final String title;
  final Widget trailing;
  final Color titleColor;
  final double? titleSize;
  final FontWeight? titleWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.sectionHeader.copyWith(
            color: titleColor,
            fontSize: titleSize,
            fontWeight: titleWeight,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class MarketSurfaceCard extends StatelessWidget {
  const MarketSurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius = AppRadius.standard,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: showShadow ? AppShadows.soft : null,
      ),
      child: child,
    );
  }
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
      ? AppColors.success
      : (type == MarketNoticeType.warning
          ? AppColors.warning
          : AppColors.danger);

  final iconBg = type == MarketNoticeType.success
      ? AppColors.successLight
      : (type == MarketNoticeType.warning
          ? AppColors.warningLight
          : AppColors.dangerLight);

  final icon = type == MarketNoticeType.success
      ? Icons.check_circle_rounded
      : (type == MarketNoticeType.warning
          ? Icons.error_outline_rounded
          : Icons.cancel_rounded);

  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      top: MediaQuery.of(context).padding.top + AppSpacing.md,
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
  Future<void>.delayed(const Duration(milliseconds: 2500)).then((_) {
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
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.medium,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.sharp),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              child: Image.file(
                File(imagePath!),
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

class MarketAppDrawer extends StatelessWidget {
  const MarketAppDrawer({
    super.key,
    this.selectedItem = 'Home',
  });

  final String selectedItem;

  List<_DrawerItemData> _quickActionsFor(
    BusinessCategoryConfig config,
    AppStrings strings,
  ) {
    return switch (config.category) {
      BusinessCategory.pharmacy => [
          _DrawerItemData(
            strings.scanPrescription,
            Icons.medication_rounded,
            onTap: (context) {
              showMarketNotice(
                context,
                title: strings.scanPrescription,
                message: _dual(
                  strings,
                  'Prescription search and scan flow goes here.',
                  'Utafutaji na uchambuzi wa dawa utawekwa hapa.',
                ),
              );
            },
          ),
          _DrawerItemData(
            strings.expiryCheck,
            Icons.event_busy_rounded,
            onTap: (context) {
              showMarketNotice(
                context,
                title: strings.expiryCheck,
                message: _dual(
                  strings,
                  'Expiry tracking needs product-level metadata.',
                  'Ufuatiliaji wa muda wa kuisha unahitaji taarifa za bidhaa.',
                ),
              );
            },
          ),
          _DrawerItemData(
            strings.refillQueue,
            Icons.queue_rounded,
            onTap: (context) {
              showMarketNotice(
                context,
                title: strings.refillQueue,
                message: _dual(
                  strings,
                  'Prescription refill workflow is ready to add.',
                  'Mtiririko wa kuongeza dawa upya uko tayari kuongezwa.',
                ),
              );
            },
          ),
        ],
      BusinessCategory.electronics => [
          _DrawerItemData(
            _dual(strings, 'Scan Serial', 'Changanua Serial'),
            Icons.qr_code_scanner_rounded,
            onTap: (context) {
              showMarketNotice(
                context,
                title: _dual(strings, 'Serial Scan', 'Uchanganuzi wa Serial'),
                message: _dual(
                  strings,
                  'Serial capture is ready to connect.',
                  'Kukusanya serial iko tayari kuunganishwa.',
                ),
              );
            },
          ),
          _DrawerItemData(
            _dual(strings, 'Register Warranty', 'Sajili Dhamana'),
            Icons.verified_user_outlined,
            onTap: (context) {
              showMarketNotice(
                context,
                title: _dual(strings, 'Warranty Register', 'Usajili wa Dhamana'),
                message: _dual(
                  strings,
                  'Warranty registration can be attached here.',
                  'Usajili wa dhamana unaweza kuwekwa hapa.',
                ),
              );
            },
          ),
          _DrawerItemData(
            _dual(strings, 'Service Plans', 'Mipango ya Huduma'),
            Icons.handyman_outlined,
            onTap: (context) {
              showMarketNotice(
                context,
                title: _dual(strings, 'Service Plans', 'Mipango ya Huduma'),
                message: _dual(
                  strings,
                  'Service plan upsells can be added next.',
                  'Mipango ya huduma inaweza kuongezwa baadaye.',
                ),
              );
            },
          ),
        ],
      BusinessCategory.retail => [],
    };
  }

  List<_DrawerItemData> _operationsItemsFor(
    BusinessCategoryConfig config,
    AppStrings strings,
  ) {
    return switch (config.category) {
      BusinessCategory.pharmacy => [
          _DrawerItemData(
            strings.medicineCatalog,
            Icons.medical_services_outlined,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ProductManagementPage(),
                ),
              );
            },
          ),
          _DrawerItemData(
            strings.prescriptionSales,
            Icons.receipt_long_outlined,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SalesPage(),
                ),
              );
            },
          ),
        ],
      BusinessCategory.electronics => [
          _DrawerItemData(
            strings.deviceCatalog,
            Icons.devices_other_outlined,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ProductManagementPage(),
                ),
              );
            },
          ),
          _DrawerItemData(
            _dual(strings, 'Warranty Claims', 'Madai ya Dhamana'),
            Icons.shield_outlined,
            onTap: (context) {
              showMarketNotice(
                context,
                title: _dual(strings, 'Warranty Claims', 'Madai ya Dhamana'),
                message: _dual(
                  strings,
                  'Claims tracking can be added next.',
                  'Ufuatiliaji wa madai unaweza kuongezwa baadaye.',
                ),
              );
            },
          ),
        ],
      BusinessCategory.retail => [
          _DrawerItemData(
            strings.customers,
            Icons.people_alt_outlined,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const CustomersPage(),
                ),
              );
            },
          ),
          _DrawerItemData(
            strings.expensesTracking,
            Icons.receipt_long_outlined,
            onTap: (context) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ExpensesTrackingPage(),
                ),
              );
            },
          ),
        ],
    };
  }

  List<_DrawerItemData> _supportItems(AppStrings strings) {
    return [
      _DrawerItemData(strings.helpSupport, Icons.support_agent_outlined),
      _DrawerItemData(strings.aboutApp, Icons.info_outline_rounded),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.of(context).size.width * 0.85;
    final store = context.watch<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final strings = AppStrings.of(store.languageCode);

    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl,
                  AppSpacing.xxl, AppSpacing.lg),
              child: _DrawerProfileHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DrawerSectionHeader(
                      title: _quickActionsTitle(config.category, strings),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DrawerSection(
                      items: _quickActionsFor(config, strings),
                      selectedItem: selectedItem,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    _DrawerSectionHeader(
                      title: _operationsTitle(config.category, strings),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DrawerSection(
                      items: _operationsItemsFor(config, strings),
                      selectedItem: selectedItem,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    _DrawerSection(
                      items: _supportItems(strings),
                      selectedItem: selectedItem,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: AppSpacing.xl),
                    const _LogoutButton(),
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

class _DrawerProfileHeader extends StatelessWidget {
  const _DrawerProfileHeader();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<PosLocalStore>().profile;
    final config = context.read<PosLocalStore>().businessCategoryConfig;
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final ownerName = profile.ownerName.isEmpty
        ? (profile.storeName.isEmpty
            ? (profile.businessCategory.isEmpty
                ? strings.setupStoreProfile
                : profile.businessCategory)
            : profile.storeName)
        : profile.ownerName;
    final category = profile.businessCategory.isEmpty
        ? (profile.roleTitle.isEmpty ? strings.businessOwner : profile.roleTitle)
        : profile.businessCategory;
    final storeDetail =
        profile.storeName.isEmpty || profile.storeName == ownerName
            ? ''
            : profile.storeName;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: profile.logoPath == null
                ? const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 40,
                  )
                : ClipOval(
                    child: Image.file(
                      File(profile.logoPath!),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ownerName,
                style: AppTypography.h3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              BusinessCategoryBadge(
                category: config.category,
                label: category,
              ),
              if (storeDetail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  storeDetail,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.items,
    required this.selectedItem,
  });

  final List<_DrawerItemData> items;
  final String selectedItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _DrawerTile(
                item: item,
                isSelected: item.label == selectedItem,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.label.copyWith(
        color: AppColors.textLight,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isSelected,
  });

  final _DrawerItemData item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.standard),
      onTap: () {
        Navigator.of(context).pop();
        if (isSelected) {
          return;
        }
        if (item.onTap != null) {
          item.onTap!(context);
          return;
        }
        final route = _routeForLabel(item.label);
        if (route != null) {
          Navigator.of(context).push(route);
        }
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.bodyMain.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textMain,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Route<void>? _routeForLabel(String label) {
  switch (label) {
    case 'Customers':
    case 'Wateja':
      return MaterialPageRoute<void>(
        builder: (context) => const CustomersPage(),
      );
    case 'Expenses Tracking':
    case 'Ufuatiliaji wa Matumizi':
      return MaterialPageRoute<void>(
        builder: (context) => const ExpensesTrackingPage(),
      );
    case 'Help & Support':
    case 'Msaada na Usaidizi':
      return MaterialPageRoute<void>(
        builder: (context) => const HelpSupportPage(),
      );
    case 'About App':
    case 'Kuhusu Programu':
      return MaterialPageRoute<void>(
        builder: (context) => const AboutAppPage(),
      );
    default:
      return null;
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.standard),
      onTap: () {
        Navigator.of(context).pop();
        showMarketNotice(
          context,
          title: _dual(strings, 'Logged Out', 'Umetoka'),
          message: _dual(
            strings,
            'You can connect the real auth flow next',
            'Unaweza kuunganisha uthibitisho halisi baadaye',
          ),
        );
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.danger,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              strings.logout,
              style: AppTypography.bodyMain.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItemData {
  const _DrawerItemData(this.label, this.icon, {this.onTap});

  final String label;
  final IconData icon;
  final void Function(BuildContext context)? onTap;
}

String _quickActionsTitle(BusinessCategory category, AppStrings strings) {
  return switch (category) {
    BusinessCategory.pharmacy => strings.pharmacyActions,
    BusinessCategory.electronics => strings.deviceActions,
    BusinessCategory.retail => strings.retailActions,
  };
}

String _operationsTitle(BusinessCategory category, AppStrings strings) {
  return strings.operations;
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
                  colors: [Color(0xFFF9FCFF), Color(0xFFD6E4F3)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.rounded),
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
          colors: [Color(0xFFFEEB6B), Color(0xFFF9CF1E)],
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
                color: const Color(0xFFE32A1C),
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
        borderRadius: BorderRadius.circular(AppRadius.sharp),
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
                color: const Color(0xFF9FD776),
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
                color: const Color(0xFF9FD776),
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
                  colors: [Color(0xFFF0FFF0), Color(0xFFCCEEB2)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.rounded),
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
        borderRadius: BorderRadius.circular(AppRadius.sharp),
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

class MarketFormField extends StatelessWidget {
  const MarketFormField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTypography.bodyMain,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                AppTypography.bodyMain.copyWith(color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}

class MarketTable extends StatelessWidget {
  const MarketTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headerColor = AppColors.surfaceSecondary,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final Color headerColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.standard)),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: columns
                .map((col) => Expanded(
                      child: Text(
                        col.toUpperCase(),
                        style: AppTypography.tableHeader,
                      ),
                    ))
                .toList(),
          ),
        ),
        // Rows
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isLast = index == rows.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: const BorderSide(color: AppColors.border),
                right: const BorderSide(color: AppColors.border),
                bottom: BorderSide(
                  color: AppColors.border,
                  width: isLast ? 1 : 0.5,
                ),
              ),
              borderRadius: isLast
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.standard))
                  : null,
            ),
            child: Row(
              children: row.map((cell) => Expanded(child: cell)).toList(),
            ),
          );
        }),
      ],
    );
  }
}

class BusinessCategoryBadge extends StatelessWidget {
  const BusinessCategoryBadge({
    super.key,
    required this.category,
    this.label,
  });

  final BusinessCategory category;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final config = BusinessCategoryConfig.forCategory(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.primaryLightColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: config.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Text(
        label ?? category.displayName,
        style: AppTypography.label.copyWith(
          color: config.primaryColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CategorySpecificTile extends StatelessWidget {
  const CategorySpecificTile({
    super.key,
    required this.category,
    required this.child,
  });

  final BusinessCategory category;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final config = BusinessCategoryConfig.forCategory(category);
    return Container(
      decoration: BoxDecoration(
        color: config.surfaceTintColor,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: config.primaryColor.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class CategoryAwareHeader extends StatelessWidget {
  const CategoryAwareHeader({
    super.key,
    required this.category,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBackButton = true,
  });

  final BusinessCategory category;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final config = BusinessCategoryConfig.forCategory(category);
    return MarketPageHeader(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      actions: trailing == null ? null : [trailing!],
      isGradient: true,
      centerTitle: false,
      titleSize: 22,
      titleWeight: FontWeight.w800,
      gradientColors: [config.primaryColor, config.primaryDeepColor],
    );
  }
}

extension BusinessCategoryWidgetBuilders on BusinessCategory {
  BusinessCategoryBadge badge({String? label}) {
    return BusinessCategoryBadge(category: this, label: label);
  }

  CategorySpecificTile tile({required Widget child}) {
    return CategorySpecificTile(category: this, child: child);
  }

  CategoryAwareHeader header({
    required String title,
    String? subtitle,
    Widget? trailing,
    bool showBackButton = true,
  }) {
    return CategoryAwareHeader(
      category: this,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      showBackButton: showBackButton,
    );
  }
}
