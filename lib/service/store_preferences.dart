class StorePreferences {
  const StorePreferences({
    this.lowStockThreshold = 20,
    this.dateFormat = 'MMM d, yyyy',
    this.timeFormat = '12h',
    this.autoDailySmsReport = true,
    this.dailySmsTime = '21:00',
    this.lastDailySmsDate = '',
    this.defaultRegisterName = 'Register 1',
    this.thermalPrinterName = '',
    this.thermalPrinterAddress = '',
    this.thermalPaperWidthMm = 58,
    this.openCashDrawerOnPrint = false,
    this.enableAdvancedAccounting = false,
    this.requireOpenShiftForSales = false,
    this.appTheme = 'light',
  });

  static const themeOptions = <String>['light', 'slate', 'warm', 'dark'];

  static const dateFormatOptions = <String>[
    'MMM d, yyyy',
    'd MMM yyyy',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
  ];

  static const timeFormatOptions = <String>['12h', '24h'];

  final int lowStockThreshold;
  final String dateFormat;
  final String timeFormat;
  final bool autoDailySmsReport;
  final String dailySmsTime;
  final String lastDailySmsDate;
  final String defaultRegisterName;
  final String thermalPrinterName;
  final String thermalPrinterAddress;
  final int thermalPaperWidthMm;
  final bool openCashDrawerOnPrint;
  final bool enableAdvancedAccounting;
  final bool requireOpenShiftForSales;
  final String appTheme;

  bool get uses24HourTime => timeFormat == '24h';

  StorePreferences copyWith({
    int? lowStockThreshold,
    String? dateFormat,
    String? timeFormat,
    bool? autoDailySmsReport,
    String? dailySmsTime,
    String? lastDailySmsDate,
    String? defaultRegisterName,
    String? thermalPrinterName,
    String? thermalPrinterAddress,
    int? thermalPaperWidthMm,
    bool? openCashDrawerOnPrint,
    bool? enableAdvancedAccounting,
    bool? requireOpenShiftForSales,
    String? appTheme,
  }) {
    return StorePreferences(
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      autoDailySmsReport: autoDailySmsReport ?? this.autoDailySmsReport,
      dailySmsTime: dailySmsTime ?? this.dailySmsTime,
      lastDailySmsDate: lastDailySmsDate ?? this.lastDailySmsDate,
      defaultRegisterName: defaultRegisterName ?? this.defaultRegisterName,
      thermalPrinterName: thermalPrinterName ?? this.thermalPrinterName,
      thermalPrinterAddress:
          thermalPrinterAddress ?? this.thermalPrinterAddress,
      thermalPaperWidthMm: thermalPaperWidthMm ?? this.thermalPaperWidthMm,
      openCashDrawerOnPrint:
          openCashDrawerOnPrint ?? this.openCashDrawerOnPrint,
      enableAdvancedAccounting:
          enableAdvancedAccounting ?? this.enableAdvancedAccounting,
      requireOpenShiftForSales:
          requireOpenShiftForSales ?? this.requireOpenShiftForSales,
      appTheme: appTheme ?? this.appTheme,
    );
  }

  factory StorePreferences.fromJson(Map<String, dynamic> json) {
    final dateFormat = json['dateFormat'] as String? ?? 'MMM d, yyyy';
    final timeFormat = json['timeFormat'] as String? ?? '12h';
    final autoSms = json['autoDailySmsReport'];
    final paperRaw = (json['thermalPaperWidthMm'] as num?)?.toInt() ?? 58;
    final openDrawer = json['openCashDrawerOnPrint'];
    final advAcc = json['enableAdvancedAccounting'];
    final reqShift = json['requireOpenShiftForSales'];
    final rawTheme = (json['appTheme'] as String? ?? 'light').trim().toLowerCase();
    return StorePreferences(
      lowStockThreshold:
          ((json['lowStockThreshold'] as num?)?.toInt() ?? 20).clamp(0, 100000),
      dateFormat:
          dateFormatOptions.contains(dateFormat) ? dateFormat : 'MMM d, yyyy',
      timeFormat: timeFormatOptions.contains(timeFormat) ? timeFormat : '12h',
      autoDailySmsReport: autoSms == null
          ? true
          : (autoSms == true ||
              autoSms == 1 ||
              autoSms == '1' ||
              (autoSms is String && autoSms.toLowerCase() == 'true')),
      dailySmsTime: json['dailySmsTime'] as String? ?? '21:00',
      lastDailySmsDate: json['lastDailySmsDate'] as String? ?? '',
      defaultRegisterName: json['defaultRegisterName'] as String? ?? 'Register 1',
      thermalPrinterName: json['thermalPrinterName'] as String? ?? '',
      thermalPrinterAddress: json['thermalPrinterAddress'] as String? ?? '',
      thermalPaperWidthMm: paperRaw >= 80 ? 80 : 58,
      openCashDrawerOnPrint: openDrawer == true ||
          openDrawer == 1 ||
          openDrawer == '1' ||
          (openDrawer is String && openDrawer.toLowerCase() == 'true'),
      enableAdvancedAccounting: advAcc == true ||
          advAcc == 1 ||
          advAcc == '1' ||
          (advAcc is String && advAcc.toLowerCase() == 'true'),
      requireOpenShiftForSales: reqShift == true ||
          reqShift == 1 ||
          reqShift == '1' ||
          (reqShift is String && reqShift.toLowerCase() == 'true'),
      appTheme: themeOptions.contains(rawTheme) ? rawTheme : 'light',
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'lowStockThreshold': lowStockThreshold,
        'dateFormat': dateFormat,
        'timeFormat': timeFormat,
        'autoDailySmsReport': autoDailySmsReport,
        'dailySmsTime': dailySmsTime,
        'lastDailySmsDate': lastDailySmsDate,
        'defaultRegisterName': defaultRegisterName,
        'thermalPrinterName': thermalPrinterName,
        'thermalPrinterAddress': thermalPrinterAddress,
        'thermalPaperWidthMm': thermalPaperWidthMm,
        'openCashDrawerOnPrint': openCashDrawerOnPrint,
        'enableAdvancedAccounting': enableAdvancedAccounting,
        'requireOpenShiftForSales': requireOpenShiftForSales,
        'appTheme': appTheme,
      };
}
