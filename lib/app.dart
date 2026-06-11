import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/service/pos_local_store.dart';
import 'package:track_mauzo/ui/widgets/capability_provider.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.manrope().fontFamily,
        textTheme: appTextTheme,
        primaryTextTheme: appTextTheme,
        scaffoldBackgroundColor: AppColors.pageBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondary: AppColors.green,
          outline: AppColors.border,
          outlineVariant: AppColors.divider,
          surfaceTint: Colors.transparent,
          onSurface: AppColors.ink,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurfaceVariant: AppColors.mutedText,
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF475569),
          size: 22,
        ),
        primaryIconTheme: const IconThemeData(
          color: AppColors.ink,
          size: 22,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.pageBackground,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF475569)),
          titleTextStyle: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
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
          hintStyle: TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w500,
          ),
          prefixIconColor: AppColors.mutedText,
          suffixIconColor: AppColors.mutedText,
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
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sharp)),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: Color(0x332563EB),
          selectionHandleColor: AppColors.primary,
        ),
      ),
      home: Consumer<PosLocalStore>(
        builder: (context, store, child) {
          return CapabilityProvider(
            capabilities: store.activeCapabilities,
            child: const AppShell(),
          );
        },
      ),
    );
  }
}
