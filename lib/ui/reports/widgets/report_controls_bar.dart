import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../models/report_models.dart';

class ReportControlsBar extends StatelessWidget {
  const ReportControlsBar({
    super.key,
    required this.dateRange,
    required this.periodLabel,
    required this.isDownloading,
    required this.onPeriodSelected,
    required this.onDownloadTap,
  });

  final String dateRange;
  final String periodLabel;
  final bool isDownloading;
  final ValueChanged<ReportPeriod> onPeriodSelected;
  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            dateRange,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _PeriodSelector(
          currentPeriod: periodLabel,
          onPeriodSelected: onPeriodSelected,
        ),
        const SizedBox(width: AppSpacing.sm),
        _DownloadButton(
          isDownloading: isDownloading,
          onTap: onDownloadTap,
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.currentPeriod,
    required this.onPeriodSelected,
  });

  final String currentPeriod;
  final ValueChanged<ReportPeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ReportPeriod>(
      tooltip: 'Select period',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentPeriod,
              style: AppTypography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => ReportPeriod.values
          .map(
            (period) => PopupMenuItem<ReportPeriod>(
              value: period,
              child: Text(period.label, style: AppTypography.bodySmall),
            ),
          )
          .toList(),
      onSelected: onPeriodSelected,
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.isDownloading,
    required this.onTap,
  });

  final bool isDownloading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isDownloading ? null : onTap,
      icon: isDownloading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : const Icon(Icons.download_rounded, size: 18),
      label: Text(
        isDownloading ? 'Preparing...' : 'PDF',
        style: AppTypography.label.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
      ),
    );
  }
}
