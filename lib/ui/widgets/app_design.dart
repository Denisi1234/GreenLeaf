import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../business_category_config.dart';

class AppColors {
  // Brand Colors
  static const primary = Color(0xFF2563EB);
  static const primaryDeep = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFEFF6FF);

  // Neutral Colors (Greyscale)
  static const ink = Color(0xFF0F172A); // Slate 900
  static const textMain = Color(0xFF1E293B); // Slate 800
  static const textMuted = Color(0xFF64748B); // Slate 500
  static const textLight = Color(0xFF94A3B8); // Slate 400

  // Background & Surface
  static const pageBackground = Color(0xFFF8FAFC); // Slate 50
  static const surface = Colors.white;
  static const surfaceSecondary = Color(0xFFF1F5F9); // Slate 100

  // Borders & Dividers
  static const border = Color(0xFFE2E8F0); // Slate 200
  static const borderLight = Color(0xFFF1F5F9); // Slate 100
  static const divider = Color(0xFFE2E8F0); // Slate 200

  // Feedback Colors
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEF2F2);

  // Reports Page Specific Colors (to be consolidated later)
  static const reportsInk = Color(0xFF33363F);
  static const reportsMuted = Color(0xFF7A859C);
  static const reportsBorder = Color(0xFFE8EBF1);
  static const reportsBlue = Color(0xFF2B6FE8);
  static const reportsGreen = Color(0xFF30B05C);

  // Chart Colors (Standardized)
  static const chart1 = Color(0xFF2563EB);
  static const chart2 = Color(0xFF10B981);
  static const chart3 = Color(0xFFF59E0B);
  static const chart4 = Color(0xFF7C3AED);
  static const chart5 = Color(0xFFEC4899);

  // Legacy Aliases (for compatibility)
  static const mutedText = textMuted;
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
