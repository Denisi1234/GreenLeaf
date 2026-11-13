class ReceiptSettings {
  const ReceiptSettings({
    this.showStoreContact = true,
    this.showTaxId = true,
    this.showOrderNumber = true,
    this.showDateTime = true,
    this.showCashier = true,
    this.showCustomer = true,
    this.showPaymentMethod = true,
    this.showItemCount = true,
    this.showDiscount = true,
    this.header = '',
    this.footer = '',
  });

  static const headerLimit = 80;
  static const footerLimit = 160;

  final bool showStoreContact;
  final bool showTaxId;
  final bool showOrderNumber;
  final bool showDateTime;
  final bool showCashier;
  final bool showCustomer;
  final bool showPaymentMethod;
  final bool showItemCount;
  final bool showDiscount;
  final String header;
  final String footer;

  @override
  bool operator ==(Object other) {
    return other is ReceiptSettings &&
        other.showStoreContact == showStoreContact &&
        other.showTaxId == showTaxId &&
        other.showOrderNumber == showOrderNumber &&
        other.showDateTime == showDateTime &&
        other.showCashier == showCashier &&
        other.showCustomer == showCustomer &&
        other.showPaymentMethod == showPaymentMethod &&
        other.showItemCount == showItemCount &&
        other.showDiscount == showDiscount &&
        other.header == header &&
        other.footer == footer;
  }

  @override
  int get hashCode => Object.hash(
        showStoreContact,
        showTaxId,
        showOrderNumber,
        showDateTime,
        showCashier,
        showCustomer,
        showPaymentMethod,
        showItemCount,
        showDiscount,
        header,
        footer,
      );

  ReceiptSettings copyWith({
    bool? showStoreContact,
    bool? showTaxId,
    bool? showOrderNumber,
    bool? showDateTime,
    bool? showCashier,
    bool? showCustomer,
    bool? showPaymentMethod,
    bool? showItemCount,
    bool? showDiscount,
    String? header,
    String? footer,
  }) {
    return ReceiptSettings(
      showStoreContact: showStoreContact ?? this.showStoreContact,
      showTaxId: showTaxId ?? this.showTaxId,
      showOrderNumber: showOrderNumber ?? this.showOrderNumber,
      showDateTime: showDateTime ?? this.showDateTime,
      showCashier: showCashier ?? this.showCashier,
      showCustomer: showCustomer ?? this.showCustomer,
      showPaymentMethod: showPaymentMethod ?? this.showPaymentMethod,
      showItemCount: showItemCount ?? this.showItemCount,
      showDiscount: showDiscount ?? this.showDiscount,
      header: header ?? this.header,
      footer: footer ?? this.footer,
    );
  }
}
