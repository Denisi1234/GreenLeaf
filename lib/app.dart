import 'package:flutter/material.dart';

import 'ui/shell/app_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const baseInk = Color(0xFF162033);
    final baseTextTheme = Typography.material2021().black.apply(
      bodyColor: baseInk,
      displayColor: baseInk,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GreenLeaf Market',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        textTheme: baseTextTheme.copyWith(
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
        scaffoldBackgroundColor: const Color(0xFFF8F7F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF90A86A),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFFDCE2EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFF2B6FF3), width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.1),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}
