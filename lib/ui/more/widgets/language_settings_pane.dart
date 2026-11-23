import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../service/store_preferences.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_theme_palette.dart';
import '../settings_layout.dart';
import '../theme_selection_page.dart';

/// Clean, native Android/iOS Theme, Language, and Date/Time settings pane.
class LanguageSettingsPane extends StatefulWidget {
  const LanguageSettingsPane({super.key});

  @override
  State<LanguageSettingsPane> createState() => _LanguageSettingsPaneState();
}

class _LanguageSettingsPaneState extends State<LanguageSettingsPane> {
  String? _pending;
  bool _savingPreferences = false;
  int _preferenceRevision = 0;

  Future<void> _applyLanguage(PosLocalStore store, String code) async {
    if (code == store.languageCode || _pending != null) return;
    setState(() => _pending = code);
    try {
      await store.setLanguageCode(code);
      if (!mounted) return;
      showSettingsResult(
        context,
        settingsText(code, 'Language updated', 'Lugha imebadilishwa'),
      );
    } catch (_) {
      if (!mounted) return;
      showSettingsResult(
        context,
        settingsText(
          store.languageCode,
          'Could not change language',
          'Imeshindikana kubadilisha lugha',
        ),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  Future<void> _updatePreferences(
    PosLocalStore store,
    StorePreferences preferences,
    String message,
  ) async {
    if (_savingPreferences) return;
    setState(() => _savingPreferences = true);
    try {
      await store.setStorePreferences(preferences);
      if (!mounted) return;
      showSettingsResult(context, message);
    } catch (_) {
      if (!mounted) return;
      showSettingsResult(
        context,
        settingsText(
          store.languageCode,
          'Could not save preferences',
          'Imeshindikana kuhifadhi mipangilio',
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPreferences = false;
          _preferenceRevision++;
        });
      }
    }
  }

  String _formatSampleDate(String format, String lang) {
    final sample = DateTime(2026, 11, 13);
    try {
      return DateFormat(format, lang).format(sample);
    } catch (_) {
      return DateFormat(format).format(sample);
    }
  }

  InputDecoration _dropdownDecoration(AppThemePalette palette) {
    return InputDecoration(
      filled: true,
      fillColor: palette.pageBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final palette = AppThemePalette.of(context);
    final lang = store.languageCode;
    final isSwahili = lang == 'sw';
    String t(String en, String sw) => settingsText(lang, en, sw);
    final preferences = store.storePreferences;
    final activePreset = AppThemePreset.byId(preferences.appTheme);

    const languages = [
      ('sw', 'Kiswahili', 'Tanzania · Kenya'),
      ('en', 'English', 'International'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
      children: [
        // 1. Appearance (opens the same clean ThemeSelectionPage as the drawer)
        _SectionLabel(t('APPEARANCE', 'MUONEKANO'), palette),
        _NativeGroupCard(
          palette: palette,
          children: [
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ThemeSelectionPage(),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 22,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          t('Theme', 'Mandhari'),
                          style: AppTypography.bodyMain.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      Text(
                        isSwahili ? activePreset.nameSw : activePreset.nameEn,
                        style: AppTypography.caption.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: palette.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // 2. Language
        _SectionLabel(t('LANGUAGE', 'LUGHA'), palette),
        _NativeGroupCard(
          palette: palette,
          children: [
            for (var i = 0; i < languages.length; i++) ...[
              if (i > 0)
                Divider(height: 1, indent: 16, color: palette.divider),
              InkWell(
                onTap: () => _applyLanguage(store, languages[i].$1),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 54),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languages[i].$2,
                                style: AppTypography.bodyMain.copyWith(
                                  fontSize: 15,
                                  fontWeight: lang == languages[i].$1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: palette.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                languages[i].$1 == 'en'
                                    ? t('International', 'Kimataifa')
                                    : languages[i].$3,
                                style: AppTypography.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_pending == languages[i].$1)
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.primary,
                            ),
                          )
                        else if (lang == languages[i].$1)
                          Icon(
                            Icons.check_rounded,
                            size: 21,
                            color: palette.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 22),

        // 3. Date & Time
        _SectionLabel(t('DATE & TIME', 'TAREHE NA MUDA'), palette),
        _NativeGroupCard(
          palette: palette,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('Date format', 'Muundo wa tarehe'),
                    style: AppTypography.caption.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'date-${preferences.dateFormat}-$lang-$_preferenceRevision',
                    ),
                    initialValue: preferences.dateFormat,
                    isExpanded: true,
                    dropdownColor: palette.surface,
                    style: TextStyle(color: palette.ink, fontSize: 15),
                    decoration: _dropdownDecoration(palette),
                    items: [
                      for (final format in StorePreferences.dateFormatOptions)
                        DropdownMenuItem(
                          value: format,
                          child: Text(
                            _formatSampleDate(format, lang),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _savingPreferences
                        ? null
                        : (value) {
                            if (value == null) return;
                            _updatePreferences(
                              store,
                              preferences.copyWith(dateFormat: value),
                              t(
                                'Date format updated',
                                'Muundo wa tarehe umebadilishwa',
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t('Time format', 'Muundo wa muda'),
                    style: AppTypography.caption.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'time-${preferences.timeFormat}-$lang-$_preferenceRevision',
                    ),
                    initialValue: preferences.timeFormat,
                    isExpanded: true,
                    dropdownColor: palette.surface,
                    style: TextStyle(color: palette.ink, fontSize: 15),
                    decoration: _dropdownDecoration(palette),
                    items: [
                      DropdownMenuItem(
                        value: '12h',
                        child: Text(
                          t('12-hour (2:05 PM)', 'Saa 12 (2:05 PM)'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: '24h',
                        child: Text(
                          t('24-hour (14:05)', 'Saa 24 (14:05)'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: _savingPreferences
                        ? null
                        : (value) {
                            if (value == null) return;
                            _updatePreferences(
                              store,
                              preferences.copyWith(timeFormat: value),
                              t(
                                'Time format updated',
                                'Muundo wa muda umebadilishwa',
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.palette);
  final String text;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _NativeGroupCard extends StatelessWidget {
  const _NativeGroupCard({required this.palette, required this.children});
  final AppThemePalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}
