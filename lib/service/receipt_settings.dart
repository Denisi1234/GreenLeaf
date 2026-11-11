class ReceiptSettings {
  const ReceiptSettings({
    this.showStoreContact = true,
    this.footer = '',
  });

  static const footerLimit = 160;

  final bool showStoreContact;
  final String footer;
}
