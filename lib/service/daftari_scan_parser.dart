import 'dart:math' as math;

import '../ui/models/product_item.dart';

class DaftariScanResult {
  const DaftariScanResult({
    required this.rawText,
    required this.lines,
    required this.unmatchedLines,
  });

  final String rawText;
  final List<DaftariScanLine> lines;
  final List<String> unmatchedLines;

  List<DaftariScanLine> get matchedLines =>
      lines.where((line) => line.matchedProduct != null).toList();
}

class DaftariScanLine {
  const DaftariScanLine({
    required this.rawText,
    required this.productName,
    required this.quantity,
    required this.matchedProduct,
    this.observedAmount,
    this.matchScore = 0,
  });

  final String rawText;
  final String productName;
  final int quantity;
  final ProductItem? matchedProduct;
  final int? observedAmount;
  final double matchScore;
}

DaftariScanResult parseDaftariText(
  String text,
  List<ProductItem> catalog,
  {
  Map<String, List<String>> learnedAliases = const <String, List<String>>{},
  }
) {
  final lines = <DaftariScanLine>[];
  final unmatchedLines = <String>[];

  for (final rawLine in text.split(RegExp(r'[\r\n]+'))) {
    final line = _normalizeOcrLine(rawLine);
    if (line.isEmpty) continue;

    final parsedLine = _parseLine(line, catalog, learnedAliases);
    if (parsedLine == null) {
      unmatchedLines.add(line);
      continue;
    }

    lines.add(parsedLine);
  }

  return DaftariScanResult(
    rawText: text,
    lines: lines,
    unmatchedLines: unmatchedLines,
  );
}

DaftariScanLine? _parseLine(
  String line,
  List<ProductItem> catalog,
  Map<String, List<String>> learnedAliases,
) {
  final compact = line.replaceAll(RegExp(r'\s+'), ' ').trim();
  final patterns = <RegExp>[
    RegExp(
      r'^(.*?)\s*(?:x|X|×|\*)\s*(\d+)(?:\s+(?:tsh\s*)?(\d[\d,]*(?:\.\d+)?))?$',
      caseSensitive: false,
    ),
    RegExp(
      r'^(.*?)\s+(?:qty|pcs|pc|pieces?)\s*(\d+)(?:\s+(?:tsh\s*)?(\d[\d,]*(?:\.\d+)?))?$',
      caseSensitive: false,
    ),
    RegExp(
      r'^(.*?)\s+(\d+)\s+(?:tsh\s*)?(\d[\d,]*(?:\.\d+)?)$',
      caseSensitive: false,
    ),
    RegExp(
      r'^(.*?)\s+(?:tsh\s*)?(\d[\d,]*(?:\.\d+)?)\s*(?:x|X|×|\*)\s*(\d+)$',
      caseSensitive: false,
    ),
    RegExp(
      r'^(.*?)\s+(\d+)$',
      caseSensitive: false,
    ),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(compact);
    if (match == null) continue;

    final productName = match.group(1)?.trim().replaceAll(
          RegExp(r'[:\-_,.;]+$'),
          '',
        ) ??
        '';
    if (productName.isEmpty) continue;

    final quantityText = match.group(2) ?? match.group(3) ?? '';
    final quantity = _parseQuantity(quantityText);
    if (quantity <= 0) continue;

    final observedAmount = _parseAmount(_extractObservedAmount(match));
    final matchedProduct = _matchProduct(
      productName,
      catalog,
      learnedAliases,
    );
    final score = matchedProduct == null
        ? 0.0
        : _matchScore(
            _normalize(productName),
            _normalize(matchedProduct.name),
            aliases: _productAliases(matchedProduct),
          );

    return DaftariScanLine(
      rawText: line,
      productName: productName,
      quantity: quantity,
      matchedProduct: matchedProduct,
      observedAmount: observedAmount,
      matchScore: score,
    );
  }

  return null;
}

ProductItem? _matchProduct(
  String query,
  List<ProductItem> catalog,
  Map<String, List<String>> learnedAliases,
) {
  if (catalog.isEmpty) return null;

  final normalizedQuery = _normalize(query);
  ProductItem? bestMatch;
  var bestScore = 0.0;

  for (final candidate in catalog) {
    final score = _matchScore(
      normalizedQuery,
      _normalize(candidate.name),
      aliases: [
        ..._productAliases(candidate),
        ...?learnedAliases[candidate.code ?? candidate.name],
      ],
    );
    if (score > bestScore) {
      bestScore = score;
      bestMatch = candidate;
    }
  }

  return bestScore >= 0.45 ? bestMatch : null;
}

double _matchScore(
  String left,
  String right, {
  List<String> aliases = const <String>[],
}) {
  if (left.isEmpty || right.isEmpty) return 0;

  if (left == right) return 1;
  if (left.contains(right) || right.contains(left)) return 0.95;

  var aliasScore = 0.0;
  for (final alias in aliases) {
    final normalizedAlias = _normalize(alias);
    if (normalizedAlias.isEmpty) continue;
    if (left == normalizedAlias) return 0.98;
    if (left.contains(normalizedAlias) || normalizedAlias.contains(left)) {
      aliasScore = math.max(aliasScore, 0.94);
      continue;
    }

    final aliasTokens =
        normalizedAlias.split(' ').where((item) => item.length > 1).toSet();
    final leftTokens = left.split(' ').where((item) => item.length > 1).toSet();
    final aliasShared = aliasTokens.intersection(leftTokens).length;
    final aliasTokenScore = aliasShared.toDouble() /
        (aliasTokens.isEmpty ? 1.0 : aliasTokens.length.toDouble());
    aliasScore = math.max(aliasScore, aliasTokenScore);
  }

  final leftTokens = left.split(' ').where((item) => item.length > 1).toSet();
  final rightTokens = right.split(' ').where((item) => item.length > 1).toSet();
  final sharedTokens = leftTokens.intersection(rightTokens).length;
  final tokenDenominator = math.max(
    1,
    math.max(leftTokens.length, rightTokens.length),
  ).toDouble();
  final tokenScore = sharedTokens.toDouble() / tokenDenominator;

  final distance = _levenshtein(left, right);
  final normalizedLength = math.max(left.length, right.length).toDouble();
  final editScore = normalizedLength == 0
      ? 0.0
      : 1.0 - (distance / normalizedLength);

  final baseScore = tokenScore > editScore ? tokenScore : editScore;
  return baseScore > aliasScore ? baseScore : aliasScore;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalizeOcrLine(String value) {
  var cleaned = value.replaceAll('×', 'x').replaceAll('✕', 'x');
  cleaned = cleaned.replaceAll(RegExp(r'\b[tT][sS][hH]\b'), 'tsh');
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'(?<![A-Za-z])[Oo](?=\d)|(?<=\d)[Oo](?![A-Za-z])'),
    (_) => '0',
  );
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'(?<![A-Za-z])[lI](?=\d)|(?<=\d)[lI](?![A-Za-z])'),
    (_) => '1',
  );
  return cleaned;
}

String? _extractObservedAmount(RegExpMatch match) {
  for (var i = 3; i <= match.groupCount; i++) {
    final value = match.group(i);
    if (value != null &&
        value.isNotEmpty &&
        RegExp(r'^\d[\d,]*(?:\.\d+)?$').hasMatch(value)) {
      return value;
    }
  }
  return null;
}

int _parseAmount(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
  final normalized = value.replaceAll(',', '');
  return int.tryParse(normalized.split('.').first) ?? 0;
}

int _parseQuantity(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(normalized) ?? 0;
}

List<String> _productAliases(ProductItem item) {
  final aliases = <String>[
    item.name,
    item.category ?? '',
    item.size,
  ];

  final lowerName = item.name.toLowerCase();
  if (lowerName.contains('water')) aliases.addAll(['aqua', 'bottle', 'mineral']);
  if (lowerName.contains('cola') || lowerName.contains('coke')) {
    aliases.addAll(['cola', 'coca']);
  }
  if (lowerName.contains('lay')) aliases.addAll(['chips', 'potato']);
  if (lowerName.contains('galaxy')) aliases.addAll(['chocolate', 'bar']);
  if (lowerName.contains('corn')) aliases.addAll(['cereal', 'flakes']);
  if (lowerName.contains('dove')) aliases.addAll(['soap', 'beauty']);
  if (lowerName.contains('colgate')) aliases.addAll(['toothpaste', 'paste']);
  if (lowerName.contains('dettol')) aliases.addAll(['handwash', 'wash']);
  if (lowerName.contains('tide')) aliases.addAll(['detergent', 'powder']);

  return aliases.where((alias) => alias.trim().isNotEmpty).toList();
}

int _levenshtein(String left, String right) {
  if (left.isEmpty) return right.length;
  if (right.isEmpty) return left.length;

  final rows = List<int>.generate(right.length + 1, (index) => index);
  for (var i = 1; i <= left.length; i++) {
    var previousDiagonal = rows[0];
    rows[0] = i;
    for (var j = 1; j <= right.length; j++) {
      final previousRowValue = rows[j];
      final cost = left[i - 1] == right[j - 1] ? 0 : 1;
      rows[j] = math.min(
        math.min(rows[j] + 1, rows[j - 1] + 1),
        previousDiagonal + cost,
      );
      previousDiagonal = previousRowValue;
    }
  }

  return rows[right.length];
}
