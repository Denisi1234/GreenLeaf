import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aza_pos/service/pos_local_store.dart';

import 'ui/auth/auth_wrapper.dart';
import 'ui/widgets/app_design.dart';
import 'ui/widgets/app_theme.dart';
import 'ui/widgets/app_theme_palette.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final Map<String, ThemeData> _cachedThemes = {};

  static ThemeData _getTheme(String themeId) {
    final palette = AppThemePalette.forId(themeId);
    AppColors.applyPalette(palette);
    final existing = _cachedThemes[palette.id];
    if (existing != null) return existing;
    final baseInk = palette.ink;
    final baseTextTheme = (palette.isDark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(
          bodyColor: baseInk,
          displayColor: baseInk,
        );
    final appTextTheme = GoogleFonts.manropeTextTheme(baseTextTheme).copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        letterSpacing: -0.6,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        letterSpacing: -0.5,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        letterSpacing: -0.4,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        letterSpacing: -0.35,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        letterSpacing: -0.3,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        letterSpacing: -0.25,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        letterSpacing: -0.2,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        letterSpacing: -0.15,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        letterSpacing: -0.1,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        letterSpacing: 0,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        letterSpacing: 0,
        height: 1.45,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        letterSpacing: 0,
        height: 1.35,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        letterSpacing: 0.05,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        letterSpacing: 0.05,
        fontWeight: FontWeight.w600,
      ),
    );
    final theme = buildOsposTheme(appTextTheme, themeId: palette.id);
    _cachedThemes[palette.id] = theme;
    return theme;
  }

  @override
  Widget build(BuildContext context) {
    final languageCode =
        context.select<PosLocalStore, String>((s) => s.languageCode);
    final appTheme = context
        .select<PosLocalStore, String>((s) => s.storePreferences.appTheme);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final palette = AppThemePalette.resolve(appTheme, platformBrightness);
    AppColors.applyPalette(palette);
    Intl.defaultLocale = languageCode;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          palette.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: palette.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: palette.headerSurface,
      systemNavigationBarIconBrightness:
          palette.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: palette.border,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aza POS',
      locale: Locale(languageCode),
      supportedLocales: const [
        Locale('en'),
        Locale('sw'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeAnimationDuration: const Duration(milliseconds: 180),
      theme: _getTheme(palette.id),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final clampedScaler = media.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: MediaQuery(
            data: media.copyWith(textScaler: clampedScaler),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const AuthWrapper(),
    );
  }
}
