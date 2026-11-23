part of '../pos_local_store.dart';

/// Receipt, tax, language, UI configuration and store profile settings for [PosLocalStore].
mixin PosSettingsStore on ChangeNotifier {
  String get _activeStoreId;
  set _activeStoreId(String value);
  PosLocalDatabase get _database;
  PosHybridDatabase? get _cloudApi;
  PhpApiClient? get cloudApi;
  set _receiptSettings(ReceiptSettings value);
  TaxSettings get _taxSettings;
  set _taxSettings(TaxSettings value);
  StorePreferences get _storePreferences;
  set _storePreferences(StorePreferences value);
  String get _languageCode;
  set _languageCode(String value);
  bool get _hasCompletedOnboarding;
  set _hasCompletedOnboarding(bool value);
  set _profile(AppProfileData value);
  bool hasPermission(String permission);
  Future<void> _recalculateStockStates();
  Future<AuditLogEntry> recordAuditEvent({
    required AuditModule module,
    required String action,
    AuditSeverity severity = AuditSeverity.info,
    required String entityType,
    String entityId = '',
    String entityLabel = '',
    required String summary,
    Map<String, String> beforeValues = const <String, String>{},
    Map<String, String> afterValues = const <String, String>{},
    Map<String, String> metadata = const <String, String>{},
    String? actorIdOverride,
    String? actorNameOverride,
    String? actorRoleOverride,
  });

  Future<void> updateReceiptSettings(ReceiptSettings settings) async {
    if (!hasPermission('System Settings')) {
      throw StateError('You do not have permission to change system settings.');
    }
    await _database.saveReceiptSettings(settings);
    _receiptSettings = settings;
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.settings,
        action: 'settings.receipt_updated',
        severity: AuditSeverity.info,
        entityType: 'Receipt Settings',
        entityLabel: 'Receipt layout',
        summary: 'Updated receipt layout & footer configuration',
      ),
    );
  }

  TaxSettings get taxSettings => _taxSettings;
  StorePreferences get storePreferences => _storePreferences;
  StorePreferences get preferences => _storePreferences;

  Future<void> updateTaxSettings(TaxSettings settings) async {
    if (!hasPermission('System Settings')) {
      throw StateError('You do not have permission to change system settings.');
    }
    final previous = _taxSettings;
    await _database.saveTaxSettings(settings);
    _taxSettings = settings;
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.settings,
        action: 'settings.tax_updated',
        severity: AuditSeverity.warning,
        entityType: 'Tax Settings',
        entityLabel: settings.taxLabel,
        summary:
            'Updated ${settings.taxLabel} tax settings (${settings.enabled ? 'Enabled ${settings.ratePercent.toStringAsFixed(1)}%' : 'Disabled'})',
        beforeValues: {
          'Enabled': previous.enabled ? 'Yes' : 'No',
          'Rate %': previous.ratePercent.toStringAsFixed(2),
          'Tax ID': previous.taxId,
        },
        afterValues: {
          'Enabled': settings.enabled ? 'Yes' : 'No',
          'Rate %': settings.ratePercent.toStringAsFixed(2),
          'Tax ID': settings.taxId,
        },
      ),
    );
  }

  Future<void> setLanguageCode(String code) async {
    final nextCode = AppStrings.normalize(code);
    if (_languageCode == nextCode) return;
    final db = _cloudApi ?? _database;
    if (db is PosCloudDatabase) {
      await cloudApi!.put('preferences', '1', <String, Object?>{
        'languageCode': nextCode,
        ..._storePreferences.toJson(),
      });
    }
    _languageCode = nextCode;
    await _writeUiConfig();
    if (db is PosHybridDatabase) {
      await db.saveLanguagePreference(nextCode);
    }
    notifyListeners();
  }

  /// Updates the active app theme preference safely for any signed-in user.
  Future<void> setAppTheme(String themeId) async {
    final normalized = themeId.trim().toLowerCase();
    final nextTheme = StorePreferences.themeOptions.contains(normalized)
        ? normalized
        : 'whatsapp_dark';
    final current = _storePreferences;
    _storePreferences = StorePreferences(
      lowStockThreshold: current.lowStockThreshold,
      dateFormat: current.dateFormat,
      timeFormat: current.timeFormat,
      autoDailySmsReport: current.autoDailySmsReport,
      dailySmsTime: current.dailySmsTime,
      lastDailySmsDate: current.lastDailySmsDate,
      defaultRegisterName: current.defaultRegisterName,
      thermalPrinterName: current.thermalPrinterName,
      thermalPrinterAddress: current.thermalPrinterAddress,
      thermalPaperWidthMm: current.thermalPaperWidthMm,
      openCashDrawerOnPrint: current.openCashDrawerOnPrint,
      enableAdvancedAccounting: current.enableAdvancedAccounting,
      requireOpenShiftForSales: current.requireOpenShiftForSales,
      appTheme: nextTheme,
      themeDefaultVersion: StorePreferences.currentThemeDefaultVersion,
    );
    notifyListeners();
    try {
      await _writeUiConfig();
    } catch (_) {}
  }

  Future<void> setStorePreferences(StorePreferences preferences) async {
    if (!hasPermission('System Settings')) {
      throw StateError('You do not have permission to change system settings.');
    }
    final thresholdChanged =
        _storePreferences.lowStockThreshold != preferences.lowStockThreshold;
    _storePreferences = preferences;
    if (thresholdChanged) {
      await _recalculateStockStates();
    }
    await _writeUiConfig();
    final db = _cloudApi ?? _database;
    if (db is PosCloudDatabase) {
      try {
        await cloudApi!.put('preferences', '1', <String, Object?>{
          'languageCode': _languageCode,
          ...preferences.toJson(),
        });
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _loadUiConfig() async {
    _storePreferences = const StorePreferences();
    var migratedThemeDefault = false;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/track_mauzo_ui_config.json');
      if (!await file.exists()) {
        final defaults = <String, dynamic>{
          'languageCode': _defaultLanguageCode,
          'activeStoreId': _activeStoreId,
          'hasCompletedOnboarding': 0,
          ..._storePreferences.toJson(),
        };
        await file.writeAsString(jsonEncode(defaults));
      } else {
        final jsonStr = await file.readAsString();
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _languageCode = AppStrings.normalize(
          map['languageCode'] as String? ?? _defaultLanguageCode,
        );
        _hasCompletedOnboarding =
            (map['hasCompletedOnboarding'] as int? ?? 0) == 1;
        final savedStoreId = (map['activeStoreId'] as String?)?.trim();
        if (savedStoreId != null && savedStoreId.isNotEmpty) {
          _activeStoreId = savedStoreId;
        }
        final savedThemeVersion =
            (map['themeDefaultVersion'] as num?)?.toInt() ?? 0;
        if (savedThemeVersion < StorePreferences.currentThemeDefaultVersion) {
          migratedThemeDefault = true;
        }
        _storePreferences = StorePreferences.fromJson(map);
      }
    } catch (_) {
      _languageCode = _defaultLanguageCode;
      _storePreferences = const StorePreferences();
    }

    if (_database is PosCloudDatabase) {
      try {
        final rows = await cloudApi!.rows('preferences');
        if (rows.isNotEmpty) {
          _languageCode = AppStrings.normalize(
            rows.first['languageCode'] as String? ?? _languageCode,
          );
          final cloudMap = Map<String, dynamic>.from(rows.first);
          final cloudThemeVersion =
              (cloudMap['themeDefaultVersion'] as num?)?.toInt() ?? 0;
          if (cloudThemeVersion < StorePreferences.currentThemeDefaultVersion) {
            cloudMap.remove('appTheme');
            cloudMap['themeDefaultVersion'] =
                StorePreferences.currentThemeDefaultVersion;
            migratedThemeDefault = true;
          }
          _storePreferences = StorePreferences.fromJson(
            <String, dynamic>{
              ..._storePreferences.toJson(),
              ...cloudMap,
            },
          );
        }
      } catch (_) {}
    }

    if (migratedThemeDefault) {
      await _saveUiConfig();
      if (_database is PosCloudDatabase) {
        try {
          await cloudApi!.put('preferences', '1', <String, Object?>{
            'languageCode': _languageCode,
            ..._storePreferences.toJson(),
          });
        } catch (_) {}
      }
    }
  }

  Future<void> _saveUiConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/track_mauzo_ui_config.json');
      Map<String, dynamic> existing = <String, dynamic>{};
      if (await file.exists()) {
        try {
          final decoded = jsonDecode(await file.readAsString());
          if (decoded is Map<String, dynamic>) existing = decoded;
        } catch (_) {}
      }
      existing['languageCode'] = _languageCode;
      existing['activeStoreId'] = _activeStoreId;
      existing['hasCompletedOnboarding'] = _hasCompletedOnboarding ? 1 : 0;
      existing.addAll(_storePreferences.toJson());
      await file.writeAsString(jsonEncode(existing), flush: true);
    } catch (_) {}
  }

  Future<void> _writeUiConfig() => _saveUiConfig();

  Future<void> markOnboardingComplete() async {
    _hasCompletedOnboarding = true;
    await _saveUiConfig();
    notifyListeners();
  }

  Future<void> updateProfile(AppProfileData profile) async {
    if (!hasPermission('System Settings')) {
      throw StateError('You do not have permission to change system settings.');
    }
    await _database.saveAppProfile(_profileToMap(profile));
    _profile = profile;
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.settings,
        action: 'settings.profile_updated',
        severity: AuditSeverity.info,
        entityType: 'Store Profile',
        entityLabel: profile.storeName,
        summary: 'Updated business profile for ${profile.storeName}',
      ),
    );
  }

  Map<String, Object?> _profileToMap(AppProfileData profile) {
    return <String, Object?>{
      'store_name': profile.storeName,
      'owner_name': profile.ownerName,
      'role_title': profile.roleTitle,
      'business_category': BusinessCategory.retail.storageKey,
      'contact_number': profile.contactNumber,
      'email_address': profile.emailAddress,
      'physical_address': profile.physicalAddress,
      'member_since': profile.memberSince,
      'tax_id': profile.taxId,
      'weekday_open': profile.weekdayOpen,
      'weekday_close': profile.weekdayClose,
      'saturday_open': profile.saturdayOpen,
      'saturday_close': profile.saturdayClose,
      'sunday_schedule': profile.sundaySchedule,
      'open_24_hours': profile.open24Hours ? 1 : 0,
      'logo_path': profile.logoPath,
    };
  }
}
