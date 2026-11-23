import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../../service/report_pdf/report_pdf_layout.dart';
import '../reports/pos_report_data.dart';
import '../widgets/market_shared_widgets.dart';

class AuditExportService {
  const AuditExportService._();

  static String buildCsv({
    required List<AuditLogEntry> entries,
    required bool isSwahili,
  }) {
    final buffer = StringBuffer();
    final headers = isSwahili
        ? const [
            'Mfuatano',
            'Tarehe na Muda',
            'Mtumiaji',
            'Cheo',
            'Sehemu',
            'Kiwango',
            'Kitendo',
            'Aina ya Kitu',
            'Namba ya Kitu',
            'Lengo',
            'Muhtasari',
            'Mabadiliko',
            'Alama ya Usalama (SHA-256)',
          ]
        : const [
            'Sequence',
            'Timestamp',
            'User',
            'Role',
            'Module',
            'Severity',
            'Action',
            'Entity Type',
            'Entity ID',
            'Target',
            'Summary',
            'Changes',
            'SHA-256 Hash',
          ];
    buffer.writeln(headers.map(_csvCell).join(','));

    for (final e in entries) {
      final diffSummary = e.changedKeys.map((key) {
        final before = e.beforeValues[key] ?? '-';
        final after = e.afterValues[key] ?? '-';
        return '$key: $before -> $after';
      }).join(' | ');

      final row = <String>[
        '${e.sequence}',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(e.timestamp),
        e.actorName,
        e.actorRole,
        e.module.label(isSwahili),
        e.severity.label(isSwahili),
        e.actionTitle(isSwahili),
        e.entityType,
        e.entityId,
        e.entityLabel,
        e.summary,
        diffSummary,
        e.entryHash,
      ];
      buffer.writeln(row.map(_csvCell).join(','));
    }

    return buffer.toString();
  }

  static Future<void> exportCsv({
    required BuildContext context,
    required List<AuditLogEntry> entries,
    required AppStrings strings,
  }) async {
    final csv = buildCsv(entries: entries, isSwahili: strings.isSwahili);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final fileName = 'audit_trail_${_stamp()}.csv';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
      );
    } catch (error) {
      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: strings.isSwahili ? 'Imeshindwa kuhamisha' : 'Export failed',
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
    }
  }

  static Future<Uint8List> buildPdf({
    required List<AuditLogEntry> entries,
    required AuditIntegrityReport integrity,
    required AppStrings strings,
    String? filterSummary,
    ReportPdfContext? pdfContext,
  }) {
    final ctx = pdfContext ?? ReportPdfContext(languageCode: strings.languageCode);
    final sw = strings.isSwahili;
    final criticalCount =
        entries.where((e) => e.severity == AuditSeverity.critical).length;
    final warningCount =
        entries.where((e) => e.severity == AuditSeverity.warning).length;
    final shortHead = integrity.headHash.length > 16
        ? '${integrity.headHash.substring(0, 16)}...'
        : integrity.headHash;

    return ReportPdfLayout.tableDocument(
      title: sw ? 'Ripoti ya Ukaguzi wa Mfumo' : 'System Audit Trail Report',
      subtitle: filterSummary ??
          (sw
              ? 'Kumbukumbu zilizolindwa dhidi ya mabadiliko'
              : 'Tamper-evident chronological activity log'),
      context: ctx,
      details: [
        MapEntry(
          sw ? 'Hali ya Usalama' : 'Chain Integrity',
          integrity.isValid
              ? (sw
                  ? 'SALAMA (${integrity.totalChecked} rekodi)'
                  : 'VERIFIED INTACT (${integrity.totalChecked} records)')
              : (sw
                  ? 'IMEINGILIWA (${integrity.brokenEntryIds.length})'
                  : 'TAMPERING DETECTED (${integrity.brokenEntryIds.length})'),
        ),
        MapEntry(
          sw ? 'Alama ya Mwisho' : 'Head SHA-256',
          shortHead,
        ),
      ],
      table: ReportTable(
        [
          ReportColumn(sw ? 'Na.' : 'Seq'),
          ReportColumn(sw ? 'Tarehe na Muda' : 'Date & Time'),
          ReportColumn(sw ? 'Mtumiaji' : 'User'),
          ReportColumn(sw ? 'Sehemu' : 'Module'),
          ReportColumn(sw ? 'Kiwango' : 'Severity'),
          ReportColumn(sw ? 'Kitendo na Lengo' : 'Action & Target'),
          ReportColumn(sw ? 'Maelezo' : 'Details'),
        ],
        [
          for (final e in entries)
            [
              '#${e.sequence}',
              DateFormat('yyyy-MM-dd HH:mm').format(e.timestamp),
              '${e.actorName} (${e.actorRole})',
              e.module.label(sw),
              e.severity.label(sw),
              e.entityLabel.isEmpty
                  ? e.actionTitle(sw)
                  : '${e.actionTitle(sw)} - ${e.entityLabel}',
              e.summary,
            ],
        ],
      ),
      summary: [
        MapEntry(sw ? 'Matukio Yote' : 'Total Events', '${entries.length}'),
        MapEntry(sw ? 'Matukio Muhimu' : 'Critical Alerts', '$criticalCount'),
        MapEntry(sw ? 'Tahadhari' : 'Warnings', '$warningCount'),
        MapEntry(
          sw ? 'Uthibitisho wa Mnyororo' : 'Integrity Status',
          integrity.isValid
              ? (sw ? 'Imethibitishwa Salama' : 'Verified Intact')
              : (sw
                  ? '${integrity.brokenEntryIds.length} zenye kasoro'
                  : '${integrity.brokenEntryIds.length} broken link(s)'),
        ),
      ],
    );
  }

  static Future<void> exportPdf({
    required BuildContext context,
    required List<AuditLogEntry> entries,
    required AuditIntegrityReport integrity,
    required AppStrings strings,
    String? filterSummary,
    ReportPdfContext? pdfContext,
  }) async {
    try {
      final reportContext = pdfContext ??
          ReportPdfContext.fromStore(
            context.read<PosLocalStore>(),
            languageCode: strings.languageCode,
          );
      final bytes = await buildPdf(
        entries: entries,
        integrity: integrity,
        strings: strings,
        filterSummary: filterSummary,
        pdfContext: reportContext,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'audit_trail_${_stamp()}.pdf',
      );
    } catch (error) {
      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: strings.isSwahili ? 'Imeshindwa kuhamisha' : 'Export failed',
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
    }
  }

  static String _stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  static String _csvCell(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
