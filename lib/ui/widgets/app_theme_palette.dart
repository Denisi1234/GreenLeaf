import 'package:flutter/material.dart';

class AppThemePreset {
  const AppThemePreset({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.subtitleEn,
    required this.subtitleSw,
    required this.icon,
    required this.palette,
    this.isSystem = false,
  });

  final String id;
  final String nameEn;
  final String nameSw;
  final String subtitleEn;
  final String subtitleSw;
  final IconData icon;
  final AppThemePalette palette;
  final bool isSystem;

  static const presets = <AppThemePreset>[
    AppThemePreset(
      id: 'graphite',
      nameEn: 'Graphite',
      nameSw: 'Grafaiti',
      subtitleEn: 'Clean neutrals with charcoal actions',
      subtitleSw: 'Rangi tulivu na vitufe vyeusi',
      icon: Icons.contrast_rounded,
      palette: AppThemePalette.graphite,
    ),
    AppThemePreset(
      id: 'whatsapp_dark',
      nameEn: 'WhatsApp Dark',
      nameSw: 'Giza (WhatsApp)',
      subtitleEn: 'Comfortable dark mode',
      subtitleSw: 'Giza laini',
      icon: Icons.dark_mode_rounded,
      palette: AppThemePalette.whatsappDark,
    ),
    AppThemePreset(
      id: 'system',
      nameEn: 'Auto (System)',
      nameSw: 'Otomatiki',
      subtitleEn: 'Follows device day & night mode',
      subtitleSw: 'Hufuata mwanga wa simu yako',
      icon: Icons.brightness_auto_outlined,
      palette: AppThemePalette.light,
      isSystem: true,
    ),
    AppThemePreset(
      id: 'light',
      nameEn: 'Crisp Light',
      nameSw: 'Mwanga Safi',
      subtitleEn: 'Soft off-white cards, low glare',
      subtitleSw: 'Kadi nyeupe laini, mwanga tulivu',
      icon: Icons.light_mode_outlined,
      palette: AppThemePalette.light,
    ),
    AppThemePreset(
      id: 'slate',
      nameEn: 'Cool Slate',
      nameSw: 'Bluu Tulivu',
      subtitleEn: 'Calm blue-slate for long shifts',
      subtitleSw: 'Rangi tulivu ya bluu kwa zamu ndefu',
      icon: Icons.water_drop_outlined,
      palette: AppThemePalette.slate,
    ),
    AppThemePreset(
      id: 'warm',
      nameEn: 'Warm Paper',
      nameSw: 'Karatasi Laini',
      subtitleEn: 'Low blue-light ivory finish',
      subtitleSw: 'Mwanga laini usiochosha macho',
      icon: Icons.wb_sunny_outlined,
      palette: AppThemePalette.warm,
    ),
    AppThemePreset(
      id: 'emerald',
      nameEn: 'Forest Mint',
      nameSw: 'Kijani Tulivu',
      subtitleEn: 'Fresh sage & botanical clarity',
      subtitleSw: 'Kijani safi na mwonekano tulivu',
      icon: Icons.eco_outlined,
      palette: AppThemePalette.emerald,
    ),
    AppThemePreset(
      id: 'dark',
      nameEn: 'Dark Shift',
      nameSw: 'Giza (Usiku)',
      subtitleEn: 'Deep charcoal for evening shifts',
      subtitleSw: 'Giza tulivu kwa zamu za usiku',
      icon: Icons.dark_mode_outlined,
      palette: AppThemePalette.dark,
    ),
    AppThemePreset(
      id: 'oled',
      nameEn: 'True Black',
      nameSw: 'Nyeusi Halisi',
      subtitleEn: 'Pure AMOLED black & battery saver',
      subtitleSw: 'Nyeusi halisi ya kuokoa chaji',
      icon: Icons.nights_stay_outlined,
      palette: AppThemePalette.oled,
    ),
  ];

  static AppThemePreset byId(String id) {
    final normalized = id.trim().toLowerCase();
    for (final preset in presets) {
      if (preset.id == normalized) return preset;
    }
    return presets.first;
  }
}

class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.id,
    required this.brightness,
    required this.primary,
    required this.primaryDeep,
    required this.primaryLight,
    required this.pageBackground,
    required this.surface,
    required this.surfaceSecondary,
    required this.headerSurface,
    required this.border,
    required this.divider,
    required this.ink,
    required this.textBody,
    required this.textMuted,
  });

  final String id;
  final Brightness brightness;
  final Color primary;
  final Color primaryDeep;
  final Color primaryLight;
  final Color pageBackground;
  final Color surface;
  final Color surfaceSecondary;
  final Color headerSurface;
  final Color border;
  final Color divider;
  final Color ink;
  final Color textBody;
  final Color textMuted;

  bool get isDark => brightness == Brightness.dark;

  static const graphite = AppThemePalette(
    id: 'graphite',
    brightness: Brightness.light,
    primary: Color(0xFF171717),
    primaryDeep: Color(0xFF111111),
    primaryLight: Color(0xFFE8EAED),
    pageBackground: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF0F2F4),
    headerSurface: Color(0xFFFFFFFF),
    border: Color(0xFFD9DDE3),
    divider: Color(0xFFE8EBEF),
    ink: Color(0xFF111827),
    textBody: Color(0xFF374151),
    textMuted: Color(0xFF606975),
  );

  static const whatsappDark = AppThemePalette(
    id: 'whatsapp_dark',
    brightness: Brightness.dark,
    primary: Color(0xFF00A884),
    primaryDeep: Color(0xFF25D366),
    primaryLight: Color(0xFF103529),
    pageBackground: Color(0xFF0B141A),
    surface: Color(0xFF111B21),
    surfaceSecondary: Color(0xFF202C33),
    headerSurface: Color(0xFF1F2C34),
    border: Color(0xFF2A3942),
    divider: Color(0xFF222E35),
    ink: Color(0xFFE9EDEF),
    textBody: Color(0xFFD1D7DB),
    textMuted: Color(0xFF8696A0),
  );

  static const light = AppThemePalette(
    id: 'light',
    brightness: Brightness.light,
    primary: Color(0xFF087F8C),
    primaryDeep: Color(0xFF086570),
    primaryLight: Color(0xFFE5F3F4),
    pageBackground: Color(0xFFF1F3F6),
    surface: Color(0xFFFAFBFD),
    surfaceSecondary: Color(0xFFECEFF3),
    headerSurface: Color(0xFFF6F8FA),
    border: Color(0xFFD8DFE6),
    divider: Color(0xFFE2E7EC),
    ink: Color(0xFF111827),
    textBody: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
  );

  static const slate = AppThemePalette(
    id: 'slate',
    brightness: Brightness.light,
    primary: Color(0xFF087F8C),
    primaryDeep: Color(0xFF086570),
    primaryLight: Color(0xFFD6EAF0),
    pageBackground: Color(0xFFD0E2EE),
    surface: Color(0xFFE8F3F8),
    surfaceSecondary: Color(0xFFD7E8F2),
    headerSurface: Color(0xFFD8EAF3),
    border: Color(0xFFB8CFE0),
    divider: Color(0xFFC0D6E5),
    ink: Color(0xFF111827),
    textBody: Color(0xFF334155),
    textMuted: Color(0xFF52667A),
  );

  static const warm = AppThemePalette(
    id: 'warm',
    brightness: Brightness.light,
    primary: Color(0xFF0D7A6F),
    primaryDeep: Color(0xFF095E55),
    primaryLight: Color(0xFFE4F2EF),
    pageBackground: Color(0xFFF3EFE6),
    surface: Color(0xFFFCFBF8),
    surfaceSecondary: Color(0xFFEBE5D9),
    headerSurface: Color(0xFFF7F4EC),
    border: Color(0xFFDDD6C7),
    divider: Color(0xFFE5DFD2),
    ink: Color(0xFF1C1917),
    textBody: Color(0xFF44403C),
    textMuted: Color(0xFF78716C),
  );

  static const emerald = AppThemePalette(
    id: 'emerald',
    brightness: Brightness.light,
    primary: Color(0xFF047857),
    primaryDeep: Color(0xFF065F46),
    primaryLight: Color(0xFFDCEEE6),
    pageBackground: Color(0xFFEFF4F1),
    surface: Color(0xFFF9FCFA),
    surfaceSecondary: Color(0xFFE5EEE9),
    headerSurface: Color(0xFFF4F8F6),
    border: Color(0xFFCFE0D7),
    divider: Color(0xFFDCE9E2),
    ink: Color(0xFF0F1F18),
    textBody: Color(0xFF2D473B),
    textMuted: Color(0xFF5B7568),
  );

  static const dark = AppThemePalette(
    id: 'dark',
    brightness: Brightness.dark,
    primary: Color(0xFF22B8C4),
    primaryDeep: Color(0xFF38D0DC),
    primaryLight: Color(0xFF133A42),
    pageBackground: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceSecondary: Color(0xFF263449),
    headerSurface: Color(0xFF162032),
    border: Color(0xFF334155),
    divider: Color(0xFF2B394F),
    ink: Color(0xFFF1F5F9),
    textBody: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
  );

  static const oled = AppThemePalette(
    id: 'oled',
    brightness: Brightness.dark,
    primary: Color(0xFF22B8C4),
    primaryDeep: Color(0xFF38D0DC),
    primaryLight: Color(0xFF103038),
    pageBackground: Color(0xFF000000),
    surface: Color(0xFF12161E),
    surfaceSecondary: Color(0xFF1B222E),
    headerSurface: Color(0xFF0A0D12),
    border: Color(0xFF263042),
    divider: Color(0xFF1E2634),
    ink: Color(0xFFF8FAFC),
    textBody: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
  );

  static AppThemePalette resolve(String id, Brightness platformBrightness) {
    final normalized = id.trim().toLowerCase();
    if (normalized == 'system') {
      return platformBrightness == Brightness.dark ? whatsappDark : light;
    }
    return AppThemePreset.byId(normalized).palette;
  }

  static AppThemePalette forId(String id) => resolve(id, Brightness.dark);

  static AppThemePalette of(BuildContext context) {
    return Theme.of(context).extension<AppThemePalette>() ?? graphite;
  }

  @override
  AppThemePalette copyWith({
    String? id,
    Brightness? brightness,
    Color? primary,
    Color? primaryDeep,
    Color? primaryLight,
    Color? pageBackground,
    Color? surface,
    Color? surfaceSecondary,
    Color? headerSurface,
    Color? border,
    Color? divider,
    Color? ink,
    Color? textBody,
    Color? textMuted,
  }) {
    return AppThemePalette(
      id: id ?? this.id,
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primaryLight: primaryLight ?? this.primaryLight,
      pageBackground: pageBackground ?? this.pageBackground,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      headerSurface: headerSurface ?? this.headerSurface,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      ink: ink ?? this.ink,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppThemePalette lerp(ThemeExtension<AppThemePalette>? other, double t) {
    if (other is! AppThemePalette) return this;
    return AppThemePalette(
      id: t < 0.5 ? id : other.id,
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t) ?? primaryDeep,
      primaryLight:
          Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      pageBackground:
          Color.lerp(pageBackground, other.pageBackground, t) ?? pageBackground,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ??
              surfaceSecondary,
      headerSurface:
          Color.lerp(headerSurface, other.headerSurface, t) ?? headerSurface,
      border: Color.lerp(border, other.border, t) ?? border,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      textBody: Color.lerp(textBody, other.textBody, t) ?? textBody,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
}
