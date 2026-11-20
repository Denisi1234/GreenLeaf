import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/reconciliation_models.dart';

class ImportStatementPage extends StatefulWidget {
  const ImportStatementPage({super.key});

  @override
  State<ImportStatementPage> createState() => _ImportStatementPageState();
}

class _ImportStatementPageState extends State<ImportStatementPage> {
  final _controller = TextEditingController();
  bool _saving = false;

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';
  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
        maxWidth: 860,
        child: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: _t('Import statement', 'Ingiza taarifa'),
                subtitle: _t('Paste lines from bank or mobile money',
                    'Bandika mistari kutoka benki au mtandao wa simu'),
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    ReconciliationCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('Format', 'Muundo'),
                            style: AppTypography.sectionHeader
                                .copyWith(color: AppColors.ink),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _t(
                              'One line per transaction: date, description, amount.\nUse comma, tab, or semicolon. Positive = money in, negative = money out.',
                              'Mstari mmoja kwa muamala: tarehe, maelezo, kiasi.\nTumia koma, tab, au nukta mkato. Chanya = imeingia, hasi = imetoka.',
                            ),
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted, height: 1.45),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              context.tr('2026-01-31, M-Pesa deposit, 150000\n2026-02-01, Supplier payment, -45000'),
                              style: AppTypography.helperText.copyWith(
                                color: AppColors.textBody,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReconciliationCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('Statement lines', 'Mistari ya taarifa'),
                              style: AppTypography.label
                                  .copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _controller,
                            maxLines: 10,
                            minLines: 6,
                            decoration:  InputDecoration(
                              hintText: context.tr('2026-01-31, M-Pesa deposit, 150000'),
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide:
                                    BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 1.4),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              isDense: true,
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MarketButton(
                      label: _saving
                          ? _t('Importing...', 'Inaingiza...')
                          : _t('Import lines', 'Ingiza mistari'),
                      icon: Icons.download_done_rounded,
                      onTap: _saving ? null : _import,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _import() async {
    final rows = _controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    if (rows.isEmpty) {
      showMarketNotice(
        context,
        title: _t('Nothing to import', 'Hakuna cha kuingiza'),
        message: _t('Paste at least one statement line.',
            'Bandika angalau mstari mmoja wa taarifa.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final store = context.read<PosLocalStore>();
      var imported = 0;
      for (final row in rows) {
        final parts = row
            .split(RegExp(r'[,\t;]'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.length < 3) continue;
        final amount = double.tryParse(
            parts.last.replaceAll(',', '').replaceAll('TSh', '').trim());
        if (amount == null || amount == 0) continue;
        final date = DateTime.tryParse(parts.first) ?? DateTime.now();
        final description = parts.length > 2
            ? parts.sublist(1, parts.length - 1).join(' ').trim()
            : parts[1];
        await store.addBankTransaction(
          BankTransaction(
            date: date,
            description: description,
            amount: amount,
            accountName: _isSwahili ? 'Benki' : 'Bank',
          ),
        );
        imported++;
      }
      if (!mounted) return;
      if (imported == 0) {
        showMarketNotice(
          context,
          title: _t('Import', 'Uingizaji'),
          message: _t(
            'No valid lines found. Check the format: date, description, amount.',
            'Hakuna mistari sahihi. Angalia muundo: tarehe, maelezo, kiasi.',
          ),
          type: MarketNoticeType.warning,
        );
        return;
      }
      showMarketNotice(
        context,
        title: _t('Import complete', 'Uingizaji umekamilika'),
        message: _t('$imported line${imported == 1 ? '' : 's'} imported',
            'Mistari $imported imeingizwa'),
        type: MarketNoticeType.success,
      );
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
