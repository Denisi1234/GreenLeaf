import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../business_category_config.dart';

class AppColors {
  // Brand Colors (OSPOS Flatly-inspired theme)
  static const primary = Color(0xFF2C3E50);
  static const primaryDeep = Color(0xFF1A252F);
  static const primaryLight = Color(0xFFD6DBDF);

  // Neutral Colors
  static const ink = Color(0xFF2C3E50);
  static const textMain = Color(0xFF2C3E50);
  static const textMuted = Color(0xFF7B8A8B);
  static const textLight = Color(0xFF95A5A6);

  // Background & Surface
  static const pageBackground = Color(0xFFECF0F1);
  static const surface = Colors.white;
  static const surfaceSecondary = Color(0xFFF4F6F7);
  static const cardWhite = surface;
  static const surfaceSubtle = surfaceSecondary;

  // Borders & Dividers
  static const border = Color(0xFFDCE4EC);
  static const borderLight = Color(0xFFECF0F1);
  static const divider = Color(0xFFDCE4EC);

  // Feedback Colors
  static const success = Color(0xFF18BC9C);
  static const successLight = Color(0xFFE8F8F5);
  static const warning = Color(0xFFF39C12);
  static const warningLight = Color(0xFFFEF5E7);
  static const danger = Color(0xFFE74C3C);
  static const dangerLight = Color(0xFFFDEDEC);

  // Reports Page Specific Colors
  static const reportsInk = Color(0xFF2C3E50);
  static const reportsMuted = Color(0xFF7B8A8B);
  static const reportsBorder = Color(0xFFDCE4EC);
  static const reportsBlue = Color(0xFF3498DB);
  static const reportsGreen = Color(0xFF18BC9C);

  // Chart Colors
  static const chart1 = Color(0xFF2C3E50);
  static const chart2 = Color(0xFF18BC9C);
  static const chart3 = Color(0xFFF39C12);
  static const chart4 = Color(0xFF3498DB);
  static const chart5 = Color(0xFFE74C3C);

  // Legacy Aliases (for compatibility)
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

  static TextStyle h1 = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.8,
  );

  static TextStyle h2 = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.6,
  );

  static TextStyle h3 = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.4,
  );

  static TextStyle sectionHeader = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    letterSpacing: -0.1,
  );

  static TextStyle cardHeader = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
  );

  static TextStyle tableHeader = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static TextStyle bodyMain = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
  );

  static TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
  );

  static TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
  );

  static TextStyle label = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.2,
  );

  static TextStyle helperText = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  // Legacy Aliases (for compatibility)
  static TextStyle cardTitle = cardHeader;
  static TextStyle kpiValue = h2;
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

  // Semantic Spacing
  static const pagePadding = lg;
  static const cardPadding = lg;
  static const sectionSpacing = xxl;
  static const elementSpacing = md;
}

class AppRadius {
  static const sharp = 6.0;
  static const standard = 12.0;
  static const rounded = 16.0;
  static const extraRounded = 24.0;
  static const pill = 99.0;

  // Semantic Radius
  static const card = standard;
  static const button = standard;
  static const input = standard;
}

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> primary = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> none = [];
}

class AppDurations {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 400);
}
