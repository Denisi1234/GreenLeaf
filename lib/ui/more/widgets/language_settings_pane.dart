import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../service/store_preferences.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_theme_palette.dart';
import '../settings_layout.dart';

/// Language and date/time preference pane.
class LanguageSettingsPane extends StatefulWidget {
  const LanguageSettingsPane({super.key});

  @override
  State<LanguageSettingsPane> createState() => _LanguageSettingsPaneState();
}

class _LanguageSettingsPaneState extends State<LanguageSettingsPane> {
  String? _pending;
  bool _savingPreferences = false;
  int _preferenceRevision = 0;

  Future<void> _apply(PosLocalStore store, String code) async {
    if (code == store.languageCode || _pending != null) return;
    setState(() => _pending = code);
    try {
      await store.setLanguageCode(code);
      if (!mounted) return;
      showSettingsResult(context,
          settingsText(code, 'Language updated', 'Lugha imebadilishwa'));
    } catch (_) {
      if (!mounted) return;
      showSettingsResult(
          context,
          settingsText(store.languageCode, 'Could not change language',
              'Imeshindikana kubadilisha lugha'),
          error: true);
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final preferences = store.storePreferences;
    const options = [
      ('sw', 'Kiswahili', 'Tanzania • Kenya'),
      ('en', 'English', 'International'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        SettingsCard(
          icon: Icons.palette_outlined,
          title: t('Appearance & theme', 'Muonekano na mandhari'),
          description: t(
            'Choose Automatic, Crisp Light, Cool Slate, Warm Paper, Forest Mint, Dark Shift, or True Black.',
            'Chagua Otomatiki, Mwanga Safi, Bluu Tulivu, Karatasi Laini, Kijani, Giza, au Nyeusi Halisi.',
          ),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final cols = constraints.maxWidth >= 520 ? 3 : 2;
                final itemWidth =
                    ((constraints.maxWidth - (spacing * (cols - 1))) / cols)
                        .floorToDouble();
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: AppThemePreset.presets.map((preset) {
                    final selected = preferences.appTheme == preset.id;
                    return _ThemePreviewCard(
                      width: itemWidth,
                      preset: preset,
                      selected: selected,
                      name: t(preset.nameEn, preset.nameSw),
                      subtitle: t(preset.subtitleEn, preset.subtitleSw),
                      onTap: _savingPreferences || selected
                          ? null
                          : () => _updatePreferences(
                                store,
                                preferences.copyWith(appTheme: preset.id),
                                t(
                                  'Theme changed to ${preset.nameEn}',
                                  'Mandhari yamebadilishwa kuwa ${preset.nameSw}',
                                ),
                              ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.translate_rounded,
          title: t('App language', 'Lugha ya programu'),
          description: t('Changes apply immediately across the app.',
              'Mabadiliko yanaanza kutumika mara moja.'),
          children: [
            for (final (code, name, region) in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ChoiceTile(
                  selected: lang == code,
                  busy: _pending == code,
                  title: name,
                  subtitle:
                      code == 'en' ? t('International', 'Kimataifa') : region,
                  onTap: () => _apply(store, code),
                ),
              ),
          ],
        ),
        SettingsCard(
          icon: Icons.schedule_outlined,
          title: t('Date & time display', 'Tarehe na muda'),
          description: t(
            'Used for new sales, receipts and reports.',
            'Hutumika kwa mauzo mapya, risiti na ripoti.',
          ),
          children: [
            SettingsField(
              label: t('Date format', 'Muundo wa tarehe'),
              hint: t('Example: Nov 13, 2026', 'Mfano: Nov 13, 2026'),
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                    'date-${preferences.dateFormat}-$lang-$_preferenceRevision'),
                initialValue: preferences.dateFormat,
                items: [
                  for (final format in StorePreferences.dateFormatOptions)
                    DropdownMenuItem(
                      value: format,
                      child: Text(_formatSampleDate(format, lang)),
                    ),
                ],
                onChanged: _savingPreferences
                    ? null
                    : (value) {
                        if (value == null) return;
                        _updatePreferences(
                          store,
                          preferences.copyWith(dateFormat: value),
                          t('Date format updated',
                              'Muundo wa tarehe umebadilishwa'),
                        );
                      },
              ),
            ),
            SettingsField(
              label: t('Time format', 'Muundo wa muda'),
              hint: t('Example: 2:05 PM or 14:05', 'Mfano: 2:05 PM au 14:05'),
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                    'time-${preferences.timeFormat}-$lang-$_preferenceRevision'),
                initialValue: preferences.timeFormat,
                items: [
                  DropdownMenuItem(
                    value: '12h',
                    child: Text(t('12-hour (2:05 PM)', 'Saa 12 (2:05 PM)')),
                  ),
                  DropdownMenuItem(
                    value: '24h',
                    child: Text(t('24-hour (14:05)', 'Saa 24 (14:05)')),
                  ),
                ],
                onChanged: _savingPreferences
                    ? null
                    : (value) {
                        if (value == null) return;
                        _updatePreferences(
                          store,
                          preferences.copyWith(timeFormat: value),
                          t('Time format updated',
                              'Muundo wa muda umebadilishwa'),
                        );
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.busy = false,
  });

  final bool selected;
  final bool busy;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.kpiSkyBg : AppColors.pageBackground,
      borderRadius: AppCorners.control,
      child: InkWell(
        borderRadius: AppCorners.control,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            borderRadius: AppCorners.control,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.kpiSky : AppColors.textMain,
                      ),
                    ),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.textLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.width,
    required this.preset,
    required this.selected,
    required this.name,
    required this.subtitle,
    this.onTap,
  });

  final double width;
  final AppThemePreset preset;
  final bool selected;
  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = preset.isSystem
        ? AppThemePalette.resolve(
            preset.id,
            MediaQuery.platformBrightnessOf(context),
          )
        : preset.palette;

    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.standard),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preset.isSystem)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 54,
                      child: Row(
                        children: const [
                          Expanded(
                            child: _MiniUiWireframe(
                              palette: AppThemePalette.light,
                              rounded: false,
                            ),
                          ),
                          Expanded(
                            child: _MiniUiWireframe(
                              palette: AppThemePalette.dark,
                              rounded: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _MiniUiWireframe(palette: p),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.primary,
                      )
                    else
                      Icon(
                        preset.icon,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniUiWireframe extends StatelessWidget {
  const _MiniUiWireframe({
    required this.palette,
    this.rounded = true,
  });

  final AppThemePalette palette;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: palette.pageBackground,
        borderRadius: rounded ? BorderRadius.circular(6) : null,
        border: rounded ? Border.all(color: palette.border, width: 0.8) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 12,
            color: palette.headerSurface,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 4,
              decoration: BoxDecoration(
                color: palette.ink.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(height: 0.8, color: palette.divider),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: palette.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: palette.ink.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FractionallySizedBox(
                            widthFactor: 0.65,
                            child: Container(
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: palette.textMuted.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 16,
                      height: 10,
                      decoration: BoxDecoration(
                        color: palette.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
