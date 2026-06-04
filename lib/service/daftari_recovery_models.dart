import '../ui/models/product_item.dart';

class DaftariRecoverySession {
  const DaftariRecoverySession({
    required this.id,
    required this.createdAt,
    required this.stage,
    required this.rawText,
    required this.extractedLines,
    required this.lines,
    required this.matchedCount,
    required this.unresolvedCount,
    required this.confidence,
    required this.estimatedTotal,
    this.imagePath,
    this.importedOrderId,
    this.failureReason,
  });

  final String id;
  final String createdAt;
  final String stage;
  final String rawText;
  final List<String> extractedLines;
  final List<DaftariRecoveryLine> lines;
  final int matchedCount;
  final int unresolvedCount;
  final double confidence;
  final double estimatedTotal;
  final String? imagePath;
  final String? importedOrderId;
  final String? failureReason;

  bool get isFailed => stage == DaftariRecoveryStage.failed.name;

  bool get isImported => stage == DaftariRecoveryStage.imported.name;

  bool get isReview => stage == DaftariRecoveryStage.review.name;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'created_at': createdAt,
      'stage': stage,
      'image_path': imagePath,
      'raw_text': rawText,
      'extracted_lines_json': _encodeStringList(extractedLines),
      'lines_json': _encodeLineList(lines),
      'matched_count': matchedCount,
      'unresolved_count': unresolvedCount,
      'confidence': confidence,
      'estimated_total': estimatedTotal,
      'imported_order_id': importedOrderId,
      'failure_reason': failureReason,
    };
  }

  factory DaftariRecoverySession.fromMap(Map<String, Object?> map) {
    return DaftariRecoverySession(
      id: map['id'] as String,
      createdAt: map['created_at'] as String,
      stage: map['stage'] as String,
      imagePath: map['image_path'] as String?,
      rawText: map['raw_text'] as String? ?? '',
      extractedLines: _decodeStringList(map['extracted_lines_json'] as String?),
      lines: _decodeLineList(map['lines_json'] as String?),
      matchedCount: (map['matched_count'] as num?)?.toInt() ?? 0,
      unresolvedCount: (map['unresolved_count'] as num?)?.toInt() ?? 0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      estimatedTotal: (map['estimated_total'] as num?)?.toDouble() ?? 0,
      importedOrderId: map['imported_order_id'] as String?,
      failureReason: map['failure_reason'] as String?,
    );
  }
}

class DaftariRecoveryLine {
  const DaftariRecoveryLine({
    required this.rawText,
    required this.productName,
    required this.quantity,
    required this.matchScore,
    required this.include,
    this.productCode,
    this.matchedProductName,
    this.observedAmount,
    this.wasManuallyCorrected = false,
  });

  final String rawText;
  final String productName;
  final int quantity;
  final double matchScore;
  final bool include;
  final String? productCode;
  final String? matchedProductName;
  final int? observedAmount;
  final bool wasManuallyCorrected;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'raw_text': rawText,
      'product_name': productName,
      'quantity': quantity,
      'match_score': matchScore,
      'include': include ? 1 : 0,
      'product_code': productCode,
      'matched_product_name': matchedProductName,
      'observed_amount': observedAmount,
      'was_manually_corrected': wasManuallyCorrected ? 1 : 0,
    };
  }

  factory DaftariRecoveryLine.fromMap(Map<String, Object?> map) {
    return DaftariRecoveryLine(
      rawText: map['raw_text'] as String? ?? '',
      productName: map['product_name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      matchScore: (map['match_score'] as num?)?.toDouble() ?? 0,
      include: (map['include'] as num?)?.toInt() == 1,
      productCode: map['product_code'] as String?,
      matchedProductName: map['matched_product_name'] as String?,
      observedAmount: (map['observed_amount'] as num?)?.toInt(),
      wasManuallyCorrected: (map['was_manually_corrected'] as num?)?.toInt() == 1,
    );
  }

  ProductItem? resolveProduct(List<ProductItem> catalog) {
    if (productCode == null) return null;
    for (final product in catalog) {
      if (product.code == productCode) return product;
    }
    for (final product in catalog) {
      if (product.name == matchedProductName) return product;
    }
    return null;
  }
}

class DaftariLearningRule {
  const DaftariLearningRule({
    required this.id,
    required this.sourceText,
    required this.targetProductCode,
    required this.targetProductName,
    required this.createdAt,
    required this.hitCount,
    required this.lastUsedAt,
  });

  final String id;
  final String sourceText;
  final String targetProductCode;
  final String targetProductName;
  final String createdAt;
  final int hitCount;
  final String lastUsedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'source_text': sourceText,
      'target_product_code': targetProductCode,
      'target_product_name': targetProductName,
      'created_at': createdAt,
      'hit_count': hitCount,
      'last_used_at': lastUsedAt,
    };
  }

  factory DaftariLearningRule.fromMap(Map<String, Object?> map) {
    return DaftariLearningRule(
      id: map['id'] as String,
      sourceText: map['source_text'] as String,
      targetProductCode: map['target_product_code'] as String,
      targetProductName: map['target_product_name'] as String,
      createdAt: map['created_at'] as String,
      hitCount: (map['hit_count'] as num?)?.toInt() ?? 0,
      lastUsedAt: map['last_used_at'] as String,
    );
  }
}

enum DaftariRecoveryStage {
  scan,
  ocr,
  matching,
  review,
  imported,
  failed,
}

String _encodeStringList(List<String> values) {
  return values.map((value) => value.replaceAll('"', '\\"')).join('\u001f');
}

List<String> _decodeStringList(String? value) {
  if (value == null || value.isEmpty) return const <String>[];
  return value.split('\u001f').map((item) => item.replaceAll('\\"', '"')).toList();
}

String _encodeLineList(List<DaftariRecoveryLine> values) {
  final encoded = values.map((line) {
    final fields = <String>[
      line.rawText,
      line.productName,
      line.quantity.toString(),
      line.matchScore.toString(),
      line.include ? '1' : '0',
      line.productCode ?? '',
      line.matchedProductName ?? '',
      line.observedAmount?.toString() ?? '',
      line.wasManuallyCorrected ? '1' : '0',
    ].map((value) => value.replaceAll('|', r'\|')).toList();
    return fields.join('|');
  }).toList();
  return encoded.join('\u001e');
}

List<DaftariRecoveryLine> _decodeLineList(String? value) {
  if (value == null || value.isEmpty) return const <DaftariRecoveryLine>[];
  return value.split('\u001e').map((row) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var escaped = false;
    for (var i = 0; i < row.length; i++) {
      final character = row[i];
      if (escaped) {
        buffer.write(character);
        escaped = false;
        continue;
      }
      if (character == r'\') {
        escaped = true;
        continue;
      }
      if (character == '|') {
        fields.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(character);
    }
    fields.add(buffer.toString());
    while (fields.length < 9) {
      fields.add('');
    }
    return DaftariRecoveryLine(
      rawText: fields[0],
      productName: fields[1],
      quantity: int.tryParse(fields[2]) ?? 0,
      matchScore: double.tryParse(fields[3]) ?? 0,
      include: fields[4] == '1',
      productCode: fields[5].isEmpty ? null : fields[5],
      matchedProductName: fields[6].isEmpty ? null : fields[6],
      observedAmount: fields[7].isEmpty ? null : int.tryParse(fields[7]),
      wasManuallyCorrected: fields[8] == '1',
    );
  }).toList();
}
