import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/shell/app_shell.dart';
import 'ui/widgets/app_design.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const baseInk = AppColors.ink;
    final baseTextTheme = Typography.material2021().black.apply(
          bodyColor: baseInk,
          displayColor: baseInk,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GreenLeaf Market',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(letterSpacing: 0),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(letterSpacing: 0),
          bodySmall: baseTextTheme.bodySmall?.copyWith(letterSpacing: 0),
          titleLarge: baseTextTheme.titleLarge?.copyWith(letterSpacing: 0),
          titleMedium: baseTextTheme.titleMedium?.copyWith(letterSpacing: 0),
          titleSmall: baseTextTheme.titleSmall?.copyWith(letterSpacing: 0),
          labelLarge: baseTextTheme.labelLarge?.copyWith(letterSpacing: 0),
          labelMedium: baseTextTheme.labelMedium?.copyWith(letterSpacing: 0),
          labelSmall: baseTextTheme.labelSmall?.copyWith(letterSpacing: 0),
        ),
        scaffoldBackgroundColor: AppColors.pageBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF90A86A),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
            borderSide: BorderSide(color: AppColors.primary, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
            borderSide: BorderSide(color: AppColors.danger, width: 1.1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
            borderSide: BorderSide(color: AppColors.danger, width: 1.1),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}
