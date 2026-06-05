import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ocr_native/flutter_ocr_native.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final sessions = store.daftariSessions;
    final recentSessions = sessions.take(4).toList();
    final baseTheme = Theme.of(context);
    final pageTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: BackdropGlow()),
              Column(
                children: [
                  _DaftariScanHeroHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 132),
                      children: [
                        _StartScanHeroCard(
                          isScanning: _isScanning,
                          onScanTap: _scanFromCamera,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.photo_outlined,
                                label: 'Import from\nGallery',
                                onTap: _scanFromGallery,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.mic_none_rounded,
                                label: 'Voice Note',
                                onTap: () {
                                  showMarketNotice(
                                    context,
                                    title: 'Coming Soon',
                                    message:
                                        'Voice note capture will be added next.',
                                    type: MarketNoticeType.warning,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recent Scans',
                                style:
                                    Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF36D399),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sessions.isEmpty
                                      ? 'No scans yet'
                                      : 'Synced ${_relativeSessionTime(sessions.first.createdAt)}',
                                  style: const TextStyle(
                                    color: Color(0xFF7A8393),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (recentSessions.isEmpty)
                          const _EmptyRecentScansState()
                        else
                          ...recentSessions.map(
                            (session) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _RecentScanCard(session: session),
                            ),
                          ),
                        if (_isScanning) ...[
                          const SizedBox(height: 4),
                          const _LoadingCard(),
                        ] else if (_scanResult != null) ...[
                          const SizedBox(height: 4),
                          _SimpleResultCard(
                            summary: _scanSummary ?? 'Scan processed successfully.',
                            matchedCount: _reviewLines
                                .where((line) => line.include && line.selectedProduct != null)
                                .length,
                            unresolvedCount: _reviewLines
                                .where((line) => line.selectedProduct == null)
                                .length,
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _ErrorCard(message: _errorMessage!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: _DaftariBottomNav(
                  currentIndex: 0,
                  onHomeTap: () {},
                  onHistoryTap: () {
                    showMarketNotice(
                      context,
                      title: 'History',
                      message: 'Recent scan history is shown on this screen.',
                    );
                  },
                  onSyncTap: () {
                    showMarketNotice(
                      context,
                      title: 'Sync Status',
                      message: 'Your scans are synced automatically.',
                    );
                  },
                  onSettingsTap: () {
                    showMarketNotice(
                      context,
                      title: 'Settings',
                      message: 'Scan settings are not configured yet.',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
    final detectedCount = _reviewLines.length;
    final baseTheme = Theme.of(context);
    final pageTheme = baseTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF070B12),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );

    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B12),
        body: Stack(
          children: [
            const Positioned.fill(child: _DarkReviewBackdrop()),
            SafeArea(
              child: Column(
                children: [
                  _ReviewSyncHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                    onHelp: () {
                      showMarketNotice(
                        context,
                        title: 'Review Help',
                        message:
                            'Check the matched items, edit any wrong rows, then sync the scan to POS.',
                      );
                    },
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        _ProcessingStatusHeader(
                          detectedCount: detectedCount,
                          matchedCount: matchedCount,
                        ),
                        const SizedBox(height: 18),
                        if (_scanResult != null)
                          _ReviewGroupsCard(
                            reviewLines: _reviewLines,
                            catalog: store.products,
                            matchedCount: matchedCount,
                            unresolvedCount: unresolvedCount,
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
                                  _reviewLines[index].selectedProduct = _bestMatch(
                                    _reviewLines[index].source.productName,
                                    store.products,
                                  );
                                }
                              });
                            },
                          )
                        else if (_isScanning)
                          const _DarkLoadingCard()
                        else if (_errorMessage != null)
                          _DarkErrorCard(message: _errorMessage!)
                        else
                          const _DarkEmptyState(),
                        const SizedBox(height: 18),
                        _ScannedNotePreview(
                          path: _selectedImage?.path,
                          onTap: _selectedImage == null
                              ? null
                              : () {
                                  showMarketNotice(
                                    context,
                                    title: 'Preview',
                                    message:
                                        'The scanned note preview can be enlarged here in a future update.',
                                  );
                                },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 66,
                          child: _PrimarySyncButton(
                            label: 'Sync to POS',
                            onTap: _importToCheckout,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _SecurityNote(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaftariScanHeroHeader extends StatelessWidget {
  const _DaftariScanHeroHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFE1E6ED)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060E1726),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.ink,
                size: 25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daftari Scan',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.02,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Scan. Organize. Simplify.',
                  style: TextStyle(
                    color: Color(0xFF7A8393),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartScanHeroCard extends StatelessWidget {
  const _StartScanHeroCard({
    required this.isScanning,
    required this.onScanTap,
  });

  final bool isScanning;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isScanning ? null : onScanTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: const Color(0xFFE1E6ED), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x330F172A),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                isScanning ? Icons.hourglass_top_rounded : Icons.camera_alt_outlined,
                color: const Color(0xFF1B9B69),
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isScanning ? 'Scanning...' : 'Start New Scan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Capture handwritten notes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7A8393),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE1E6ED)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1B9B69), size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8A94A6),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({
    required this.session,
  });

  final DaftariRecoverySession session;

  @override
  Widget build(BuildContext context) {
    final created = DateTime.tryParse(session.createdAt);
    final titleNumber = _scanNumberFromId(session.id);
    final subtitle = created == null
        ? 'Recently processed'
        : '${_formatDaftariDate(created)} • ${_formatDaftariTime(created)}';

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E6ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _RecentScanThumb(path: session.imagePath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan #$titleNumber',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _money(session.estimatedTotal),
                  style: const TextStyle(
                    color: Color(0xFF1B9B69),
                    fontSize: 16.5,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$subtitle • ${session.matchedCount} matched',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7A8393),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0x99FFFFFF),
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _RecentScanThumb extends StatelessWidget {
  const _RecentScanThumb({
    this.path,
  });

  final String? path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 96,
        height: 96,
        color: const Color(0xFFF5F7FA),
        child: path != null && path!.isNotEmpty
            ? Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _RecentScanThumbPlaceholder(),
              )
            : _RecentScanThumbPlaceholder(),
      ),
    );
  }
}

class _RecentScanThumbPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: const Center(
        child: Icon(
          Icons.receipt_long_rounded,
          color: Color(0xFF8A94A6),
          size: 36,
        ),
      ),
    );
  }
}

class _EmptyRecentScansState extends StatelessWidget {
  const _EmptyRecentScansState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E6ED)),
      ),
      child: const Text(
        'No recent scans yet. Start your first scan above.',
        style: TextStyle(
          color: Color(0xFF7A8393),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}

class _DaftariBottomNav extends StatelessWidget {
  const _DaftariBottomNav({
    required this.currentIndex,
    required this.onHomeTap,
    required this.onHistoryTap,
    required this.onSyncTap,
    required this.onSettingsTap,
  });

  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onSyncTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1E6ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 14,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DaftariNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: onHomeTap,
            ),
          ),
          Expanded(
            child: _DaftariNavItem(
              icon: Icons.history_rounded,
              label: 'History',
              selected: currentIndex == 1,
              onTap: onHistoryTap,
            ),
          ),
          Expanded(
            child: _DaftariNavItem(
              icon: Icons.cloud_done_outlined,
              label: 'Sync Status',
              selected: currentIndex == 2,
              onTap: onSyncTap,
            ),
          ),
          Expanded(
            child: _DaftariNavItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: currentIndex == 3,
              onTap: onSettingsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaftariNavItem extends StatelessWidget {
  const _DaftariNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF1B9B69) : const Color(0xFF8A94A6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3.5,
            width: selected ? 38 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF1B9B69),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double value) {
  final whole = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return 'TSH $buffer';
}

String _formatDaftariDate(DateTime value) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _formatDaftariTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _relativeSessionTime(String createdAt) {
  final created = DateTime.tryParse(createdAt);
  if (created == null) return 'just now';
  final diff = DateTime.now().difference(created);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
  if (diff.inHours < 24) return '${diff.inHours} hrs ago';
  return '${diff.inDays} days ago';
}

String _scanNumberFromId(String id) {
  final digits = RegExp(r'(\d+)$').firstMatch(id)?.group(1);
  if (digits != null && digits.isNotEmpty) return digits;
  final fallback = id.hashCode.abs() % 90 + 10;
  return fallback.toString();
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

class _DarkReviewBackdrop extends StatelessWidget {
  const _DarkReviewBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF04060A), Color(0xFF0B1120), Color(0xFF05070B)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            left: -40,
            child: _DarkGlowBlob(
              size: 220,
              color: Color(0x3310B981),
            ),
          ),
          Positioned(
            top: 180,
            right: -30,
            child: _DarkGlowBlob(
              size: 180,
              color: Color(0x222563EB),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 20,
            child: _DarkGlowBlob(
              size: 180,
              color: Color(0x1810B981),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkGlowBlob extends StatelessWidget {
  const _DarkGlowBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _ReviewSyncHeader extends StatelessWidget {
  const _ReviewSyncHeader({
    required this.onBack,
    required this.onHelp,
  });

  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundHeaderButton(icon: Icons.chevron_left_rounded, onTap: onBack),
          const Expanded(
            child: Text(
              'Review & Sync',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
          ),
          _RoundHeaderButton(icon: Icons.help_outline_rounded, onTap: onHelp),
        ],
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _ProcessingStatusHeader extends StatelessWidget {
  const _ProcessingStatusHeader({
    required this.detectedCount,
    required this.matchedCount,
  });

  final int detectedCount;
  final int matchedCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF16C38D),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF14B87D),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5514B87D),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF16C38D),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Processing Complete',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF18BE87),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$detectedCount item${detectedCount == 1 ? '' : 's'} detected',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC9CFD9),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.05,
          ),
        ),
        if (matchedCount > 0) ...[
          const SizedBox(height: 4),
          Text(
            '$matchedCount matched and ready to sync',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7EE2B8),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewGroupsCard extends StatelessWidget {
  const _ReviewGroupsCard({
    required this.reviewLines,
    required this.catalog,
    required this.matchedCount,
    required this.unresolvedCount,
    required this.onApplyBestMatches,
    required this.onClearSelections,
    required this.onQuantityChanged,
    required this.onProductChanged,
    required this.onToggleInclude,
  });

  final List<_ReviewLine> reviewLines;
  final List<ProductItem> catalog;
  final int matchedCount;
  final int unresolvedCount;
  final VoidCallback onApplyBestMatches;
  final VoidCallback onClearSelections;
  final void Function(int index, int quantity) onQuantityChanged;
  final void Function(int index, ProductItem? product) onProductChanged;
  final void Function(int index, bool include) onToggleInclude;

  @override
  Widget build(BuildContext context) {
    final matchedLines = reviewLines.where((line) => line.include).toList();
    final unresolvedLines = reviewLines.where((line) => !line.include).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0F0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit if needed',
            style: TextStyle(
              color: Color(0xFF9AA3B2),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          _ReviewSectionCard(
            title: 'Matched',
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF18BE87),
            children: [
              if (matchedLines.isEmpty)
                const _DarkEmptySectionText(
                  text: 'No matched items yet. Tap Auto Match to fill them in.',
                )
              else
                ...matchedLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewLineCard(
                      line: line,
                      catalog: catalog,
                      onQuantityChanged: (value) => onQuantityChanged(reviewLines.indexOf(line), value),
                      onProductChanged: (value) => onProductChanged(reviewLines.indexOf(line), value),
                      onToggleInclude: (value) => onToggleInclude(reviewLines.indexOf(line), value),
                    ),
                  ),
                ),
            ],
          ),
          if (unresolvedLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ReviewSectionCard(
              title: 'Needs attention',
              icon: Icons.sync_problem_rounded,
              iconColor: const Color(0xFFF59E0B),
              children: [
                ...unresolvedLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewLineCard(
                      line: line,
                      catalog: catalog,
                      onQuantityChanged: (value) => onQuantityChanged(reviewLines.indexOf(line), value),
                      onProductChanged: (value) => onProductChanged(reviewLines.indexOf(line), value),
                      onToggleInclude: (value) => onToggleInclude(reviewLines.indexOf(line), value),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DarkOutlineButton(
                  label: 'Auto Match',
                  icon: Icons.auto_fix_high_outlined,
                  onTap: onApplyBestMatches,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DarkOutlineButton(
                  label: 'Clear',
                  icon: Icons.backspace_outlined,
                  onTap: onClearSelections,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewSectionCard extends StatelessWidget {
  const _ReviewSectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0x0D111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: 0.45)),
                  color: iconColor.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0x22FFFFFF)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DarkOutlineButton extends StatelessWidget {
  const _DarkOutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0x10111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF18BE87), size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkEmptySectionText extends StatelessWidget {
  const _DarkEmptySectionText({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9AA3B2),
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }
}

class _DarkLoadingCard extends StatelessWidget {
  const _DarkLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0F0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF18BE87)),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Reading text from the photo...',
              style: TextStyle(
                color: Colors.white,
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

class _DarkErrorCard extends StatelessWidget {
  const _DarkErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1A7F1D1D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF7F1D1D)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFCA5A5),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}

class _DarkEmptyState extends StatelessWidget {
  const _DarkEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0F0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: const Text(
        'Scan a note to see items ready for review.',
        style: TextStyle(
          color: Color(0xFF9AA3B2),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ScannedNotePreview extends StatelessWidget {
  const _ScannedNotePreview({
    this.path,
    this.onTap,
  });

  final String? path;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0x0F0F172A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scanned Note (Preview)',
              style: TextStyle(
                color: Color(0xFF9AA3B2),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 136,
                    height: 170,
                    color: const Color(0xFF151A23),
                    child: path != null && path!.isNotEmpty
                        ? Image.file(
                            File(path!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _PreviewPlaceholder(),
                          )
                        : const _PreviewPlaceholder(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x26FFFFFF)),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to enlarge',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFBAC2D0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF151A23),
      child: Center(
        child: Icon(
          Icons.receipt_long_rounded,
          color: Color(0xFF6B7280),
          size: 38,
        ),
      ),
    );
  }
}

class _PrimarySyncButton extends StatelessWidget {
  const _PrimarySyncButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF15A86F), Color(0xFF27C67D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x5527C67D),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF6B7280),
          size: 18,
        ),
        SizedBox(width: 8),
        Text(
          'Your data is secure and encrypted',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    final estimatedTotal = (selectedProduct == null
            ? 0.0
            : selectedProduct.priceValue * line.quantity)
        .toDouble();
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
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selectedProduct == null
              ? const Color(0xFF7F1D1D)
              : const Color(0xFF273244),
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
                activeColor: const Color(0xFF27C67D),
                checkColor: Colors.white,
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
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedProduct == null
                          ? 'No match yet'
                          : 'Matched to ${selectedProduct.name}',
                      style: TextStyle(
                        color: selectedProduct == null
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFB4DCC6),
                        fontSize: 11.5,
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
                        color: confidenceColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: confidenceColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        confidenceLabel,
                        style: TextStyle(
                          color: confidenceColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _money(estimatedTotal),
                style: const TextStyle(
                  color: Color(0xFF27C67D),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  showMarketNotice(
                    context,
                    title: 'Edit row',
                    message:
                        'Use the product dropdown below to adjust the selected item.',
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Color(0xFFB8C0CC),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ProductItem?>(
            initialValue: selectedProduct,
            dropdownColor: const Color(0xFF0F172A),
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            iconEnabledColor: const Color(0xFFB8C0CC),
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
            decoration: InputDecoration(
              labelText: 'Product',
              isDense: true,
              labelStyle: const TextStyle(color: Color(0xFF9AA3B2)),
              filled: true,
              fillColor: const Color(0xFF0B1220),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF273244)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF273244)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF27C67D)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Qty',
                style: TextStyle(
                  color: Color(0xFFC9CFD9),
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
                color: const Color(0xFF27C67D),
              ),
              Text(
                line.quantity.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => onQuantityChanged(line.quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
                visualDensity: VisualDensity.compact,
                color: const Color(0xFF27C67D),
              ),
              const Spacer(),
              if (line.source.observedAmount != null)
                Text(
                  'Note TSh${line.source.observedAmount}',
                  style: const TextStyle(
                    color: Color(0xFF9AA3B2),
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
