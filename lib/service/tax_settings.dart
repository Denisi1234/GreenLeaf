class TaxSettings {
  final bool enabled;
  final double ratePercent;
  final bool pricesIncludeTax;
  final String taxId;
  final String taxLabel;
  final bool trackExpenseTax;

  const TaxSettings({
    this.enabled = false,
    this.ratePercent = 0,
    this.pricesIncludeTax = true,
    this.taxId = '',
    this.taxLabel = 'VAT',
    this.trackExpenseTax = true,
  });

  TaxSettings copyWith({
    bool? enabled,
    double? ratePercent,
    bool? pricesIncludeTax,
    String? taxId,
    String? taxLabel,
    bool? trackExpenseTax,
  }) =>
      TaxSettings(
        enabled: enabled ?? this.enabled,
        ratePercent: ratePercent ?? this.ratePercent,
        pricesIncludeTax: pricesIncludeTax ?? this.pricesIncludeTax,
        taxId: taxId ?? this.taxId,
        taxLabel: taxLabel ?? this.taxLabel,
        trackExpenseTax: trackExpenseTax ?? this.trackExpenseTax,
      );

  /// Tax portion contained in a gross (tax inclusive) amount.
  double taxFromGross(double gross) {
    if (!enabled || ratePercent <= 0 || !pricesIncludeTax) return 0;
    return gross - gross / (1 + ratePercent / 100);
  }

  /// Tax added on top of a net (tax exclusive) amount.
  double taxFromNet(double net) {
    if (!enabled || ratePercent <= 0 || pricesIncludeTax) return 0;
    return net * ratePercent / 100;
  }

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'rate_percent': ratePercent,
        'prices_include_tax': pricesIncludeTax,
        'tax_id': taxId,
        'tax_label': taxLabel,
        'track_expense_tax': trackExpenseTax,
      };

  factory TaxSettings.fromJson(Map<String, Object?> json) {
    bool readBool(Object? value, bool fallback) {
      if (value == null) return fallback;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.toLowerCase().trim();
        if (v == 'true' || v == '1') return true;
        if (v == 'false' || v == '0') return false;
      }
      return fallback;
    }

    return TaxSettings(
      enabled: readBool(json['enabled'], false),
      ratePercent: (json['rate_percent'] as num?)?.toDouble() ?? 0,
      pricesIncludeTax: readBool(json['prices_include_tax'], true),
      taxId: (json['tax_id'] ?? '').toString(),
      taxLabel: (json['tax_label'] ?? 'VAT').toString(),
      trackExpenseTax: readBool(json['track_expense_tax'], true),
    );
  }
}
