import 'package:flutter/material.dart';

// Flatly palette from the OSPOS settings screen.
const settingsInk = Color(0xFF2C3E50);
const settingsBorder = Color(0xFFDCE4EC);
const settingsMuted = Color(0xFF617282);

ThemeData settingsTheme(ThemeData base) {
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3)),
  );
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(3)),
    borderSide: BorderSide(color: settingsBorder),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Lato',
    fontFamilyFallback: const ['Helvetica Neue', 'Helvetica', 'Arial'],
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: settingsInk,
      primary: settingsInk,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: settingsInk,
      onSurfaceVariant: settingsMuted,
      outline: settingsBorder,
    ),
    visualDensity: base.visualDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: settingsInk,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        borderSide: BorderSide(color: settingsInk),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: shape),
    ),
  );
}

class SettingsField extends StatelessWidget {
  const SettingsField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final heading = Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heading, const SizedBox(height: 6), child],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: Padding(
                  padding: const EdgeInsets.only(top: 9, right: 16),
                  child: heading,
                ),
              ),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

class SettingsSaveButton extends StatelessWidget {
  const SettingsSaveButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
