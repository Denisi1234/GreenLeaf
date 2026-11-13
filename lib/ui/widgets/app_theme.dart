import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_design.dart';

/// Global Material theme mirroring the OSPOS "UI maturity" styling:
/// neutral text, green primary actions and active states, 10px controls,
/// 12px dialogs, 14–18px cards and 42–44px touch targets.
ThemeData buildOsposTheme(TextTheme textTheme) {
  const controlRadius = BorderRadius.all(Radius.circular(AppRadius.standard));
  const minControl = Size(64, AppSpacing.controlHeight);
  final fontFamily = GoogleFonts.manrope().fontFamily;

  // All TextStyles inside ThemeData must have `inherit: false` so they match
  // Typography.material2021() and never fail TextStyle.lerp during animations.
  TextStyle style({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      inherit: false,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      textBaseline: TextBaseline.alphabetic,
      leadingDistribution: TextLeadingDistribution.even,
      decoration: TextDecoration.none,
    );
  }

  final labelStyle = style(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: 0.1,
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.surfaceSecondary,
    onPrimaryContainer: AppColors.primaryDeep,
    secondary: AppColors.success,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.successLight,
    onSecondaryContainer: AppColors.successDeep,
    tertiary: AppColors.toneIndigo,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerLight,
    onErrorContainer: AppColors.dangerDeep,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.surfaceSecondary,
    surfaceContainer: AppColors.surfaceSecondary,
    surfaceContainerHigh: AppColors.surfaceHover,
    surfaceContainerHighest: AppColors.surfaceHover,
    outline: AppColors.border,
    outlineVariant: AppColors.borderLight,
    surfaceTint: Colors.transparent,
    shadow: AppColors.ink,
    scrim: AppColors.backdrop,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.pageBackground,
    canvasColor: AppColors.pageBackground,
    splashFactory: InkSparkle.splashFactory,
    hoverColor: AppColors.surfaceHover,
    highlightColor: AppColors.surfaceHover,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    iconTheme: const IconThemeData(color: AppColors.textMuted, size: 22),
    primaryIconTheme: const IconThemeData(color: AppColors.ink, size: 22),

    // Top bar – white header with slate brand text (mobile .navbar-header)
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppColors.border,
      centerTitle: false,
      toolbarHeight: 56,
      iconTheme: const IconThemeData(color: AppColors.textBody),
      actionsIconTheme: const IconThemeData(color: AppColors.textBody),
      titleTextStyle: style(
        color: AppColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
    ),

    // .module_item cards
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        side: BorderSide(color: AppColors.border),
      ),
    ),

    // .modal-content
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.modal)),
      ),
      titleTextStyle: style(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textStrong,
        letterSpacing: -0.2,
      ),
      contentTextStyle: style(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textBody,
        height: 1.45,
      ),
      barrierColor: AppColors.backdrop,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.surface,
      modalBarrierColor: AppColors.backdrop,
      showDragHandle: true,
      dragHandleColor: AppColors.border,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.extraRounded)),
      ),
    ),

    // Drawer (#ospos-sidebar-collapse)
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      scrimColor: AppColors.backdrop,
      width: 285,
      elevation: 0,
      shape: RoundedRectangleBorder(),
    ),

    // .form-control – white, 1px slate border, 10px radius, 42px+ tall
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      constraints: const BoxConstraints(minHeight: AppSpacing.controlHeight),
      hintStyle: style(
        fontSize: 14,
        color: AppColors.textPlaceholder,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      border: inputBorder(AppColors.border),
      enabledBorder: inputBorder(AppColors.border),
      disabledBorder: inputBorder(AppColors.borderLight),
      focusedBorder: inputBorder(AppColors.primary, 1.5),
      errorBorder: inputBorder(AppColors.danger, 1.2),
      focusedErrorBorder: inputBorder(AppColors.danger, 1.5),
    ),

    // Buttons – 42px min height, 10px radius
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textLight,
        minimumSize: minControl,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: const RoundedRectangleBorder(borderRadius: controlRadius),
        textStyle: labelStyle,
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textLight,
        minimumSize: minControl,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: const RoundedRectangleBorder(borderRadius: controlRadius),
        textStyle: labelStyle,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        minimumSize: minControl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: controlRadius),
        textStyle: labelStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(48, AppSpacing.controlHeight),
        shape: const RoundedRectangleBorder(borderRadius: controlRadius),
        textStyle: labelStyle,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textBody,
        minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
        shape: const RoundedRectangleBorder(borderRadius: controlRadius),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.tile)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(minControl),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: controlRadius),
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.border),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.successLight
              : AppColors.surfaceSecondary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.successDeep
              : AppColors.textSecondary,
        ),
        textStyle: WidgetStatePropertyAll(labelStyle),
      ),
    ),

    // Chips – .nav-tabs pill look (teal when selected)
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceSecondary,
      selectedColor: AppColors.successLight,
      disabledColor: AppColors.surfaceHover,
      checkmarkColor: AppColors.successDeep,
      side: const BorderSide(color: AppColors.border),
      shape: const RoundedRectangleBorder(borderRadius: controlRadius),
      labelStyle: style(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      secondaryLabelStyle: style(
        color: AppColors.successDeep,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),

    // Tabs – teal active indicator (.nav-tabs > li.active)
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.successDeep,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.successBright,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: AppColors.border,
      labelStyle: labelStyle,
      unselectedLabelStyle: labelStyle.copyWith(fontWeight: FontWeight.w600),
      indicator: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: controlRadius,
        border: Border.all(color: AppColors.successBright, width: 1.5),
      ),
      overlayColor: const WidgetStatePropertyAll(AppColors.surfaceHover),
    ),

    // Bottom navigation – active nav = blue on #EFF6FF
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primaryLight,
      elevation: 0,
      height: 68,
      shadowColor: AppColors.border,
      indicatorShape: const RoundedRectangleBorder(borderRadius: controlRadius),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
          size: 24,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => style(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primaryLight,
      indicatorShape: const RoundedRectangleBorder(borderRadius: controlRadius),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => style(
          fontSize: 14,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textBody,
        ),
      ),
    ),

    // Sidebar / list rows (.ospos-sidebar-nav > li > a)
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.textMuted,
      textColor: AppColors.textBody,
      selectedColor: AppColors.primary,
      selectedTileColor: AppColors.primaryLight,
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      shape: const RoundedRectangleBorder(borderRadius: controlRadius),
      titleTextStyle: style(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
      subtitleTextStyle: style(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
    ),

    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(AppColors.surfaceSecondary),
      headingTextStyle: style(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      ),
      dataTextStyle: style(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textBody,
      ),
      dividerThickness: 1,
      headingRowHeight: 44,
      dataRowMinHeight: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: AppColors.border),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: const RoundedRectangleBorder(
        borderRadius: controlRadius,
        side: BorderSide(color: AppColors.border),
      ),
      textStyle: style(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textBody,
      ),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: controlRadius,
            side: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        border: inputBorder(AppColors.borderInput),
        enabledBorder: inputBorder(AppColors.borderInput),
        focusedBorder: inputBorder(AppColors.primary, 1.5),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.textLight,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.successBright
            : AppColors.surfaceHover,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.successBright
            : AppColors.border,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
      side: const BorderSide(color: AppColors.textLight, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.textLight,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceHover,
      circularTrackColor: AppColors.surfaceHover,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.primarySoft,
      thumbColor: AppColors.primary,
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      textStyle: style(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: style(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: AppColors.primarySoft,
      shape: const RoundedRectangleBorder(borderRadius: controlRadius),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.modal)),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x33D32222),
      selectionHandleColor: AppColors.primary,
    ),
  );
}
