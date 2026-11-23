import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../service/audit_log_model.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_theme_palette.dart';
import '../../widgets/market_shared_widgets.dart';

Future<void> showAuditEventDetailSheet(
  BuildContext context, {
  required AuditLogEntry entry,
  required bool isSwahili,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppThemePalette.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.extraRounded)),
    ),
    builder: (ctx) => _AuditEventDetailSheet(
      entry: entry,
      isSwahili: isSwahili,
    ),
  );
}

class _AuditEventDetailSheet extends StatelessWidget {
  const _AuditEventDetailSheet({
    required this.entry,
    required this.isSwahili,
  });

  final AuditLogEntry entry;
  final bool isSwahili;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final severityColor = switch (entry.severity) {
      AuditSeverity.critical => AppColors.dangerDeep,
      AuditSeverity.warning => AppColors.warningDeep,
      AuditSeverity.info => palette.primaryDeep,
    };
    final severityBg = switch (entry.severity) {
      AuditSeverity.critical => AppColors.dangerLight,
      AuditSeverity.warning => AppColors.warningLight,
      AuditSeverity.info => palette.primaryLight,
    };
    final hashValid = entry.isSelfHashValid;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: severityBg,
                      borderRadius: BorderRadius.circular(AppRadius.sharp),
                    ),
                    child: Text(
                      entry.severity.label(isSwahili).toUpperCase(),
                      style: AppTypography.label.copyWith(
                        fontSize: 10.5,
                        color: severityColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: palette.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.sharp),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entry.module.icon,
                            size: 13, color: palette.textBody),
                        const SizedBox(width: 5),
                        Text(
                          entry.module.label(isSwahili),
                          style: AppTypography.label.copyWith(
                            fontSize: 11,
                            color: palette.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${entry.sequence}',
                    style: AppTypography.label.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                entry.actionTitle(isSwahili),
                style: AppTypography.h3.copyWith(color: palette.ink),
              ),
              const SizedBox(height: 6),
              Text(
                entry.summary,
                style: AppTypography.bodyMain.copyWith(
                  color: palette.textBody,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _DetailCard(
                palette: palette,
                title: _t('Event context', 'Taarifa za tukio'),
                child: Column(
                  children: [
                    _DetailRow(
                      palette: palette,
                      label: _t('Timestamp', 'Muda'),
                      value: DateFormat('MMM d, yyyy · HH:mm:ss')
                          .format(entry.timestamp),
                    ),
                    _DetailRow(
                      palette: palette,
                      label: _t('Performed by', 'Aliyefanya'),
                      value: '${entry.actorName} (${entry.actorRole})',
                    ),
                    if (entry.entityLabel.isNotEmpty)
                      _DetailRow(
                        palette: palette,
                        label: _t('Target', 'Lengo'),
                        value: entry.entityLabel,
                      ),
                    _DetailRow(
                      palette: palette,
                      label: _t('Record type', 'Aina ya rekodi'),
                      value: entry.entityType,
                    ),
                    if (entry.entityId.isNotEmpty)
                      _DetailRow(
                        palette: palette,
                        label: _t('Reference ID', 'Kitambulisho'),
                        value: entry.entityId,
                      ),
                    _DetailRow(
                      palette: palette,
                      label: _t('Store ID', 'Duka'),
                      value: entry.storeId,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              if (entry.hasDiff) ...[
                const SizedBox(height: 14),
                _DetailCard(
                  palette: palette,
                  title: _t('Before & after changes', 'Mabadiliko (Kabla → Baada)'),
                  child: Column(
                    children: [
                      for (var i = 0; i < entry.changedKeys.length; i++) ...[
                        if (i > 0)
                          Divider(height: 16, color: palette.divider),
                        _DiffRow(
                          palette: palette,
                          field: entry.changedKeys[i],
                          before: entry.beforeValues[entry.changedKeys[i]],
                          after: entry.afterValues[entry.changedKeys[i]],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (entry.metadata.isNotEmpty) ...[
                const SizedBox(height: 14),
                _DetailCard(
                  palette: palette,
                  title: _t('Additional notes', 'Maelezo ya ziada'),
                  child: Column(
                    children: [
                      for (var i = 0; i < entry.metadata.entries.length; i++)
                        _DetailRow(
                          palette: palette,
                          label: entry.metadata.entries.elementAt(i).key,
                          value: entry.metadata.entries.elementAt(i).value,
                          isLast: i == entry.metadata.entries.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _DetailCard(
                palette: palette,
                title: _t('Tamper-proof signature', 'Uthibitisho wa usalama'),
                trailing: TextButton.icon(
                  onPressed: () {
                    final proof = [
                      'Aza POS Audit Proof',
                      'ID: ${entry.id}',
                      'Seq: #${entry.sequence}',
                      'Timestamp: ${entry.timestamp.toIso8601String()}',
                      'Actor: ${entry.actorName} (${entry.actorRole})',
                      'Action: ${entry.action}',
                      'Prev SHA-256: ${entry.prevHash}',
                      'Entry SHA-256: ${entry.entryHash}',
                    ].join('\n');
                    Clipboard.setData(ClipboardData(text: proof));
                    showMarketNotice(
                      context,
                      title: _t('Proof copied', 'Nakala imechukuliwa'),
                      message: _t(
                        'Audit cryptographic proof copied to clipboard.',
                        'Uthibitisho wa usalama umenakiliwa.',
                      ),
                      type: MarketNoticeType.success,
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: Text(_t('Copy proof', 'Nakili')),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hashValid
                              ? Icons.verified_user_rounded
                              : Icons.gpp_bad_rounded,
                          size: 18,
                          color: hashValid
                              ? AppColors.successDeep
                              : AppColors.dangerDeep,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hashValid
                                ? _t('SHA-256 record integrity verified',
                                    'Alama ya SHA-256 imethibitishwa salama')
                                : _t('Integrity check failed on this record',
                                    'Alama ya usalama imebadilika kwenye rekodi hii'),
                            style: AppTypography.bodySmall.copyWith(
                              color: hashValid
                                  ? AppColors.successDeep
                                  : AppColors.dangerDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      palette: palette,
                      label: _t('Previous hash', 'Mnyororo uliotangulia'),
                      value: entry.prevHash,
                      monospace: true,
                    ),
                    _DetailRow(
                      palette: palette,
                      label: _t('Entry SHA-256', 'Alama ya SHA-256'),
                      value: entry.entryHash,
                      monospace: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.palette,
    required this.title,
    required this.child,
    this.trailing,
  });

  final AppThemePalette palette;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.pageBackground,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w800,
                    color: palette.textMuted,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.palette,
    required this.label,
    required this.value,
    this.monospace = false,
    this.isLast = false,
  });

  final AppThemePalette palette;
  final String label;
  final String value;
  final bool monospace;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
                fontFamily: monospace ? 'monospace' : null,
                fontSize: monospace ? 11.5 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.palette,
    required this.field,
    this.before,
    this.after,
  });

  final AppThemePalette palette;
  final String field;
  final String? before;
  final String? after;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field,
          style: AppTypography.bodySmall.copyWith(
            color: palette.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (before != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  before!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.dangerDeep,
                    decoration: after != null
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (before != null && after != null)
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: palette.textMuted,
              ),
            if (after != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  after!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.successDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
