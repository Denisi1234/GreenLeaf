import 'package:aza_pos/app.dart';
import 'package:aza_pos/service/app_update_service.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/service/store_preferences.dart';
import 'package:aza_pos/ui/auth/auth_shell.dart';
import 'package:aza_pos/ui/auth/login_page.dart';
import 'package:aza_pos/ui/auth/onboarding_page.dart';
import 'package:aza_pos/ui/business_category_config.dart';
import 'package:aza_pos/ui/shell/app_shell.dart';
import 'package:aza_pos/ui/widgets/app_design.dart';
import 'package:aza_pos/ui/widgets/app_theme_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'support/ui_test_fonts.dart';
import 'package:provider/provider.dart';

class _ThemeTestStore extends PosLocalStore {
  StorePreferences _prefs = const StorePreferences();
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;

  @override
  bool get isInitialized => true;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  @override
  String get languageCode => 'en';

  @override
  StorePreferences get storePreferences => _prefs;

  void setAuthState({bool? isLoggedIn, bool? hasCompletedOnboarding}) {
    if (isLoggedIn != null) _isLoggedIn = isLoggedIn;
    if (hasCompletedOnboarding != null) {
      _hasCompletedOnboarding = hasCompletedOnboarding;
    }
    notifyListeners();
  }

  @override
  Future<void> setStorePreferences(StorePreferences preferences) async {
    _prefs = preferences;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting();
    await configureUiTestFonts();
  });
  tearDown(() {
    AppColors.applyPalette(AppThemePalette.graphite);
    AppUpdateService.instance.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('trackmauzo/app_update'),
      null,
    );
  });

  test('StorePreferences persists all valid appTheme options safely', () {
    const defaults = StorePreferences();
    expect(defaults.appTheme, 'graphite');
    expect(
      defaults.themeDefaultVersion,
      StorePreferences.currentThemeDefaultVersion,
    );

    for (final themeId in [
      'graphite',
      'whatsapp_dark',
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
      expect(
        restored.themeDefaultVersion,
        StorePreferences.currentThemeDefaultVersion,
      );
    }

    final unknown = StorePreferences.fromJson(const {
      'appTheme': 'neon',
      'themeDefaultVersion': StorePreferences.currentThemeDefaultVersion,
    });
    expect(unknown.appTheme, 'graphite');
    expect(StorePreferences.fromJson({}).appTheme, 'graphite');
  });

  test(
      'StorePreferences preserves explicit themes from older saved preferences',
      () {
    final legacyNoVersion = StorePreferences.fromJson(const {
      'appTheme': 'light',
    });
    expect(legacyNoVersion.appTheme, 'light');
    expect(
      legacyNoVersion.themeDefaultVersion,
      StorePreferences.currentThemeDefaultVersion,
    );

    final legacyZeroVersion = StorePreferences.fromJson(const {
      'appTheme': 'slate',
      'themeDefaultVersion': 0,
    });
    expect(legacyZeroVersion.appTheme, 'slate');
    expect(
      legacyZeroVersion.themeDefaultVersion,
      StorePreferences.currentThemeDefaultVersion,
    );

    final userChoiceAfterMigration = StorePreferences.fromJson(const {
      'appTheme': 'light',
      'themeDefaultVersion': StorePreferences.currentThemeDefaultVersion,
    });
    expect(userChoiceAfterMigration.appTheme, 'light');
  });

  test('AppUpdateService handles silent update states and downloaded callback',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('trackmauzo/app_update');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    final service = AppUpdateService.instance;
    service.allowPlatformOverride = true;

    String mockResponse = 'up_to_date';
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'checkAndStartAutoUpdate') return mockResponse;
      if (call.method == 'completeUpdate') return true;
      return null;
    });

    expect(
      await service.checkForAutoUpdate(bypassThrottle: true),
      AppUpdateCheckResult.upToDate,
    );

    mockResponse = 'flexible_started';
    expect(
      await service.checkForAutoUpdate(bypassThrottle: true),
      AppUpdateCheckResult.downloading,
    );

    mockResponse = 'immediate_started';
    expect(
      await service.checkForAutoUpdate(bypassThrottle: true),
      AppUpdateCheckResult.installing,
    );

    mockResponse = 'installing';
    expect(
      await service.checkForAutoUpdate(bypassThrottle: true),
      AppUpdateCheckResult.installing,
    );

    mockResponse = 'unavailable';
    expect(
      await service.checkForAutoUpdate(bypassThrottle: true),
      AppUpdateCheckResult.unavailable,
    );

    service.initialize();
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('onUpdateDownloaded')),
      (_) {},
    );
    expect(service.updateDownloaded.value, isTrue);

    expect(await service.completeUpdate(), isTrue);
    expect(service.updateDownloaded.value, isFalse);
  });

  test('AppThemePalette.resolve maps system theme to platform brightness', () {
    expect(
      AppThemePalette.resolve('system', Brightness.dark),
      AppThemePalette.whatsappDark,
    );
    expect(
      AppThemePalette.resolve('system', Brightness.light),
      AppThemePalette.light,
    );
  });

  test('Graphite defaults are registered and keep readable action contrast',
      () {
    expect(AppThemePreset.presets.map((p) => p.id).toSet(),
        StorePreferences.themeOptions.toSet());
    expect(AppThemePreset.byId('unknown').id, 'graphite');
    expect(AppThemePalette.forId(' GRAPHITE '), AppThemePalette.graphite);
    AppColors.applyPalette(AppThemePalette.graphite);
    double contrast(Color a, Color b) {
      final first = a.computeLuminance();
      final second = b.computeLuminance();
      return first > second
          ? (first + 0.05) / (second + 0.05)
          : (second + 0.05) / (first + 0.05);
    }

    expect(
        contrast(AppColors.primary, Colors.white), greaterThanOrEqualTo(4.5));
    expect(contrast(AppColors.textMuted, AppColors.surface),
        greaterThanOrEqualTo(4.5));
    expect(contrast(AppColors.completionAction, Colors.white),
        greaterThanOrEqualTo(4.5));
    expect(AppColors.completionAction, AppColors.successDeep);
    expect(AppColors.primary, isNot(AppColors.completionAction));
  });

  testWidgets(
      'Auth stays light and signed-in users start with Graphite and can switch presets',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _ThemeTestStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PosLocalStore>.value(value: store),
          ChangeNotifierProvider.value(value: store.authService),
          ChangeNotifierProvider.value(value: store.salesService),
          ChangeNotifierProvider.value(value: store.inventoryService),
          ChangeNotifierProvider.value(value: store.accountingService),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Auth retains its own light surface.
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(AppColors.activePalette.id, 'light');
    expect(AppColors.isDark, isFalse);
    expect(AppColors.pageBackground, AppThemePalette.light.pageBackground);
    final onboardingScaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(OnboardingPage),
        matching: find.byType(Scaffold),
      ),
    );
    expect(onboardingScaffold.backgroundColor, Colors.white);
    expect(AppRadius.input, 0.0);
    expect(AppCorners.input, BorderRadius.zero);
    final onboardingRegion = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .first;
    expect(onboardingRegion.value.statusBarIconBrightness, Brightness.dark);
    expect(onboardingRegion.value.systemNavigationBarColor, Colors.white);
    final onboardingInputBorder = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .theme
        ?.inputDecorationTheme
        .border as OutlineInputBorder;
    expect(onboardingInputBorder.borderRadius, BorderRadius.zero);

    // 2. Login / AuthShell stays pure white even if appTheme is dark/oled
    store.setAuthState(hasCompletedOnboarding: true, isLoggedIn: false);
    await store.setStorePreferences(
      store.storePreferences.copyWith(appTheme: 'oled'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthShell), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(AppColors.activePalette.id, 'light');
    expect(AppColors.isDark, isFalse);
    final authScaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(AuthShell),
        matching: find.byType(Scaffold),
      ),
    );
    expect(authScaffold.backgroundColor, Colors.white);
    final authMaterialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(authMaterialApp.theme?.brightness, Brightness.light);
    final authRegion = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .first;
    expect(authRegion.value.statusBarIconBrightness, Brightness.dark);
    expect(authRegion.value.systemNavigationBarColor, Colors.white);

    // 3. Inside AppShell: use the new default and log in
    await store.setStorePreferences(
      store.storePreferences
          .copyWith(appTheme: StorePreferences.defaultAppTheme),
    );
    store.setAuthState(hasCompletedOnboarding: true, isLoggedIn: true);
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(AppColors.activePalette.id, 'graphite');
    expect(AppColors.isDark, isFalse);
    expect(AppColors.pageBackground, AppThemePalette.graphite.pageBackground);
    expect(AppColors.headerSurface, AppThemePalette.graphite.headerSurface);

    final initialMaterialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(initialMaterialApp.theme?.brightness, Brightness.light);
    expect(
      initialMaterialApp.theme?.scaffoldBackgroundColor,
      AppThemePalette.graphite.pageBackground,
    );
    final darkInputBorder = initialMaterialApp
        .theme?.inputDecorationTheme.border as OutlineInputBorder;
    expect(darkInputBorder.borderRadius, BorderRadius.zero);

    final initialRegion = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .first;
    expect(initialRegion.value.statusBarIconBrightness, Brightness.dark);
    expect(
      initialRegion.value.systemNavigationBarColor,
      AppThemePalette.graphite.headerSurface,
    );

    // Switch dynamically across all presets while inside the app
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

    // 4. Logout returns auth screen to light while preserving saved appTheme
    await store.setStorePreferences(
      store.storePreferences.copyWith(appTheme: 'whatsapp_dark'),
    );
    store.setAuthState(isLoggedIn: false);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(AppColors.activePalette.id, 'light');
    expect(AppColors.isDark, isFalse);
    expect(store.storePreferences.appTheme, 'whatsapp_dark');
  });
}
