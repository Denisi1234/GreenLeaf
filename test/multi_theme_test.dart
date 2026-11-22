import 'package:aza_pos/app.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/service/store_preferences.dart';
import 'package:aza_pos/ui/business_category_config.dart';
import 'package:aza_pos/ui/widgets/app_design.dart';
import 'package:aza_pos/ui/widgets/app_theme_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ThemeTestStore extends PosLocalStore {
  StorePreferences _prefs = const StorePreferences();

  @override
  bool get isInitialized => true;

  @override
  String get languageCode => 'en';

  @override
  StorePreferences get storePreferences => _prefs;

  @override
  Future<void> setStorePreferences(StorePreferences preferences) async {
    _prefs = preferences;
    notifyListeners();
  }
}

void main() {
  tearDown(() {
    AppColors.applyPalette(AppThemePalette.light);
  });

  test('StorePreferences persists all valid appTheme options safely', () {
    const defaults = StorePreferences();
    expect(defaults.appTheme, 'light');

    for (final themeId in [
      'system',
      'light',
      'slate',
      'warm',
      'emerald',
      'dark',
      'oled',
    ]) {
      final prefs = defaults.copyWith(appTheme: themeId);
      final restored = StorePreferences.fromJson(prefs.toJson());
      expect(restored.appTheme, themeId);
    }

    final unknown = StorePreferences.fromJson(const {'appTheme': 'neon'});
    expect(unknown.appTheme, 'light');
  });

  test('AppThemePalette.resolve maps system theme to platform brightness', () {
    expect(
      AppThemePalette.resolve('system', Brightness.dark),
      AppThemePalette.dark,
    );
    expect(
      AppThemePalette.resolve('system', Brightness.light),
      AppThemePalette.light,
    );
  });

  testWidgets(
      'App switches dynamically across all presets and syncs system chrome',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _ThemeTestStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<PosLocalStore>.value(
        value: store,
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    for (final preset in AppThemePreset.presets) {
      await store.setStorePreferences(
        store.storePreferences.copyWith(appTheme: preset.id),
      );
      await tester.pumpAndSettle();

      final expected = preset.isSystem
          ? AppThemePalette.resolve(
              preset.id,
              tester.binding.platformDispatcher.platformBrightness,
            )
          : preset.palette;

      expect(AppColors.isDark, expected.isDark);
      expect(AppColors.pageBackground, expected.pageBackground);
      expect(AppColors.surface, expected.surface);
      expect(AppColors.ink, expected.ink);
      expect(AppTypography.h1.color, expected.ink);
      expect(
        BusinessCategoryConfig.forCategory(BusinessCategory.retail)
            .primaryColor,
        AppColors.primary,
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, expected.brightness);
      expect(
        materialApp.theme?.scaffoldBackgroundColor,
        expected.pageBackground,
      );

      final region = tester
          .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first;
      expect(
        region.value.statusBarIconBrightness,
        expected.isDark ? Brightness.light : Brightness.dark,
      );
      expect(region.value.systemNavigationBarColor, expected.headerSurface);
    }
  });
}
