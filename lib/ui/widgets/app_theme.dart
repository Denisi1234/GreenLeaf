import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_design.dart';
import 'app_theme_palette.dart';

/// Shared POS theme: neutral surfaces, restrained accents and consistent controls.
ThemeData buildOsposTheme(TextTheme textTheme, {String themeId = 'light'}) {
  final palette = AppThemePalette.forId(themeId);
  const controlRadius = BorderRadius.all(Radius.circular(AppRadius.standard));
  const pillRadius = BorderRadius.all(Radius.circular(AppRadius.pill));
  final fontFamily = GoogleFonts.manrope().fontFamily;

  // All TextStyles inside ThemeData must have `inherit: false` so they match
  // Typography.material2021() and never fail TextStyle.lerp during animations.
  TextStyle style({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      inherit: false,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? palette.ink,
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
    color: palette.ink,
    letterSpacing: 0.1,
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: palette.brightness,
  ).copyWith(
    primary: palette.primary,
    onPrimary: Colors.white,
    primaryContainer: palette.surfaceSecondary,
    onPrimaryContainer: palette.primaryDeep,
    secondary: AppColors.success,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.successLight,
    onSecondaryContainer: AppColors.successDeep,
    tertiary: AppColors.toneIndigo,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerLight,
    onErrorContainer: AppColors.dangerDeep,
    surface: palette.surface,
    onSurface: palette.ink,
    onSurfaceVariant: palette.textMuted,
    surfaceContainerLowest: palette.surface,
    surfaceContainerLow: palette.surfaceSecondary,
    surfaceContainer: palette.surfaceSecondary,
    surfaceContainerHigh: palette.surfaceSecondary,
    surfaceContainerHighest: palette.surfaceSecondary,
    outline: palette.border,
    outlineVariant: palette.divider,
    surfaceTint: Colors.transparent,
    shadow: Colors.black12,
    scrim: AppColors.backdrop,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    extensions: [palette],
    fontFamily: fontFamily,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.pageBackground,
    canvasColor: palette.pageBackground,
    cardColor: palette.surface,
    dividerColor: palette.divider,
    splashFactory: InkSparkle.splashFactory,
    hoverColor: palette.surfaceSecondary,
    highlightColor: palette.surfaceSecondary,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    iconTheme: IconThemeData(color: palette.textMuted, size: 22),
    primaryIconTheme: IconThemeData(color: palette.ink, size: 22),

    // Top bar – clean header using active theme headerSurface
    appBarTheme: AppBarTheme(
      backgroundColor: palette.headerSurface,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: palette.border,
      centerTitle: false,
      toolbarHeight: 56,
      iconTheme: IconThemeData(color: palette.textBody),
      actionsIconTheme: IconThemeData(color: palette.textBody),
      titleTextStyle: style(
        color: palette.ink,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      shape: Border(bottom: BorderSide(color: palette.border)),
    ),

    // .module_item cards
    cardTheme: CardThemeData(
      color: palette.surface,
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

    bottomSheetTheme: BottomSheetThemeData(
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
    drawerTheme: DrawerThemeData(
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
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      focusedBorder: inputBorder(AppColors.primary, 1.4),
      errorBorder: inputBorder(AppColors.danger, 1.2),
      focusedErrorBorder: inputBorder(AppColors.danger, 1.4),
    ),

    // Unified pill button design matching the primary "Add item" button across the entire app.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textLight,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        textStyle: style(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textLight,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        textStyle: style(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        textStyle: style(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDeep,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        textStyle: labelStyle,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textBody,
        minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
        shape: const CircleBorder(),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 3,
      shape: RoundedRectangleBorder(borderRadius: pillRadius),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: pillRadius),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: AppColors.border),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryLight
              : AppColors.surfaceSecondary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryDeep
              : AppColors.textSecondary,
        ),
        textStyle: WidgetStatePropertyAll(labelStyle),
      ),
    ),

    // Chips – .nav-tabs pill look (cyan when selected)
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceSecondary,
      selectedColor: AppColors.primaryLight,
      disabledColor: AppColors.surfaceHover,
      checkmarkColor: AppColors.primaryDeep,
      side: BorderSide(color: AppColors.border),
      shape: const RoundedRectangleBorder(borderRadius: controlRadius),
      labelStyle: style(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      secondaryLabelStyle: style(
        color: AppColors.primaryDeep,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),

    // Tabs – cyan active indicator (.nav-tabs > li.active)
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primaryDeep,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: AppColors.border,
      labelStyle: labelStyle,
      unselectedLabelStyle: labelStyle.copyWith(fontWeight: FontWeight.w600),
      indicator: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: controlRadius,
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      overlayColor: WidgetStatePropertyAll(AppColors.surfaceHover),
    ),

    // Bottom navigation – soft cyan header surface matching top bar (no white)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.headerSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primary.withValues(alpha: 0.16),
      elevation: 0,
      height: 68,
      shadowColor: AppColors.border,
      indicatorShape: const RoundedRectangleBorder(borderRadius: pillRadius),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.primaryDeep
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
              ? AppColors.primaryDeep
              : AppColors.textMuted,
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.headerSurface,
      selectedItemColor: AppColors.primaryDeep,
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
      headingRowColor: WidgetStatePropertyAll(AppColors.surfaceSecondary),
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
      headingRowHeight: 48,
      dataRowMinHeight: 52,
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryLight;
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.surfaceHover;
        }
        return null;
      }),
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
      shape: RoundedRectangleBorder(
        borderRadius: controlRadius,
        side: BorderSide(color: AppColors.border),
      ),
      textStyle: style(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textBody,
      ),
    ),
    menuTheme: MenuThemeData(
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
            ? AppColors.surface
            : AppColors.textLight,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.surfaceHover,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.border,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
      side: BorderSide(color: AppColors.textLight, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.textLight,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceHover,
      circularTrackColor: AppColors.surfaceHover,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.primarySoft,
      thumbColor: AppColors.primary,
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceSecondary : AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: palette.isDark ? Border.all(color: palette.border) : null,
      ),
      textStyle: style(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.successBright,
      contentTextStyle: style(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: pillRadius),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.modal)),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x3822B8C4),
      selectionHandleColor: AppColors.primary,
    ),
  );
}
