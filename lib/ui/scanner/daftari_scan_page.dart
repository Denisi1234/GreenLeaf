import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ocr_native/flutter_ocr_native.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../service/daftari_scan_parser.dart';
import '../../service/daftari_recovery_models.dart';
import '../../service/pos_local_store.dart';
import '../models/product_item.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

enum DaftariScanMode {
  drawer,
  checkout,
}

class DaftariScanPage extends StatefulWidget {
  const DaftariScanPage({
    super.key,
    this.mode = DaftariScanMode.drawer,
  });

  final DaftariScanMode mode;

  @override
  State<DaftariScanPage> createState() => _DaftariScanPageState();
}

class _DaftariScanPageState extends State<DaftariScanPage> {
  final ImagePicker _picker = ImagePicker();
  final OcrReader _reader = OcrReader();

  bool _isScanning = false;
  XFile? _selectedImage;
  DaftariScanResult? _scanResult;
  final List<_ReviewLine> _reviewLines = <_ReviewLine>[];
  String? _errorMessage;
  String? _scanSummary;
  String? _currentSessionId;
  String? _currentSessionCreatedAt;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _scanFromCamera() async {
    await _pickAndScan(ImageSource.camera);
  }

  Future<void> _scanFromGallery() async {
    await _pickAndScan(ImageSource.gallery);
  }

  Future<void> _pickAndScan(ImageSource source) async {
    if (_isScanning) return;

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (image == null || !mounted) return;

      final store = context.read<PosLocalStore>();
      final learnedAliases = store.daftariLearningAliases;
      setState(() {
        _selectedImage = image;
        _isScanning = true;
        _scanResult = null;
        _errorMessage = null;
        _scanSummary = null;
        _currentSessionId = 'daftari-${DateTime.now().microsecondsSinceEpoch}';
        _currentSessionCreatedAt = DateTime.now().toIso8601String();
      });

      final recognizedText = await _reader.readFromPath(image.path);
      if (!mounted) return;
      final parsed = parseDaftariText(
        recognizedText.text,
        store.products,
        learnedAliases: learnedAliases,
      );

      setState(() {
        _scanResult = parsed;
        _reviewLines
          ..clear()
          ..addAll(
            _buildReviewLines(parsed, store.products),
          );
      });

      if (widget.mode == DaftariScanMode.drawer) {
        await _autoImportScanResults();
      } else {
        await _persistSession(stage: DaftariRecoveryStage.review);
      }
    } on UnsupportedError {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'OCR scanning is not available on this device. Use a supported mobile or desktop build, or try a clearer image.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not scan the daftari image: $error';
      });
      await _persistSession(
        stage: DaftariRecoveryStage.failed,
        failureReason: error.toString(),
      );
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Scan Failed',
        message: 'We could not read text from that image',
        type: MarketNoticeType.warning,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _autoImportScanResults() async {
    final store = context.read<PosLocalStore>();
    var importedItems = 0;
    var importedLines = 0;

    for (final line in _reviewLines) {
      final product = line.selectedProduct;
      if (!line.include || product == null) continue;

      final didAdd = store.addToCartQuantity(product, line.quantity);
      if (!didAdd) continue;

      importedItems += line.quantity;
      importedLines += 1;

      if (line.source.matchedProduct?.name != product.name ||
          line.source.productName.toLowerCase() != product.name.toLowerCase()) {
        await store.rememberDaftariCorrection(
          sourceText: line.source.productName,
          product: product,
        );
      }
    }

    await _persistSession(
      stage: importedLines > 0
          ? DaftariRecoveryStage.imported
          : DaftariRecoveryStage.review,
    );

    if (!mounted) return;
    setState(() {
      if (importedLines > 0) {
        _scanSummary =
            'Imported $importedItems item${importedItems == 1 ? '' : 's'} from ${widget.mode == DaftariScanMode.drawer ? 'Scan Daftari' : 'the scan'}';
      } else {
        _scanSummary = 'Scan complete. No items were matched strongly enough to import automatically.';
      }
    });

    showMarketNotice(
      context,
      title: importedLines > 0 ? 'Scan Complete' : 'Scan Saved',
      message: importedLines > 0
          ? 'Items were added to the cart automatically'
          : 'The scan was processed, but no line was imported',
      type: importedLines > 0 ? MarketNoticeType.success : MarketNoticeType.warning,
    );
  }

  void _importToCheckout() {
    final importLines = _buildImportLines();
    if (importLines.isEmpty) {
      _persistSession(stage: DaftariRecoveryStage.review);
      if (widget.mode == DaftariScanMode.checkout) {
        showMarketNotice(
          context,
          title: 'Nothing To Import',
          message: 'Resolve at least one row before importing',
          type: MarketNoticeType.warning,
        );
      } else {
        showMarketNotice(
          context,
          title: 'Draft Saved',
          message: 'The scan is stored and can be reopened from the Smart Recovery history.',
        );
      }
      return;
    }

    final stage = widget.mode == DaftariScanMode.checkout
        ? DaftariRecoveryStage.imported
        : DaftariRecoveryStage.review;
    _persistSession(stage: stage);
    if (widget.mode == DaftariScanMode.checkout) {
      Navigator.of(context).pop(importLines);
      return;
    }

    showMarketNotice(
      context,
      title: 'Recovery Saved',
      message: 'The daftari scan has been stored for review and future training.',
    );
  }

  void _applyBestMatches() {
    final store = context.read<PosLocalStore>();
    setState(() {
      for (final line in _reviewLines) {
        final best = line.source.matchedProduct ??
            _bestMatch(line.source.productName, store.products);
        line.selectedProduct = best;
        line.include = best != null;
      }
    });
  }

  void _clearSelections() {
    setState(() {
      for (final line in _reviewLines) {
        line.selectedProduct = null;
        line.include = false;
      }
    });
  }

  List<DaftariScanLine> _buildImportLines() {
    return _reviewLines
        .where((line) => line.include && line.selectedProduct != null)
        .map(
          (line) => DaftariScanLine(
            rawText: line.source.rawText,
            productName: line.selectedProduct!.name,
            quantity: line.quantity,
            matchedProduct: line.selectedProduct,
            observedAmount: line.source.observedAmount,
            matchScore: line.source.matchScore,
          ),
        )
        .toList();
  }

  Future<void> _persistSession({
    required DaftariRecoveryStage stage,
    String? failureReason,
  }) async {
    if (_currentSessionId == null) return;
    if (_scanResult == null && stage != DaftariRecoveryStage.failed) return;

    final store = context.read<PosLocalStore>();
    final reviewLines = _buildCurrentRecoveryLines();
    final matchedCount =
        reviewLines.where((line) => line.include && line.productCode != null).length;
    final unresolvedCount =
        reviewLines.where((line) => line.include && line.productCode == null).length;
    final confidence = reviewLines.isEmpty
        ? 0.0
        : reviewLines.fold<double>(0.0, (sum, line) => sum + line.matchScore) /
            reviewLines.length;
    final estimatedTotal = _reviewLines.fold<double>(0, (sum, line) {
      if (!line.include || line.selectedProduct == null) return sum;
      return sum + (line.selectedProduct!.priceValue * line.quantity);
    });

    await store.saveDaftariSession(
      DaftariRecoverySession(
        id: _currentSessionId!,
        createdAt: _currentSessionCreatedAt ?? DateTime.now().toIso8601String(),
        stage: stage.name,
        imagePath: _selectedImage?.path,
        rawText: _scanResult?.rawText ?? '',
        extractedLines: _scanResult?.lines.map((line) => line.rawText).toList() ?? const <String>[],
        lines: reviewLines,
        matchedCount: matchedCount,
        unresolvedCount: unresolvedCount,
        confidence: confidence,
        estimatedTotal: estimatedTotal,
        failureReason: failureReason,
      ),
    );
  }

  List<DaftariRecoveryLine> _buildCurrentRecoveryLines() {
    return _reviewLines.map((line) {
      final selected = line.selectedProduct;
      return DaftariRecoveryLine(
        rawText: line.source.rawText,
        productName: line.source.productName,
        quantity: line.quantity,
        matchScore: line.source.matchScore,
        include: line.include,
        productCode: selected?.code,
        matchedProductName: selected?.name,
        observedAmount: line.source.observedAmount,
        wasManuallyCorrected: selected != null &&
            line.source.matchedProduct?.name != selected.name,
      );
    }).toList();
  }

  List<_ReviewLine> _buildReviewLines(
    DaftariScanResult parsed,
    List<ProductItem> catalog,
  ) {
    return parsed.lines.map((line) {
      final bestMatch = line.matchedProduct ?? _bestMatch(line.productName, catalog);
      return _ReviewLine(
        source: line,
        quantity: line.quantity,
        selectedProduct: bestMatch,
        include: bestMatch != null,
      );
    }).toList();
  }

  ProductItem? _bestMatch(String query, List<ProductItem> catalog) {
    if (catalog.isEmpty) return null;

    final normalizedQuery = _normalize(query);
    ProductItem? bestMatch;
    var bestScore = 0.0;

    for (final candidate in catalog) {
      final score = _matchScore(normalizedQuery, _normalize(candidate.name));
      if (score > bestScore) {
        bestScore = score;
        bestMatch = candidate;
      }
    }

    return bestScore >= 0.45 ? bestMatch : null;
  }

  double _matchScore(String left, String right) {
    if (left.isEmpty || right.isEmpty) return 0;
    if (left == right) return 1;
    if (left.contains(right) || right.contains(left)) return 0.95;

    final leftTokens = left.split(' ').where((item) => item.length > 1).toSet();
    final rightTokens = right.split(' ').where((item) => item.length > 1).toSet();
    final sharedTokens = leftTokens.intersection(rightTokens).length;
    final tokenDenominator = (leftTokens.length > rightTokens.length
            ? leftTokens.length
            : rightTokens.length)
        .toDouble();
    final tokenScore =
        sharedTokens.toDouble() / (tokenDenominator <= 0 ? 1.0 : tokenDenominator);

    final distance = _levenshtein(left, right);
    final normalizedLength =
        (left.length > right.length ? left.length : right.length).toDouble();
    final editScore = normalizedLength == 0
        ? 0
        : 1 - (distance / normalizedLength);

    return (tokenScore > editScore ? tokenScore : editScore).toDouble();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
        rows[j] = [
          rows[j] + 1,
          rows[j - 1] + 1,
          previousDiagonal + cost,
        ].reduce((a, b) => a < b ? a : b);
        previousDiagonal = previousRowValue;
      }
    }

    return rows[right.length];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == DaftariScanMode.drawer) {
      return _buildSimpleScannerView(context);
    }

    return _buildDetailedRecoveryView(context);
  }

  Widget _buildSimpleScannerView(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final todayScans = store.daftariSessions.length;
    final matchedCount = _reviewLines
        .where((line) => line.include && line.selectedProduct != null)
        .length;
    final unresolvedCount = _reviewLines
        .where((line) => line.selectedProduct == null)
        .length;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          Column(
            children: [
              const MarketPageHeader(title: 'Scan Daftari'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.document_scanner_outlined,
                          color: AppColors.primary,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Scan a notebook page',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap once. The app will read the page and handle the rest quietly in the background.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _NativeScanAction(
                        isScanning: _isScanning,
                        onTap: _scanFromCamera,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$todayScans scan${todayScans == 1 ? '' : 's'} processed',
                        style: const TextStyle(
                          color: Color(0xFF7A8393),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_isScanning)
                        const _LoadingCard()
                      else if (_scanResult != null)
                        _SimpleResultCard(
                          summary:
                              _scanSummary ?? 'Scan processed successfully.',
                          matchedCount: matchedCount,
                          unresolvedCount: unresolvedCount,
                        ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _ErrorCard(message: _errorMessage!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRecoveryView(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final matchedCount = _reviewLines
        .where((line) => line.include && line.selectedProduct != null)
        .length;
    final unresolvedCount = _reviewLines
        .where((line) => line.selectedProduct == null)
        .length;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          Column(
            children: [
              const MarketPageHeader(title: 'Scan Daftari'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    _ScanHeroCard(
                      isScanning: _isScanning,
                      onScanTap: _scanFromCamera,
                      onGalleryTap: _scanFromGallery,
                      sessionCount: store.daftariSessions.length,
                    ),
                    const SizedBox(height: 14),
                    if (_selectedImage != null)
                      _ImagePreview(path: _selectedImage!.path),
                    if (_selectedImage != null) const SizedBox(height: 14),
                    if (_isScanning)
                      const _LoadingCard()
                    else if (_scanResult != null)
                      _ScanSummaryCard(
                        matchedCount: matchedCount,
                        unresolvedCount: unresolvedCount,
                        reviewLines: _reviewLines,
                        catalog: store.products,
                        onApplyBestMatches: _applyBestMatches,
                        onClearSelections: _clearSelections,
                        onQuantityChanged: (index, quantity) {
                          setState(() {
                            _reviewLines[index].quantity = quantity;
                          });
                        },
                        onProductChanged: (index, product) {
                          setState(() {
                            _reviewLines[index].selectedProduct = product;
                            _reviewLines[index].include = product != null;
                          });
                        },
                        onToggleInclude: (index, include) {
                          setState(() {
                            _reviewLines[index].include = include;
                            if (include &&
                                _reviewLines[index].selectedProduct == null) {
                              _reviewLines[index].selectedProduct =
                                  _bestMatch(
                                _reviewLines[index].source.productName,
                                store.products,
                              );
                            }
                          });
                        },
                        rawText: _scanResult!.rawText,
                      ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _ErrorCard(message: _errorMessage!),
                    ],
                    const SizedBox(height: 18),
                    const _ReviewNote(),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: MarketButton(
                  label: widget.mode == DaftariScanMode.checkout
                      ? 'Import To POS'
                      : 'Save Recovery Draft',
                  icon: Icons.playlist_add_check_circle_outlined,
                  onTap: _importToCheckout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleResultCard extends StatelessWidget {
  const _SimpleResultCard({
    required this.summary,
    required this.matchedCount,
    required this.unresolvedCount,
  });

  final String summary;
  final int matchedCount;
  final int unresolvedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.green),
              SizedBox(width: 10),
              Text(
                'Processed',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13.2,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SimpleStatPill(
                label: 'Matched',
                value: matchedCount.toString(),
                accent: const Color(0xFF1E7A47),
              ),
              _SimpleStatPill(
                label: 'Needs review',
                value: unresolvedCount.toString(),
                accent: const Color(0xFFB45309),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleStatPill extends StatelessWidget {
  const _SimpleStatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({
    required this.isScanning,
    required this.onScanTap,
    required this.onGalleryTap,
    required this.sessionCount,
  });

  final bool isScanning;
  final VoidCallback onScanTap;
  final VoidCallback onGalleryTap;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Scan Daftari',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const Text(
            'Point the camera at the notebook page and SmartDuka will handle OCR, matching, and import in the background.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 13.2,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          MarketButton(
            label: isScanning ? 'Scanning...' : 'Open Camera',
            icon: Icons.camera_alt_outlined,
            onTap: isScanning ? () {} : onScanTap,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: isScanning ? null : onGalleryTap,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Use gallery instead'),
          ),
          const SizedBox(height: 12),
          Text(
            '$sessionCount scan${sessionCount == 1 ? '' : 's'} handled in the background',
            style: const TextStyle(
              color: Color(0xFF7A8393),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.path,
  });

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        child: Image.file(
          File(path),
          height: 260,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _NativeScanAction extends StatelessWidget {
  const _NativeScanAction({
    required this.isScanning,
    required this.onTap,
  });

  final bool isScanning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isScanning ? null : onTap,
      child: Container(
        width: 148,
        height: 148,
        decoration: BoxDecoration(
          color: isScanning ? const Color(0xFFE9EDF5) : AppColors.ink,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isScanning ? Icons.hourglass_top_rounded : Icons.camera_alt_rounded,
              color: Colors.white,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              isScanning ? 'Scanning' : 'Start Scan',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Reading text from the photo...',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanSummaryCard extends StatelessWidget {
  const _ScanSummaryCard({
    required this.matchedCount,
    required this.unresolvedCount,
    required this.reviewLines,
    required this.catalog,
    required this.onApplyBestMatches,
    required this.onClearSelections,
    required this.onQuantityChanged,
    required this.onProductChanged,
    required this.onToggleInclude,
    required this.rawText,
  });

  final int matchedCount;
  final int unresolvedCount;
  final List<_ReviewLine> reviewLines;
  final List<ProductItem> catalog;
  final VoidCallback onApplyBestMatches;
  final VoidCallback onClearSelections;
  final void Function(int index, int quantity) onQuantityChanged;
  final void Function(int index, ProductItem? product) onProductChanged;
  final void Function(int index, bool include) onToggleInclude;
  final String rawText;

  int get _resolvedCount =>
      reviewLines.where((line) => line.include && line.selectedProduct != null).length;

  double get _estimatedTotal => reviewLines.fold<double>(
        0,
        (sum, line) {
          if (!line.include || line.selectedProduct == null) return sum;
          return sum + (line.selectedProduct!.priceValue * line.quantity);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review $_resolvedCount line(s)',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$matchedCount matched, $unresolvedCount still need attention',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TSh${_estimatedTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Estimated import',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MarketButton(
                  label: 'Auto Match',
                  icon: Icons.auto_fix_high_outlined,
                  onTap: onApplyBestMatches,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MarketButton(
                  label: 'Clear',
                  icon: Icons.backspace_outlined,
                  isPrimary: false,
                  onTap: onClearSelections,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(reviewLines.length, (index) {
            final line = reviewLines[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReviewLineCard(
                line: line,
                catalog: catalog,
                onQuantityChanged: (value) => onQuantityChanged(index, value),
                onProductChanged: (value) => onProductChanged(index, value),
                onToggleInclude: (value) => onToggleInclude(index, value),
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            'Recognized text',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              rawText.trim().isEmpty ? 'No text recognized' : rawText.trim(),
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewLineCard extends StatelessWidget {
  const _ReviewLineCard({
    required this.line,
    required this.catalog,
    required this.onQuantityChanged,
    required this.onProductChanged,
    required this.onToggleInclude,
  });

  final _ReviewLine line;
  final List<ProductItem> catalog;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<ProductItem?> onProductChanged;
  final ValueChanged<bool> onToggleInclude;

  @override
  Widget build(BuildContext context) {
    final selectedProduct = line.selectedProduct;
    final estimatedTotal =
        selectedProduct == null ? 0 : selectedProduct.priceValue * line.quantity;
    final confidence = line.source.matchScore;
    final confidenceLabel = confidence >= 0.85
        ? 'High confidence'
        : confidence >= 0.65
            ? 'Medium confidence'
            : 'Low confidence';
    final confidenceColor = confidence >= 0.85
        ? const Color(0xFF027A48)
        : confidence >= 0.65
            ? const Color(0xFFB54708)
            : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(
          color: selectedProduct == null
              ? const Color(0xFFFECACA)
              : const Color(0xFFD0D5DD),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: line.include,
                onChanged: (value) => onToggleInclude(value ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.source.productName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedProduct == null
                          ? 'No match yet'
                          : 'Matched to ${selectedProduct.name}',
                      style: TextStyle(
                        color: selectedProduct == null
                            ? const Color(0xFFB42318)
                            : const Color(0xFF475467),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: confidenceColor.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        confidenceLabel,
                        style: TextStyle(
                          color: confidenceColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'TSh${estimatedTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ProductItem?>(
            initialValue: selectedProduct,
            items: [
              const DropdownMenuItem<ProductItem?>(
                value: null,
                child: Text('Choose product'),
              ),
              ...catalog.map(
                (product) => DropdownMenuItem<ProductItem?>(
                  value: product,
                  child: Text(product.name),
                ),
              ),
            ],
            onChanged: onProductChanged,
            decoration: const InputDecoration(
              labelText: 'Product',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Qty',
                style: TextStyle(
                  color: Color(0xFF475467),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: line.quantity > 1
                    ? () => onQuantityChanged(line.quantity - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                visualDensity: VisualDensity.compact,
                color: AppColors.primary,
              ),
              Text(
                line.quantity.toString(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => onQuantityChanged(line.quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
                visualDensity: VisualDensity.compact,
                color: AppColors.primary,
              ),
              const Spacer(),
              if (line.source.observedAmount != null)
                Text(
                  'Note TSh${line.source.observedAmount}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewLine {
  _ReviewLine({
    required this.source,
    required this.quantity,
    required this.selectedProduct,
    required this.include,
  });

  final DaftariScanLine source;
  int quantity;
  ProductItem? selectedProduct;
  bool include;
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReviewNote extends StatelessWidget {
  const _ReviewNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        'Always review the imported items before charging the sale. Handwritten notes can be imperfect, so the POS should stay in control.',
        style: TextStyle(
          color: Color(0xFF92400E),
          fontSize: 12.5,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
