import 'dart:convert';
import 'dart:typed_data';

import '../ui/receipt/receipt_document.dart';

enum ThermalPaperWidth {
  mm58(58, 32),
  mm80(80, 48);

  const ThermalPaperWidth(this.mm, this.columns);
  final int mm;
  final int columns;

  static ThermalPaperWidth fromMm(int mm) => mm >= 80 ? mm80 : mm58;
}

/// Builds raw ESC/POS byte commands for 58mm (32-column) and 80mm (48-column)
/// Bluetooth/USB thermal receipt printers.
class EscPosReceiptBuilder {
  const EscPosReceiptBuilder._();

  static Uint8List buildReceipt(
    ReceiptDocument receipt, {
    ThermalPaperWidth paperWidth = ThermalPaperWidth.mm58,
    bool openCashDrawer = false,
    bool autoCut = true,
  }) {
    final cols = paperWidth.columns;
    final buf = BytesBuilder(copy: false);

    void cmd(List<int> bytes) => buf.add(bytes);
    void align(int mode) => cmd([0x1B, 0x61, mode]); // 0=left, 1=center, 2=right
    void bold(bool on) => cmd([0x1B, 0x45, on ? 1 : 0]);
    void textSize(int mode) => cmd([0x1D, 0x21, mode]); // 0x00, 0x01, 0x11

    void writeLine(String text) {
      final clean = _sanitizeAscii(text);
      buf.add(ascii.encode(clean));
      buf.addByte(0x0A);
    }

    void writeWrapped(String text) {
      for (final part in _wrap(text, cols)) {
        writeLine(part);
      }
    }

    void divider([String ch = '-']) => writeLine(ch * cols);

    cmd([0x1B, 0x40]); // ESC @ Initialize printer

    // Header
    align(1);
    bold(true);
    textSize(0x11); // Double width & height
    writeWrapped(receipt.businessName);
    textSize(0x00);
    bold(false);

    if (receipt.settings.showStoreContact) {
      if (receipt.storeAddress.trim().isNotEmpty) {
        writeWrapped(receipt.storeAddress.trim());
      }
      if (receipt.storePhone.trim().isNotEmpty) {
        writeWrapped(receipt.storePhone.trim());
      }
    }
    if (receipt.settings.showTaxId && receipt.storeTaxId.trim().isNotEmpty) {
      writeWrapped('TIN: ${receipt.storeTaxId.trim()}');
    }
    if (receipt.settings.header.trim().isNotEmpty) {
      writeWrapped(receipt.settings.header.trim());
    }

    divider();
    bold(true);
    writeWrapped(receipt.statusLabel);
    bold(false);
    divider();

    // Metadata
    align(0);
    for (final entry in receipt.metadata) {
      writeLine(_columns(entry.key, entry.value, cols));
    }

    divider();
    bold(true);
    writeLine(_columns('ITEM', 'AMOUNT', cols));
    bold(false);
    divider();

    // Line items
    for (final line in receipt.order.lines) {
      writeWrapped(line.itemName);
      final qtyPrice = '${line.quantity} x ${receipt.money(line.unitPriceValue)}';
      final lineTotal = receipt.money(line.lineTotal);
      writeLine(_columns('  $qtyPrice', lineTotal, cols));
    }

    divider();

    // Totals
    final totalLabel = receipt.label('Total').toLowerCase();
    for (final entry in receipt.totals) {
      final isGrandTotal = entry.key.toLowerCase() == totalLabel;
      if (isGrandTotal) {
        bold(true);
        textSize(0x01); // Double height
        writeLine(_columns(entry.key, entry.value, cols));
        textSize(0x00);
        bold(false);
      } else {
        writeLine(_columns(entry.key, entry.value, cols));
      }
    }

    divider();
    align(1);
    writeWrapped(receipt.footer);

    // Feed lines & cut
    cmd([0x1B, 0x64, 4]); // ESC d 4
    if (autoCut) {
      cmd([0x1D, 0x56, 66, 0]); // GS V 66 0 (partial cut)
    }
    if (openCashDrawer) {
      cmd([0x1B, 0x70, 0x00, 0x19, 0xFA]); // ESC p 0 25 250
    }

    return buf.toBytes();
  }

  static Uint8List buildTestTicket({
    required String storeName,
    ThermalPaperWidth paperWidth = ThermalPaperWidth.mm58,
  }) {
    final cols = paperWidth.columns;
    final buf = BytesBuilder(copy: false);
    final name = storeName.trim().isEmpty ? 'TrackMauzo POS' : storeName.trim();

    buf.add([0x1B, 0x40]); // ESC @
    buf.add([0x1B, 0x61, 1]); // Center
    buf.add([0x1B, 0x45, 1]); // Bold
    buf.add([0x1D, 0x21, 0x11]); // Double size
    for (final line in _wrap(name, cols)) {
      buf.add(ascii.encode('${_sanitizeAscii(line)}\n'));
    }
    buf.add([0x1D, 0x21, 0x00]);
    buf.add([0x1B, 0x45, 0]);
    buf.add(ascii.encode('${'-' * cols}\n'));
    buf.add(ascii.encode('Thermal Printer Test (${paperWidth.mm}mm)\n'));
    buf.add(ascii.encode('${'-' * cols}\n'));
    buf.add([0x1B, 0x61, 0]); // Left
    buf.add(ascii.encode('${_columns('Columns', '$cols chars', cols)}\n'));
    buf.add(ascii.encode('${_columns('Status', 'READY', cols)}\n'));
    buf.add(ascii.encode('${'-' * cols}\n'));
    buf.add([0x1B, 0x61, 1]);
    buf.add(ascii.encode('TrackMauzo Printer OK\n'));
    buf.add([0x1B, 0x64, 4]);
    buf.add([0x1D, 0x56, 66, 0]);
    return buf.toBytes();
  }

  static String _columns(String left, String right, int cols) {
    final l = _sanitizeAscii(left).trimRight();
    final r = _sanitizeAscii(right).trim();
    const minGap = 1;
    if (l.length + r.length + minGap <= cols) {
      final spaces = cols - l.length - r.length;
      return '$l${' ' * spaces}$r';
    }
    final maxLeft = (cols - r.length - minGap).clamp(0, cols);
    if (maxLeft <= 0) {
      return r.length > cols ? r.substring(0, cols) : r;
    }
    final trimmedLeft = l.length > maxLeft ? l.substring(0, maxLeft) : l;
    final spaces = (cols - trimmedLeft.length - r.length).clamp(1, cols);
    return '$trimmedLeft${' ' * spaces}$r';
  }

  static List<String> _wrap(String text, int width) {
    final clean = _sanitizeAscii(text).trim();
    if (clean.isEmpty) return const [];
    final lines = <String>[];
    for (final rawLine in clean.split('\n')) {
      var remaining = rawLine.trim();
      while (remaining.length > width) {
        var splitAt = remaining.lastIndexOf(' ', width);
        if (splitAt <= 0) splitAt = width;
        lines.add(remaining.substring(0, splitAt).trimRight());
        remaining = remaining.substring(splitAt).trimLeft();
      }
      if (remaining.isNotEmpty) lines.add(remaining);
    }
    return lines;
  }

  static String _sanitizeAscii(String input) {
    final replaced = input
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('•', '*')
        .replaceAll('·', '*')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"');
    final out = StringBuffer();
    for (final code in replaced.runes) {
      if (code == 10 || (code >= 32 && code <= 126)) {
        out.writeCharCode(code);
      } else {
        out.write(' ');
      }
    }
    return out.toString();
  }
}
