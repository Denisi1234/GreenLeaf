import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/service/pos_local_store.dart';

import 'ui/auth/auth_wrapper.dart';
import 'ui/widgets/app_design.dart';
import 'ui/widgets/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    const baseInk = AppColors.ink;
    final baseTextTheme = Typography.material2021().black.apply(
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackMauzo',
      locale: Locale(store.languageCode),
      supportedLocales: const [
        Locale('sw'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeAnimationDuration: Duration.zero,
      theme: buildOsposTheme(appTextTheme),
      home: const AuthWrapper(),
    );
  }
}
