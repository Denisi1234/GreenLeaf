import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../business_category_config.dart';
import 'app_theme_palette.dart';

/// Shared visual language for sales, management and reporting workspaces.
/// Driven dynamically by the active [AppThemePalette] (defaulting to
/// Graphite, with WhatsApp Dark, Crisp Light, Cool Slate, Warm Paper, Forest Mint,
/// Dark Shift, True Black, and Auto System selectable app-wide).
class AppColors {
  static AppThemePalette _palette = AppThemePalette.graphite;

  static AppThemePalette get activePalette => _palette;
  static bool get isDark => _palette.isDark;

  static void applyPalette(AppThemePalette palette) {
    _palette = palette;
  }

  // Brand / action colors
  static Color get primary => _palette.primary;
  static Color get primaryDeep => _palette.primaryDeep;
  static Color get completionAction =>
      _palette.id == 'graphite' ? successDeep : primary;
  static const primaryBright = Color(0xFF68CADD);
  static Color get primaryLight => _palette.primaryLight;
  static Color get primarySoft => _palette.surface;

  // Brand identity
  static const brand = Color(0xFF22B8C4);
  static const drawerHeader = Color(0xFF182735);

  // Neutral text scale (Adapts automatically across light & dark themes)
  static Color get ink => _palette.ink;
  static Color get textMain => _palette.ink;
  static Color get textStrong => _palette.ink;
  static Color get textBody => _palette.textBody;
  static Color get textSecondary => _palette.textBody;
  static Color get textMuted => _palette.textMuted;
  static Color get textLight => _palette.textMuted;
  static Color get textPlaceholder => _palette.textMuted;

  // Neutral low-glare work surfaces
  static Color get pageBackground => _palette.pageBackground;
  static Color get surface => _palette.surface;
  static Color get surfaceSecondary => _palette.surfaceSecondary;
  static Color get surfaceHover => _palette.surfaceSecondary;
  static Color get cardWhite => _palette.surface;
  static Color get surfaceSubtle => _palette.surfaceSecondary;
  static Color get kpiSurface => _palette.surface;
  static Color get headerSurface => _palette.headerSurface;
  static Color get sectionSurface => _palette.surface;

  // Borders & dividers
  static Color get border => _palette.border;
  static Color get borderLight => _palette.divider;
  static Color get borderInput => _palette.border;
  static Color get divider => _palette.divider;

  // Feedback colors (Clear and high contrast across light & dark themes)
  static const success = Color(0xFF10B981);
  static const successBright = Color(0xFF059669);
  static Color get successDeep =>
      _palette.isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
  static Color get successLight =>
      _palette.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static Color get warningDeep =>
      _palette.isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color get warningLight =>
      _palette.isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerBright = Color(0xFFDC2626);
  static Color get dangerDeep =>
      _palette.isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
  static Color get dangerLight =>
      _palette.isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
  static const dangerBorder = Color(0xFFFCA5A5);
  static const info = Color(0xFF22B8C4);
  static Color get infoLight =>
      _palette.isDark ? const Color(0xFF133A42) : const Color(0xFFE0F4F8);

  // KPI surfaces & restrained accents
  static Color get kpiRoseBg => surface;
  static Color get kpiRose =>
      _palette.isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D);
  static Color get kpiSkyBg => surface;
  static Color get kpiSky => primaryDeep;
  static Color get kpiAmberBg => surface;
  static Color get kpiAmber =>
      _palette.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
  static Color get kpiDangerBg => surface;
  static Color get kpiDanger => dangerDeep;
  static Color get kpiVioletBg => surface;
  static Color get kpiViolet => ink;
  static Color get kpiSuccessBg => surface;
  static Color get kpiSuccess => successDeep;
  static Color get kpiNeutralBg => surfaceSecondary;
  static Color get kpiNeutral => textMuted;

  // KPI tones
  static Color get toneViolet => kpiViolet;
  static Color get toneIndigo => kpiSky;
  static Color get toneTeal => primary;
  static Color get toneLime => kpiSuccess;
  static Color get toneRose => kpiRose;
  static Color get toneAmber => kpiAmber;

  // Reports page specific colors
  static Color get reportsInk => ink;
  static Color get reportsMuted => textMuted;
  static Color get reportsBorder => border;
  static Color get reportsBlue => primary;
  static const reportsGreen = success;

  // Chart colors
  static const chart1 = Color(0xFF10B981);
  static const chart2 = Color(0xFFEF4444);
  static const chart3 = Color(0xFF22B8C4);
  static const chart4 = Color(0xFFF59E0B);
  static const chart5 = Color(0xFF6B7280);
  static Color get chartGrid => divider;
  static Color get chartLabel => textMuted;

  // Overlays
  static const backdrop = Color(0x66000000);

  // Legacy aliases (for compatibility)
  static Color get mutedText => textMuted;
  static Color get textMedium => textMuted;
  static const green = success;

  static Color categoryPrimary(BusinessCategory category) =>
      BusinessCategoryConfig.forCategory(category).primaryColor;
  static Color categoryPrimaryDeep(BusinessCategory category) =>
      BusinessCategoryConfig.forCategory(category).primaryDeepColor;
  static Color categoryPrimaryLight(BusinessCategory category) =>
      BusinessCategoryConfig.forCategory(category).primaryLightColor;
  static Color categoryAccent(BusinessCategory category) =>
      BusinessCategoryConfig.forCategory(category).accentColor;
}

class AppTypography {
  // Font Family: Manrope (Professional, Modern, Readable)
  static const String fontFamily = 'Manrope';

  // .dash-page-title / #page_title
  static TextStyle get h1 => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textStrong,
        letterSpacing: -0.4,
      );

  // .dash-card-title
  static TextStyle get h3 => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textStrong,
        letterSpacing: -0.2,
      );

  static TextStyle get sectionHeader => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textStrong,
        letterSpacing: -0.1,
      );

  static TextStyle get cardHeader => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textStrong,
      );

  static TextStyle get tableHeader => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      );

  static TextStyle get bodyMain => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textMain,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textBody,
      );

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textBody,
      );

  // .dash-kpi-label
  static TextStyle get label => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.1,
      );

  static TextStyle get helperText => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textLight,
      );

  // .dash-kpi-value
  static TextStyle get kpiValue => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: -0.4,
        height: 1.15,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // .dash-kpi-foot
  static TextStyle get kpiFoot => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  // Legacy aliases (for compatibility)
  static TextStyle get cardTitle => cardHeader;
  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );
}

class AppSpacing {
  static const zero = 0.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const massive = 48.0;

  // Semantic spacing
  static const pagePadding = xl; // .ospos-pos-dashboard padding: 20px
  static const cardPadding = xl; // .dash-card padding: 20px 22px
  static const kpiGap = 14.0; // .dash-kpi-grid gap
  static const sectionSpacing = 22.0;
  static const elementSpacing = md;

  // Touch targets (mobile responsiveness audit)
  static const touchTarget = 44.0;
  static const controlHeight = 44.0;
}

class AppRadius {
  static const sharp = 8.0; // footer links / small chips
  static const standard = 10.0; // inputs, tabs, buttons, selects
  static const modal = 12.0; // .modal-content
  static const tile = 14.0; // .module_item
  static const rounded = 16.0; // .dash-kpi-card
  static const extraRounded = 18.0; // .dash-card
  static const pill = 99.0;

  // Semantic radius
  static const card = tile;
  static const dashCard = extraRounded;
  static const kpiCard = rounded;
  static const button = pill;
  static const input = 0.0; // sharp square inputs app-wide
  static const iconBox = 11.0; // .dash-kpi-icon
}

/// Constant shapes shared by forms, action sheets and management controls.
class AppCorners {
  static const control = BorderRadius.all(Radius.circular(AppRadius.standard));
  static const input = BorderRadius.zero;
}

class AppShadows {
  // .module_item: 0 4px 14px rgba(0,0,0,.05)
  static List<BoxShadow> soft = [
    const BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  // .dash-card: 0 8px 24px rgba(0,0,0,.05)
  static List<BoxShadow> medium = [
    const BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // Primary brand glow shadow (Cyan #22B8C4)
  static List<BoxShadow> primary = [
    const BoxShadow(
      color: Color(0x4022B8C4),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // drawer: 6px 0 30px rgba(0,0,0,.25)
  static List<BoxShadow> drawer = [
    const BoxShadow(
      color: Color(0x40000000),
      blurRadius: 30,
      offset: Offset(6, 0),
    ),
  ];

  static List<BoxShadow> none = [];
}

class AppDecorations {
  /// `.dash-card` – low-glare card, crisp daylight-proof border, soft lift.
  static BoxDecoration card({double radius = AppRadius.dashCard}) =>
      BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.medium,
      );

  /// `.module_item` – list/tile card.
  static BoxDecoration tile({double radius = AppRadius.tile}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      );

  /// `.dash-kpi-card` – crisp KPI tile with daylight-proof border & soft lift.
  static BoxDecoration kpi({Color? color}) => BoxDecoration(
        color: color ?? AppColors.kpiSurface,
        borderRadius: BorderRadius.circular(AppRadius.kpiCard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      );

  /// `.dash-kpi-icon` – rounded tone square.
  static BoxDecoration kpiIcon(Color tone) => BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(AppRadius.iconBox),
      );

  /// `.nav-tabs > li.active > a` – cyan active pill.
  static BoxDecoration activeTab() => BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.primary, width: 1.5),
      );

  /// `.nav-tabs > li > a` – idle tab pill.
  static BoxDecoration idleTab() => BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
      );
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}
