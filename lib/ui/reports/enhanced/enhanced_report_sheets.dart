part of '../enhanced_report_page.dart';

extension _EnhancedReportSheets on _EnhancedReportPageState {
  ReportPdfContext _pdfContext() => ReportPdfContext.fromStore(
        context.read<PosLocalStore>(),
        languageCode: context.strings.languageCode,
        filterSummary: [
          if (_searchQuery.trim().isNotEmpty)
            '${context.tr('Search')}: ${_searchQuery.trim()}',
          if (_selection != null) '${context.tr('Selection')}: $_selection',
        ].join(' | '),
      );

  Widget _buildExportButton(ReportTable table) => InkWell(
        onTap: _exporting
            ? null
            : () {
                if (table.rows.isEmpty) {
                  showMarketNotice(
                    context,
                    title: context.tr('Nothing to export'),
                    message: context.tr(
                      'No records found for this report period.',
                    ),
                    type: MarketNoticeType.info,
                  );
                  return;
                }
                _showExportSheet(table);
              },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: AppCorners.control,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_exporting) ...[
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.ink)),
                const SizedBox(width: 8),
              ] else ...[
                Icon(Icons.ios_share_outlined,
                    size: 16, color: AppColors.ink),
                const SizedBox(width: 8),
              ],
              Text(
                context.tr('Export'),
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      table.rows.isEmpty ? AppColors.textLight : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _showExportSheet(ReportTable table) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('Export report'),
                    style: AppTypography.sectionHeader
                        .copyWith(fontSize: 18, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                  '${context.tr(widget.report.title)} • ${table.rows.length} ${context.tr(table.rows.length == 1 ? 'record' : 'records')}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                _sheetSectionLabel('Download to device'),
                _sheetAction(
                  icon: Icons.table_view_rounded,
                  title: context.tr('CSV spreadsheet'),
                  subtitle: context.tr('Comma separated values'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _triggerExport(table, ExportFormat.csv, save: true);
                  },
                ),
                _sheetAction(
                  icon: Icons.grid_on_rounded,
                  title: context.tr('Excel workbook'),
                  subtitle: context.tr('Microsoft Excel (.xls)'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _triggerExport(table, ExportFormat.excel, save: true);
                  },
                ),
                _sheetAction(
                  icon: Icons.picture_as_pdf_outlined,
                  title: context.tr('PDF document'),
                  subtitle: context.tr('Printable, formatted report'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _triggerExport(table, ExportFormat.pdf, save: true);
                  },
                ),
                const SizedBox(height: 16),
                _sheetSectionLabel(context.tr('Share')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final format in [
                      ExportFormat.csv,
                      ExportFormat.excel,
                      ExportFormat.pdf
                    ])
                      ActionChip(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _triggerExport(table, format, save: false);
                        },
                        avatar: Icon(_formatIcon(format), size: 16),
                        label: Text(format.label),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppCorners.control),
                        labelStyle: AppTypography.helperText.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        backgroundColor: AppColors.surfaceSecondary,
                        side: BorderSide.none,
                      ),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    context.tr('Other formats'),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final format in [
                              ExportFormat.json,
                              ExportFormat.xml,
                              ExportFormat.txt,
                              ExportFormat.sql,
                            ])
                              ActionChip(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  _triggerExport(table, format, save: false);
                                },
                                avatar: Icon(_formatIcon(format), size: 16),
                                label: Text(format.label),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: AppCorners.control),
                                labelStyle: AppTypography.helperText.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                                backgroundColor: AppColors.surfaceSecondary,
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sheetSectionLabel(context.tr('More')),
                _sheetAction(
                  icon: Icons.copy_all_rounded,
                  title: context.tr('Copy table'),
                  subtitle: context.tr('Copy all matching rows as CSV'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ReportExportService.copyCsv(context, table);
                  },
                ),
                _sheetAction(
                  icon: Icons.print_outlined,
                  title: context.tr('Print'),
                  subtitle: context.tr('Open the system print dialog'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _printReport(table);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _printReport(ReportTable table) async {
    if (_exporting) return;
    final reportContext = _pdfContext();
    final title = context.tr(widget.report.title);
    _updateState(() => _exporting = true);
    try {
      final bytes = await ReportExportService.generatePdf(
          table, title, _range, widget.report.isSnapshot,
          pdfContext: reportContext);
      if (!mounted) return;
      await Printing.layoutPdf(
          name: ReportExportService.exportFileName(title, 'pdf'),
          format: ReportPdfLayout.pageFormatFor(table.columns.length),
          dynamicLayout: false,
          onLayout: (_) async => bytes);
    } catch (error) {
      if (mounted) {
        showMarketNotice(context,
            title: context.tr('Print failed'),
            message: error.toString(),
            type: MarketNoticeType.error);
      }
    } finally {
      if (mounted) _updateState(() => _exporting = false);
    }
  }

  Future<void> _triggerExport(ReportTable table, ExportFormat format,
      {required bool save}) async {
    if (_exporting) return;
    _updateState(() => _exporting = true);
    try {
      if (save) {
        await ReportExportService.saveReport(
          context: context,
          table: table,
          title: context.tr(widget.report.title),
          format: format,
          range: _range,
          isSnapshot: widget.report.isSnapshot,
          pdfContext: format == ExportFormat.pdf ? _pdfContext() : null,
        );
      } else {
        await ReportExportService.exportReport(
          context: context,
          table: table,
          title: context.tr(widget.report.title),
          format: format,
          range: _range,
          isSnapshot: widget.report.isSnapshot,
          pdfContext: format == ExportFormat.pdf ? _pdfContext() : null,
        );
      }
    } finally {
      if (mounted) _updateState(() => _exporting = false);
    }
  }

  IconData _formatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.data_object_rounded;
      case ExportFormat.xml:
        return Icons.code_rounded;
      case ExportFormat.csv:
        return Icons.table_chart_outlined;
      case ExportFormat.txt:
        return Icons.description_outlined;
      case ExportFormat.sql:
        return Icons.storage_rounded;
      case ExportFormat.excel:
        return Icons.grid_on_rounded;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }

  Widget _sheetSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.label.copyWith(
          fontSize: 11,
          letterSpacing: 0.8,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppCorners.control,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: AppCorners.control,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Future<void> _showColumnsSheet(ReportTable table) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('Show columns'),
                              style: AppTypography.sectionHeader
                                  .copyWith(fontSize: 17, color: AppColors.ink),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() => _hiddenColumns.clear());
                              _updateState(() {});
                            },
                            child: Text(context.tr('Reset')),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_hasCostProfitColumns(table))
                      SwitchListTile(
                        title: Text(context.tr('Show cost and profit')),
                        value: !_costProfitHidden(table),
                        onChanged: (show) {
                          setSheetState(() {
                            if (show) {
                              _hiddenColumns
                                  .removeAll(_costProfitLabels(table));
                            } else {
                              _hiddenColumns.addAll(_costProfitLabels(table));
                            }
                          });
                          _updateState(() {});
                        },
                      ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final column in table.columns)
                            CheckboxListTile(
                              value: !_hiddenColumns.contains(column.label),
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked ?? true) {
                                    _hiddenColumns.remove(column.label);
                                  } else if (table.columns.length -
                                          _hiddenColumns.length >
                                      1) {
                                    _hiddenColumns.add(column.label);
                                  }
                                });
                                _updateState(() {});
                              },
                              title: Text(
                                context.tr(column.label),
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.ink),
                              ),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
