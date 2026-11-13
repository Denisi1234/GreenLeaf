class StorePreferences {
  const StorePreferences({
    this.lowStockThreshold = 20,
    this.dateFormat = 'MMM d, yyyy',
    this.timeFormat = '12h',
    this.autoDailySmsReport = true,
    this.dailySmsTime = '21:00',
    this.lastDailySmsDate = '',
  });

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

  bool get uses24HourTime => timeFormat == '24h';

  StorePreferences copyWith({
    int? lowStockThreshold,
    String? dateFormat,
    String? timeFormat,
    bool? autoDailySmsReport,
    String? dailySmsTime,
    String? lastDailySmsDate,
  }) {
    return StorePreferences(
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      autoDailySmsReport: autoDailySmsReport ?? this.autoDailySmsReport,
      dailySmsTime: dailySmsTime ?? this.dailySmsTime,
      lastDailySmsDate: lastDailySmsDate ?? this.lastDailySmsDate,
    );
  }

  factory StorePreferences.fromJson(Map<String, dynamic> json) {
    final dateFormat = json['dateFormat'] as String? ?? 'MMM d, yyyy';
    final timeFormat = json['timeFormat'] as String? ?? '12h';
    final autoSms = json['autoDailySmsReport'];
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
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'lowStockThreshold': lowStockThreshold,
        'dateFormat': dateFormat,
        'timeFormat': timeFormat,
        'autoDailySmsReport': autoDailySmsReport,
        'dailySmsTime': dailySmsTime,
        'lastDailySmsDate': lastDailySmsDate,
      };
}
