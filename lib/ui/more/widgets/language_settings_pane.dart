import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../service/store_preferences.dart';
import '../../widgets/app_design.dart';
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
                  subtitle: code == 'en' ? t('International', 'Kimataifa') : region,
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
      color: selected ? AppColors.successLight : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: selected ? AppColors.successBright : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
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
                        color: selected
                            ? AppColors.successDeep
                            : AppColors.textMain,
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
                  color:
                      selected ? AppColors.successBright : AppColors.textLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
