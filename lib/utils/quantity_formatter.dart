import 'dart:math' as math;

const List<String> kMeasurementUnits = <String>[
  'Pcs',
  'kg',
  'g',
  'L',
  'ml',
  'm',
];

bool isMeasuredUnit(String unit) {
  final normalized = unit.trim().toLowerCase();
  return normalized == 'kg' ||
      normalized == 'g' ||
      normalized == 'l' ||
      normalized == 'ml' ||
      normalized == 'm';
}

double roundQuantity(double value) {
  if (!value.isFinite) return 0.0;
  final rounded = (value * 1000).round() / 1000.0;
  return rounded == 0 ? 0.0 : rounded;
}

String formatQuantity(double value, {int maxDecimals = 3}) {
  if (!value.isFinite) return '0';
  final factor = math.pow(10, maxDecimals).toDouble();
  final rounded = (value * factor).round() / factor;
  final clean = rounded == 0 ? 0.0 : rounded;
  if (maxDecimals <= 0) return clean.round().toString();
  final fixed = clean.toStringAsFixed(maxDecimals);
  final trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return trimmed == '-0' ? '0' : trimmed;
}

String formatStockWithUnit(double stock, String unit) {
  final qtyText = formatQuantity(stock);
  final u = unit.trim();
  return u.isEmpty ? qtyText : '$qtyText $u';
}

String formatQtyForReceipt(double qty, String unit) {
  final qtyText = formatQuantity(qty);
  final u = unit.trim();
  if (u.isEmpty || u.toLowerCase() == 'pcs') {
    return qtyText;
  }
  return '$qtyText $u';
}

double stepForUnit(String unit, bool allowFractional) {
  if (!allowFractional) return 1.0;
  switch (unit.trim().toLowerCase()) {
    case 'kg':
    case 'l':
      return 0.25;
    case 'm':
      return 0.5;
    case 'g':
    case 'ml':
      return 100.0;
    default:
      return 0.25;
  }
}

String defaultPackNameForUnit(String unit) {
  switch (unit.trim().toLowerCase()) {
    case 'kg':
    case 'g':
      return 'Mfuko';
    case 'l':
    case 'ml':
      return 'Dumu';
    case 'm':
      return 'Roll';
    default:
      return 'Katoni';
  }
}

String? formatPackEquivalent(
  double stock,
  String unit, {
  String? packName,
  double? packSize,
}) {
  final name = packName?.trim() ?? '';
  if (name.isEmpty || packSize == null || packSize <= 0 || stock <= 0) {
    return null;
  }
  final packs = stock / packSize;
  return '${formatQuantity(packs, maxDecimals: 2)} $name';
}

List<({String labelEn, String labelSw, double qty})> measurementPresetsForUnit(
  String unit,
) {
  final trimmed = unit.trim();
  switch (trimmed.toLowerCase()) {
    case 'kg':
      return const [
        (labelEn: 'Robo (¼ kg)', labelSw: 'Robo (¼ kg)', qty: 0.25),
        (labelEn: 'Nusu (½ kg)', labelSw: 'Nusu (½ kg)', qty: 0.5),
        (labelEn: 'Robo tatu (¾ kg)', labelSw: 'Robo tatu (¾ kg)', qty: 0.75),
        (labelEn: '1 kg', labelSw: '1 kg', qty: 1.0),
        (labelEn: '2 kg', labelSw: '2 kg', qty: 2.0),
        (labelEn: '5 kg', labelSw: '5 kg', qty: 5.0),
      ];
    case 'l':
      return const [
        (labelEn: 'Robo (¼ L)', labelSw: 'Robo (¼ L)', qty: 0.25),
        (labelEn: 'Nusu (½ L)', labelSw: 'Nusu (½ L)', qty: 0.5),
        (labelEn: '¾ L', labelSw: '¾ L', qty: 0.75),
        (labelEn: '1 L', labelSw: '1 L', qty: 1.0),
        (labelEn: '2 L', labelSw: '2 L', qty: 2.0),
        (labelEn: '5 L', labelSw: '5 L', qty: 5.0),
      ];
    case 'g':
    case 'ml':
      return [
        (labelEn: '100 $trimmed', labelSw: '100 $trimmed', qty: 100.0),
        (labelEn: '250 $trimmed', labelSw: '250 $trimmed', qty: 250.0),
        (labelEn: '500 $trimmed', labelSw: '500 $trimmed', qty: 500.0),
        (labelEn: '1000 $trimmed', labelSw: '1000 $trimmed', qty: 1000.0),
      ];
    case 'm':
      return const [
        (labelEn: '0.5 m', labelSw: '0.5 m', qty: 0.5),
        (labelEn: '1 m', labelSw: '1 m', qty: 1.0),
        (labelEn: '1.5 m', labelSw: '1.5 m', qty: 1.5),
        (labelEn: '2 m', labelSw: '2 m', qty: 2.0),
        (labelEn: '5 m', labelSw: '5 m', qty: 5.0),
      ];
    default:
      final suffix =
          trimmed.isNotEmpty && trimmed.toLowerCase() != 'pcs' ? ' $trimmed' : '';
      return [
        (labelEn: '0.25$suffix', labelSw: '0.25$suffix', qty: 0.25),
        (labelEn: '0.5$suffix', labelSw: '0.5$suffix', qty: 0.5),
        (labelEn: '0.75$suffix', labelSw: '0.75$suffix', qty: 0.75),
        (labelEn: '1$suffix', labelSw: '1$suffix', qty: 1.0),
        (labelEn: '2$suffix', labelSw: '2$suffix', qty: 2.0),
        (labelEn: '5$suffix', labelSw: '5$suffix', qty: 5.0),
      ];
  }
}
