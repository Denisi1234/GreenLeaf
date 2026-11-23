import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/common/market_page_header.dart';

/// Clean, native-style theme selector matching MorePage & AdvancedFeaturesPage.
class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final isSwahili = store.languageCode == 'sw';
    final currentThemeId = store.storePreferences.appTheme;
    final palette = AppThemePalette.of(context);
    String t(String en, String sw) => isSwahili ? sw : en;

    final systemPreset =
        AppThemePreset.presets.firstWhere((p) => p.isSystem);
    final lightPresets = AppThemePreset.presets
        .where((p) => !p.isSystem && !p.palette.isDark)
        .toList();
    final darkPresets = AppThemePreset.presets
        .where((p) => !p.isSystem && p.palette.isDark)
        .toList();

    Future<void> selectTheme(String id) async {
      if (id == currentThemeId) return;
      HapticFeedback.selectionClick();
      await store.setAppTheme(id);
    }

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: t('Theme', 'Mandhari'),
            showBackButton: true,
            centerTitle: false,
            titleSize: 20,
            titleWeight: FontWeight.w800,
            showBorder: true,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    children: [
                      _ThemeGroup(
                        label: t('AUTOMATIC', 'OTOMATIKI'),
                        palette: palette,
                        presets: [systemPreset],
                        currentThemeId: currentThemeId,
                        isSwahili: isSwahili,
                        onSelect: selectTheme,
                      ),
                      const SizedBox(height: 22),
                      _ThemeGroup(
                        label: t('DARK', 'GIZA'),
                        palette: palette,
                        presets: darkPresets,
                        currentThemeId: currentThemeId,
                        isSwahili: isSwahili,
                        onSelect: selectTheme,
                      ),
                      const SizedBox(height: 22),
                      _ThemeGroup(
                        label: t('LIGHT', 'MWANGA'),
                        palette: palette,
                        presets: lightPresets,
                        currentThemeId: currentThemeId,
                        isSwahili: isSwahili,
                        onSelect: selectTheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeGroup extends StatelessWidget {
  const _ThemeGroup({
    required this.label,
    required this.palette,
    required this.presets,
    required this.currentThemeId,
    required this.isSwahili,
    required this.onSelect,
  });

  final String label;
  final AppThemePalette palette;
  final List<AppThemePreset> presets;
  final String currentThemeId;
  final bool isSwahili;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: palette.textMuted,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: palette.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var i = 0; i < presets.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: palette.divider,
                    ),
                  _ThemeListRow(
                    preset: presets[i],
                    palette: palette,
                    selected: presets[i].id == currentThemeId,
                    isSwahili: isSwahili,
                    onTap: () => onSelect(presets[i].id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeListRow extends StatelessWidget {
  const _ThemeListRow({
    required this.preset,
    required this.palette,
    required this.selected,
    required this.isSwahili,
    required this.onTap,
  });

  final AppThemePreset preset;
  final AppThemePalette palette;
  final bool selected;
  final bool isSwahili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = isSwahili ? preset.nameSw : preset.nameEn;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              _ColorSwatchDot(preset: preset, borderColor: palette.border),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodyMain.copyWith(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: palette.ink,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: 21,
                  color: palette.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchDot extends StatelessWidget {
  const _ColorSwatchDot({
    required this.preset,
    required this.borderColor,
  });

  final AppThemePreset preset;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    if (preset.isSystem) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.5, 0.5],
            colors: [
              Color(0xFFFAFBFD),
              Color(0xFF0B141A),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: preset.palette.pageBackground,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: preset.palette.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
