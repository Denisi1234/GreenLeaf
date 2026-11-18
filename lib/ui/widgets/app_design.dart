import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../business_category_config.dart';

/// Design tokens ported from the OSPOS signature theme with full light gray background.
class AppColors {
  // Brand / action colors (Cyan & Teal identity matching OpenSourcePOS #22B8C4 and brand #68CADD)
  static const primary = Color(0xFF22B8C4);
  static const primaryDeep = Color(0xFF1396A1);
  static const primaryBright = Color(0xFF68CADD);
  static const primaryLight = Color(0xFFE0F4F8);
  static const primarySoft = Color(0xFFF0F9FB);

  // Brand identity
  static const brand = Color(0xFF22B8C4);
  static const drawerHeader = Color(0xFF182735);

  // Neutral text scale (Crisp dark text on light gray surfaces)
  static const ink = Color(0xFF111827);
  static const textMain = Color(0xFF1F2937);
  static const textStrong = Color(0xFF000000);
  static const textBody = Color(0xFF374151);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  static const textPlaceholder = Color(0xFF9CA3AF);

  // Background & surface (Light blue-grey theme matching dashboard & more page)
  static const pageBackground = Color(0xFFEAF2F9); // Soft light-blue grey (#EAF2F9)
  static const surface = Colors.white;             // Clean crisp white surface
  static const surfaceSecondary = Color(0xFFF1F5F9); // Elevated subtle slate
  static const surfaceHover = Color(0xFFE2E8F0);     // Hover state
  static const cardWhite = surface;
  static const surfaceSubtle = surfaceSecondary;
  static const kpiSurface = Colors.white;

  // Borders & dividers (Clean light-blue borders matching dashboard)
  static const border = Color(0xFFD6E4F0);
  static const borderLight = Color(0xFFE2E8F0);
  static const borderInput = Color(0xFFCBD5E1);
  static const divider = Color(0xFFE2E8F0);

  // Feedback colors (Clear and high contrast)
  static const success = Color(0xFF10B981);
  static const successBright = Color(0xFF059669);
  static const successDeep = Color(0xFF047857);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningDeep = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerBright = Color(0xFFDC2626);
  static const dangerDeep = Color(0xFFB91C1C);
  static const dangerLight = Color(0xFFFEE2E2);
  static const dangerBorder = Color(0xFFFCA5A5);
  static const info = Color(0xFF22B8C4);
  static const infoLight = Color(0xFFE0F4F8);

  // KPI tones
  static const toneViolet = Color(0xFF10B981);
  static const toneIndigo = Color(0xFF22B8C4);
  static const toneTeal = Color(0xFF0284C7);
  static const toneLime = Color(0xFF16A34A);

  // Reports page specific colors
  static const reportsInk = ink;
  static const reportsMuted = textMuted;
  static const reportsBorder = border;
  static const reportsBlue = primary;
  static const reportsGreen = success;

  // Chart colors
  static const chart1 = Color(0xFF10B981);
  static const chart2 = Color(0xFFEF4444);
  static const chart3 = Color(0xFF22B8C4);
  static const chart4 = Color(0xFFF59E0B);
  static const chart5 = Color(0xFF6B7280);
  static const chartGrid = Color(0xFFD1D5DB);
  static const chartLabel = textMuted;

  // Overlays
  static const backdrop = Color(0x66000000);

  // Legacy aliases (for compatibility)
  static const mutedText = textMuted;
  static const textMedium = textMuted;
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
  static TextStyle h1 = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );

  static TextStyle h2 = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
    letterSpacing: -0.4,
  );

  // .dash-card-title
  static TextStyle h3 = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
    letterSpacing: -0.2,
  );

  static TextStyle sectionHeader = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
    letterSpacing: -0.1,
  );

  static TextStyle cardHeader = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
  );

  static TextStyle tableHeader = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.4,
  );

  static TextStyle bodyMain = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
  );

  static TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
  );

  static TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
  );

  // .dash-kpi-label
  static TextStyle label = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.1,
  );

  static TextStyle helperText = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  // .dash-kpi-value
  static TextStyle kpiValue = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textStrong,
    height: 1.15,
  );

  // .dash-kpi-foot
  static TextStyle kpiFoot = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  // Legacy aliases (for compatibility)
  static TextStyle cardTitle = cardHeader;
  static TextStyle caption = GoogleFonts.manrope(
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
  static const controlHeight = 42.0;
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
  static const button = standard;
  static const input = standard;
  static const iconBox = 11.0; // .dash-kpi-icon
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

  // .modern-hamburger-btn: 0 2px 6px rgba(200,30,30,.28)
  static List<BoxShadow> primary = [
    const BoxShadow(
      color: Color(0x4715803D),
      blurRadius: 6,
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
  /// `.dash-card` – white card, hairline border, soft lift.
  static BoxDecoration card({double radius = AppRadius.dashCard}) =>
      BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.medium,
      );

  /// `.module_item` – list/tile card.
  static BoxDecoration tile({double radius = AppRadius.tile}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      );

  /// `.dash-kpi-card` – lavender KPI surface.
  static BoxDecoration kpi({Color color = AppColors.kpiSurface}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.kpiCard),
      );

  /// `.dash-kpi-icon` – rounded tone square.
  static BoxDecoration kpiIcon(Color tone) => BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(AppRadius.iconBox),
      );

  /// `.nav-tabs > li.active > a` – teal active pill.
  static BoxDecoration activeTab() => BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.successBright, width: 2),
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
