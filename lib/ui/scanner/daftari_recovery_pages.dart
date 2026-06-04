import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/daftari_recovery_models.dart';
import '../../service/pos_local_store.dart';
import '../models/product_item.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class DaftariOcrProcessingPage extends StatelessWidget {
  const DaftariOcrProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<PosLocalStore>().latestDaftariSession;
    return _RecoveryScaffold(
      selectedItem: 'OCR Processing',
      title: 'OCR Processing',
      child: _SessionFocusView(
        session: session,
        emptyTitle: 'No scan has been processed yet',
        emptyMessage: 'Open Scan Daftari first, then return here to inspect the OCR output.',
        childBuilder: (session) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricStrip(session: session),
              const SizedBox(height: 14),
              _RecoveryBlock(
                title: 'Extracted text',
                child: SelectableText(
                  session.rawText.isEmpty ? 'No text recognized' : session.rawText,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _RecoveryBlock(
                title: 'Detected lines',
                child: Column(
                  children: session.extractedLines
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _LineSummaryTile(
                            title: line,
                            subtitle: 'Raw OCR text',
                            accent: const Color(0xFF2B6FE8),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DaftariMatchingPage extends StatefulWidget {
  const DaftariMatchingPage({
    super.key,
    this.sessionId,
  });

  final String? sessionId;

  @override
  State<DaftariMatchingPage> createState() => _DaftariMatchingPageState();
}

class _DaftariMatchingPageState extends State<DaftariMatchingPage> {
  final Map<String, ProductItem?> _manualMatches = <String, ProductItem?>{};
  final Map<String, int> _quantities = <String, int>{};
  final Map<String, bool> _included = <String, bool>{};
  final Map<String, bool> _manualFlags = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final session = widget.sessionId == null
        ? store.latestDaftariSession
        : store.daftariSessionById(widget.sessionId!);
    return _RecoveryScaffold(
      selectedItem: 'AI Matching',
      title: 'AI Product Matching',
      child: _SessionFocusView(
        session: session,
        emptyTitle: 'No scan available to match',
        emptyMessage: 'Capture a daftari page first so the matcher has text to work with.',
        childBuilder: (session) {
          final lines = _editedLines(session, store.products);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricStrip(session: session),
              const SizedBox(height: 14),
              _RecoveryBlock(
                title: 'Match notebook text to inventory',
                child: Column(
                  children: lines
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MatchingLineCard(
                            line: line,
                            catalog: store.products,
                            onIncludeChanged: (value) {
                              setState(() {
                                _included[line.rawText] = value;
                              });
                            },
                            onQuantityChanged: (value) {
                              setState(() {
                                _quantities[line.rawText] = value;
                              });
                            },
                            onProductChanged: (value) {
                              setState(() {
                                _manualMatches[line.rawText] = value;
                                _manualFlags[line.rawText] = true;
                                if (value != null) {
                                  _included[line.rawText] = true;
                                }
                              });
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MarketButton(
                      label: 'Save Matches',
                      icon: Icons.save_outlined,
                      onTap: () => _saveMatches(context, session, store.products),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MarketButton(
                      label: 'Review Sales',
                      icon: Icons.fact_check_outlined,
                      isPrimary: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DaftariReviewSalesPage(
                              sessionId: session.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<_MatchLineView> _editedLines(
    DaftariRecoverySession session,
    List<ProductItem> catalog,
  ) {
    return session.lines.map((line) {
      final resolved = line.resolveProduct(catalog);
      final product = _manualMatches[line.rawText] ?? resolved;
      final quantity = _quantities[line.rawText] ?? line.quantity;
      final include = _included[line.rawText] ?? line.include;
      final manual = _manualFlags[line.rawText] ?? line.wasManuallyCorrected;
      return _MatchLineView(
        line: line,
        resolvedProduct: product,
        quantity: quantity,
        include: include,
        manual: manual,
      );
    }).toList();
  }

  Future<void> _saveMatches(
    BuildContext context,
    DaftariRecoverySession session,
    List<ProductItem> catalog,
  ) async {
    final store = context.read<PosLocalStore>();
    final lines = _editedLines(session, catalog);
    final savedSession = DaftariRecoverySession(
      id: session.id,
      createdAt: session.createdAt,
      stage: DaftariRecoveryStage.matching.name,
      imagePath: session.imagePath,
      rawText: session.rawText,
      extractedLines: session.extractedLines,
      lines: lines
          .map(
            (line) => DaftariRecoveryLine(
              rawText: line.line.rawText,
              productName: line.line.productName,
              quantity: line.quantity,
              matchScore: line.line.matchScore,
              include: line.include,
              productCode: line.resolvedProduct?.code,
              matchedProductName: line.resolvedProduct?.name,
              observedAmount: line.line.observedAmount,
              wasManuallyCorrected: line.manual || line.line.wasManuallyCorrected,
            ),
          )
          .toList(),
      matchedCount:
          lines.where((line) => line.include && line.resolvedProduct != null).length,
      unresolvedCount:
          lines.where((line) => line.include && line.resolvedProduct == null).length,
      confidence: lines.isEmpty
          ? 0.0
          : lines.fold<double>(0.0, (sum, line) => sum + line.line.matchScore) /
              lines.length,
      estimatedTotal: lines.fold<double>(0.0, (sum, line) {
        if (!line.include || line.resolvedProduct == null) return sum;
        return sum + (line.resolvedProduct!.priceValue * line.quantity);
      }),
    );
    await store.saveDaftariSession(savedSession);
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: 'Matches Saved',
      message: 'Your corrections have been stored so the POS will learn them next time.',
    );
  }
}

class DaftariReviewSalesPage extends StatelessWidget {
  const DaftariReviewSalesPage({
    super.key,
    this.sessionId,
  });

  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final session = sessionId == null
        ? store.latestDaftariSession
        : store.daftariSessionById(sessionId!);
    return _RecoveryScaffold(
      selectedItem: 'Review Sales',
      title: 'Review & Confirm Sales',
      child: _SessionFocusView(
        session: session,
        emptyTitle: 'Nothing is ready to confirm',
        emptyMessage: 'Use Scan Daftari first, then review the matched lines here.',
        childBuilder: (session) {
          final readyLines = session.lines.where((line) => line.include).toList();
          final estimatedTotal = readyLines.fold<double>(
            0,
            (sum, line) {
              final product = line.resolveProduct(store.products);
              if (product == null) return sum;
              return sum + (product.priceValue * line.quantity);
            },
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricStrip(session: session),
              const SizedBox(height: 14),
              _RecoveryBlock(
                title: 'Confirm sale lines',
                child: Column(
                  children: [
                    _ReviewTableHeader(),
                    const Divider(height: 20),
                    ...readyLines.map(
                      (line) {
                        final product = line.resolveProduct(store.products);
                        final total = product == null
                            ? 0
                            : product.priceValue * line.quantity;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReviewTableRow(
                            productName: product?.name ?? line.productName,
                            quantity: line.quantity,
                            price: product == null
                                ? 'Unmatched'
                                : 'TSH ${product.priceValue.toStringAsFixed(0)}',
                            total: 'TSH ${total.toStringAsFixed(0)}',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: MarketButton(
                            label: 'Confirm Sales',
                            icon: Icons.check_circle_outline,
                            onTap: () => _confirm(context, session),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MarketButton(
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            isPrimary: false,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => DaftariMatchingPage(
                                    sessionId: session.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MarketButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      isPrimary: false,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Estimated total: TSH ${estimatedTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirm(BuildContext context, DaftariRecoverySession session) async {
    final store = context.read<PosLocalStore>();
    var importedCount = 0;
    for (final line in session.lines) {
      if (!line.include) continue;
      final product = line.resolveProduct(store.products);
      if (product == null) continue;
      final added = store.addToCartQuantity(product, line.quantity);
      if (added) {
        importedCount += line.quantity;
        if (line.wasManuallyCorrected || line.productName.toLowerCase() != product.name.toLowerCase()) {
          await store.rememberDaftariCorrection(
            sourceText: line.productName,
            product: product,
          );
        }
      }
    }

    await store.saveDaftariSession(
      DaftariRecoverySession(
        id: session.id,
        createdAt: session.createdAt,
        stage: DaftariRecoveryStage.imported.name,
        imagePath: session.imagePath,
        rawText: session.rawText,
        extractedLines: session.extractedLines,
        lines: session.lines,
        matchedCount: session.matchedCount,
        unresolvedCount: session.unresolvedCount,
        confidence: session.confidence,
        estimatedTotal: session.estimatedTotal,
        importedOrderId: session.importedOrderId,
        failureReason: session.failureReason,
      ),
    );

    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: 'Sales Confirmed',
      message: '$importedCount item(s) added to the cart and learned for next time.',
    );
  }
}

class DaftariFailedScansPage extends StatelessWidget {
  const DaftariFailedScansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<PosLocalStore>().daftariSessions.where((item) => item.isFailed).toList();
    return _RecoveryScaffold(
      selectedItem: 'Failed Scans',
      title: 'Failed Scan Center',
      child: _RecoveryListView(
        emptyTitle: 'No failed scans yet',
        emptyMessage: 'When OCR cannot read the notebook clearly, the scan appears here for recovery.',
        items: sessions,
        itemBuilder: (session) => _SessionCard(
          session: session,
          subtitle: session.failureReason ?? 'Unclear handwriting or blurry image',
          actionLabel: 'Retry',
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DaftariMatchingPage(
                  sessionId: session.id,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DaftariHistoryPage extends StatefulWidget {
  const DaftariHistoryPage({super.key});

  @override
  State<DaftariHistoryPage> createState() => _DaftariHistoryPageState();
}

class _DaftariHistoryPageState extends State<DaftariHistoryPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<PosLocalStore>().daftariSessions;
    final filtered = sessions.where((session) {
      if (_query.trim().isEmpty) return true;
      final needle = _query.toLowerCase();
      return session.rawText.toLowerCase().contains(needle) ||
          session.stage.toLowerCase().contains(needle) ||
          session.createdAt.toLowerCase().contains(needle);
    }).toList();

    return _RecoveryScaffold(
      selectedItem: 'History',
      title: 'Recovered Sales History',
      child: Column(
        children: [
          _RecoveryBlock(
            title: 'Search history',
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by text, date, or status...',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 14),
          _RecoveryListView(
            emptyTitle: 'No recovered sales yet',
            emptyMessage: 'Once a daftari scan is confirmed, it will appear here with audit details.',
            items: filtered,
            itemBuilder: (session) => _SessionCard(
              session: session,
              subtitle:
                  '${session.matchedCount} matched, ${session.unresolvedCount} unresolved',
              actionLabel: 'Re-open',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DaftariReviewSalesPage(
                      sessionId: session.id,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DaftariLearningPage extends StatelessWidget {
  const DaftariLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final rules = store.daftariLearningRules;
    return _RecoveryScaffold(
      selectedItem: 'AI Learning',
      title: 'Training / Learning Center',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RecoveryBlock(
            title: 'What the POS has learned',
            child: Text(
              'Every time a cashier corrects a daftari match, the system remembers it and improves future scans.',
              style: TextStyle(
                color: Color(0xFF475467),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _RecoveryBlock(
            title: 'Learned mappings',
            child: rules.isEmpty
                ? const _EmptyState(
                    title: 'No training yet',
                    message: 'Correct a scan once and the system will start building its memory here.',
                  )
                : Column(
                    children: rules
                        .map(
                          (rule) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LearningRuleTile(rule: rule),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class DaftariAnalyticsPage extends StatelessWidget {
  const DaftariAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sessions = store.daftariSessions;
    final imported = sessions.where((item) => item.isImported).length;
    final failed = sessions.where((item) => item.isFailed).length;
    final reviewed = sessions.where((item) => item.isReview || item.isImported).length;
    final avgConfidence = sessions.isEmpty
        ? 0.0
        : sessions.fold<double>(0, (sum, item) => sum + item.confidence) / sessions.length;

    final productCounts = <String, int>{};
    for (final session in sessions) {
      for (final line in session.lines) {
        final name = line.matchedProductName ?? line.productName;
        productCounts[name] = (productCounts[name] ?? 0) + line.quantity;
      }
    }
    final topProducts = productCounts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    return _RecoveryScaffold(
      selectedItem: 'Analytics',
      title: 'Recovery Analytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricStrip(
            session: sessions.isEmpty ? null : sessions.first,
            extraMetrics: [
              _MiniMetric(label: 'Scans', value: sessions.length.toString()),
              _MiniMetric(label: 'Reviewed', value: reviewed.toString()),
              _MiniMetric(label: 'Imported', value: imported.toString()),
              _MiniMetric(label: 'Failed', value: failed.toString()),
            ],
          ),
          const SizedBox(height: 14),
          _RecoveryBlock(
            title: 'Confidence trends',
            child: _StatTile(
              title: 'Average OCR confidence',
              value: '${(avgConfidence * 100).toStringAsFixed(0)}%',
              subtitle: 'Higher means the system is reading notebook text more clearly.',
            ),
          ),
          const SizedBox(height: 14),
          _RecoveryBlock(
            title: 'Most scanned products',
            child: topProducts.isEmpty
                ? const _EmptyState(
                    title: 'No product analytics yet',
                    message: 'Once scans are imported, the top products will appear here.',
                  )
                : Column(
                    children: topProducts.take(6).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LineSummaryTile(
                          title: entry.key,
                          subtitle: '${entry.value} units recovered',
                          accent: const Color(0xFF2B6FE8),
                          trailing: Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              color: Color(0xFF1D2939),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryScaffold extends StatelessWidget {
  const _RecoveryScaffold({
    required this.selectedItem,
    required this.title,
    required this.child,
  });

  final String selectedItem;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          Column(
            children: [
              MarketPageHeader(
                title: title,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [child],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionFocusView extends StatelessWidget {
  const _SessionFocusView({
    required this.session,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.childBuilder,
  });

  final DaftariRecoverySession? session;
  final String emptyTitle;
  final String emptyMessage;
  final Widget Function(DaftariRecoverySession session) childBuilder;

  @override
  Widget build(BuildContext context) {
    final current = session;
    if (current == null) {
      return _EmptyState(title: emptyTitle, message: emptyMessage);
    }
    return childBuilder(current);
  }
}

class _RecoveryListView extends StatelessWidget {
  const _RecoveryListView({
    required this.items,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final List<DaftariRecoverySession> items;
  final String emptyTitle;
  final String emptyMessage;
  final Widget Function(DaftariRecoverySession session) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(title: emptyTitle, message: emptyMessage);
    }
    return Column(
      children: items
          .map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: itemBuilder(session),
            ),
          )
          .toList(),
    );
  }
}

class _RecoveryBlock extends StatelessWidget {
  const _RecoveryBlock({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.session,
    this.extraMetrics = const <_MiniMetric>[],
  });

  final DaftariRecoverySession? session;
  final List<_MiniMetric> extraMetrics;

  @override
  Widget build(BuildContext context) {
    final metrics = <_MiniMetric>[
      _MiniMetric(
        label: 'OCR',
        value: session == null ? '0%' : '${(session!.confidence * 100).toStringAsFixed(0)}%',
      ),
      _MiniMetric(
        label: 'Matched',
        value: session == null ? '0' : session!.matchedCount.toString(),
      ),
      _MiniMetric(
        label: 'Need review',
        value: session == null ? '0' : session!.unresolvedCount.toString(),
      ),
      ...extraMetrics,
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics
          .map(
            (metric) => _MiniMetricChip(metric: metric),
          )
          .toList(),
    );
  }
}

class _MiniMetric {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _MiniMetricChip extends StatelessWidget {
  const _MiniMetricChip({required this.metric});

  final _MiniMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metric.label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: const TextStyle(
              color: Color(0xFF1D2939),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final DaftariRecoverySession session;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final stage = session.stage;
    final badgeColor = session.isFailed
        ? const Color(0xFFF04438)
        : session.isImported
            ? const Color(0xFF027A48)
            : const Color(0xFF2B6FE8);
    final badgeBg = badgeColor.withValues(alpha: 0.08);
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ${session.id}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  stage,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.createdAt,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          MarketButton(
            label: actionLabel,
            icon: Icons.open_in_new_outlined,
            isPrimary: false,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}

class _LearningRuleTile extends StatelessWidget {
  const _LearningRuleTile({required this.rule});

  final DaftariLearningRule rule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_alt_outlined, color: Color(0xFF2B6FE8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rule.sourceText} → ${rule.targetProductName}',
                  style: const TextStyle(
                    color: Color(0xFF1D2939),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Used ${rule.hitCount} time(s) • Last trained ${rule.lastUsedAt}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _LineSummaryTile extends StatelessWidget {
  const _LineSummaryTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1D2939),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ReviewTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('Product')),
        Expanded(child: Text('Qty')),
        Expanded(child: Text('Price')),
        Expanded(child: Text('Total')),
      ],
    );
  }
}

class _ReviewTableRow extends StatelessWidget {
  const _ReviewTableRow({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  final String productName;
  final int quantity;
  final String price;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(productName)),
        Expanded(child: Text(quantity.toString())),
        Expanded(child: Text(price)),
        Expanded(child: Text(total)),
      ],
    );
  }
}

class _MatchingLineCard extends StatelessWidget {
  const _MatchingLineCard({
    required this.line,
    required this.catalog,
    required this.onIncludeChanged,
    required this.onQuantityChanged,
    required this.onProductChanged,
  });

  final _MatchLineView line;
  final List<ProductItem> catalog;
  final ValueChanged<bool> onIncludeChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<ProductItem?> onProductChanged;

  @override
  Widget build(BuildContext context) {
    final product = line.resolvedProduct;
    final confidence = line.line.matchScore;
    final confidenceLabel = confidence >= 0.85
        ? 'High confidence'
        : confidence >= 0.65
            ? 'Medium confidence'
            : 'Low confidence';
    final confidenceColor = confidence >= 0.85
        ? const Color(0xFF027A48)
        : confidence >= 0.65
            ? const Color(0xFFB54708)
            : const Color(0xFFF04438);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(
          color: line.include ? const Color(0xFFD0D5DD) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: line.include,
                onChanged: (value) => onIncludeChanged(value ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.line.productName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product == null
                          ? 'No match yet'
                          : 'Matched to ${product.name}',
                      style: TextStyle(
                        color: product == null
                            ? const Color(0xFFB42318)
                            : const Color(0xFF475467),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
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
          const SizedBox(height: 10),
          DropdownButtonFormField<ProductItem?>(
            initialValue: product,
            items: [
              const DropdownMenuItem<ProductItem?>(
                value: null,
                child: Text('Choose product'),
              ),
              ...catalog.map(
                (item) => DropdownMenuItem<ProductItem?>(
                  value: item,
                  child: Text(item.name),
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
                onPressed: line.quantity > 1 ? () => onQuantityChanged(line.quantity - 1) : null,
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
              if (line.line.observedAmount != null)
                Text(
                  'Note TSH ${line.line.observedAmount}',
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

class _MatchLineView {
  _MatchLineView({
    required this.line,
    required this.resolvedProduct,
    required this.quantity,
    required this.include,
    required this.manual,
  });

  final DaftariRecoveryLine line;
  final ProductItem? resolvedProduct;
  final int quantity;
  final bool include;
  final bool manual;

  String get rawText => line.rawText;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1D2939),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
