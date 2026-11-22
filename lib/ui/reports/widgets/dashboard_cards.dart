import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aza_pos/l10n/app_localization.dart';
import '../../../utils/quantity_formatter.dart';
import '../../widgets/app_design.dart';
class TodaySaleOverviewCard extends StatelessWidget {
  const TodaySaleOverviewCard({super.key, 
    required this.formattedSale,
    required this.growthText,
    required this.hasGrowth,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.m1Label,
    required this.m2Label,
    required this.m3Label,
  });

  final String formattedSale;
  final String growthText;
  final bool hasGrowth;
  final double s1;
  final double s2;
  final double s3;
  final String m1Label;
  final String m2Label;
  final String m3Label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Your Sale Overview (Today)'),
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Text(
                  context.tr('Today\'s Total Sale'),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formattedSale,
                    maxLines: 1,
                    style: GoogleFonts.manrope(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: hasGrowth ? AppColors.kpiSuccessBg : AppColors.kpiDangerBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasGrowth ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: hasGrowth ? AppColors.success : AppColors.danger,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        growthText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasGrowth ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Line Chart
          SizedBox(
            height: 98,
            width: double.infinity,
            child: CustomPaint(
              painter: SaleOverviewChartPainter(
                values: [s1, s2, s3],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Month X-Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m1Label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                m2Label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                m3Label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SaleOverviewChartPainter extends CustomPainter {
  SaleOverviewChartPainter({required this.values});

  final List<double> values;

  String _compact(double value) {
    if (value <= 0) return '0';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    return value.toStringAsFixed(0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.reduce(math.max);
    final hasData = maxVal > 0;
    final ceiling = hasData ? maxVal * 1.25 : 1.0;
    final baselineY = size.height - 8;
    final usableHeight = size.height - 32;

    // Dashed base line
    final dashPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, baselineY),
        Offset(startX + 4, baselineY),
        dashPaint,
      );
      startX += 8;
    }

    double yFor(double v) =>
        hasData ? baselineY - (v / ceiling) * usableHeight : baselineY;

    final p0 = Offset(14, yFor(values[0]));
    final p1 = Offset(size.width * 0.5, yFor(values[1]));
    final p2 = Offset(size.width - 14, yFor(values[2]));

    // Subtle area fill under real data
    if (hasData) {
      final fillPath = Path()
        ..moveTo(p0.dx, baselineY)
        ..lineTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p2.dx, baselineY)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.kpiSky.withValues(alpha: 0.16),
            AppColors.kpiSky.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, baselineY));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Blue Line
    final linePaint = Paint()
      ..color = hasData ? AppColors.kpiSky : AppColors.borderInput
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(path, linePaint);

    // Dots & live value labels
    final dotPaint = Paint()
      ..color = hasData ? AppColors.kpiSky : AppColors.textLight;
    final innerWhite = Paint()..color = AppColors.surface;
    final pts = [p0, p1, p2];

    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 2, innerWhite);

      final tp = TextPainter(
        text: TextSpan(
          text: _compact(values[i]),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = (p.dx - tp.width / 2).clamp(0.0, size.width - tp.width);
      final labelY = (p.dy - tp.height - 6).clamp(0.0, baselineY - tp.height);
      tp.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant SaleOverviewChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

// ---------------------------------------------------------------------------
// Card 2: Expenses (Today)
// ---------------------------------------------------------------------------
class ExpensesSummaryCard extends StatelessWidget {
  const ExpensesSummaryCard({super.key, 
    required this.formattedAmount,
    this.onAddExpense,
  });

  final String formattedAmount;
  final VoidCallback? onAddExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Expenses (Today)'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (onAddExpense != null)
                TextButton(
                  onPressed: onAddExpense,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: Text(
                    context.tr('Add expense'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kpiSky,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formattedAmount,
              maxLines: 1,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.kpiDanger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 3: Most Used Reports
// ---------------------------------------------------------------------------
class MostUsedReportsCard extends StatelessWidget {
  const MostUsedReportsCard({super.key, 
    required this.onSalesTap,
    required this.onPurchasesTap,
    required this.onBalSheetTap,
    required this.onProfitLossTap,
    required this.onSeeAllTap,
  });

  final VoidCallback onSalesTap;
  final VoidCallback onPurchasesTap;
  final VoidCallback onBalSheetTap;
  final VoidCallback onProfitLossTap;
  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr('Most Used Reports'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeAllTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(
                  context.tr('See All'),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kpiSky,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ReportIconItem(
                  label: context.tr('Sales'),
                  icon: Icons.receipt_long_rounded,
                  badgeSymbol: '%',
                  badgeColor: AppColors.primaryDeep,
                  bgColor: AppColors.surfaceSecondary,
                  iconColor: AppColors.ink,
                  onTap: onSalesTap,
                ),
              ),
              Expanded(
                child: ReportIconItem(
                  label: context.tr('Purchases'),
                  icon: Icons.assignment_outlined,
                  badgeSymbol: null,
                  bgColor: AppColors.surfaceSecondary,
                  iconColor: AppColors.ink,
                  onTap: onPurchasesTap,
                ),
              ),
              Expanded(
                child: ReportIconItem(
                  label: context.tr('Bal. Sheet'),
                  icon: Icons.balance_rounded,
                  badgeSymbol: null,
                  bgColor: AppColors.surfaceSecondary,
                  iconColor: AppColors.ink,
                  onTap: onBalSheetTap,
                ),
              ),
              Expanded(
                child: ReportIconItem(
                  label: context.tr('Profit & Loss'),
                  icon: Icons.trending_up_rounded,
                  badgeSymbol: null,
                  bgColor: AppColors.surfaceSecondary,
                  iconColor: AppColors.ink,
                  onTap: onProfitLossTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportIconItem extends StatelessWidget {
  const ReportIconItem({super.key, 
    required this.label,
    required this.icon,
    this.badgeSymbol,
    this.hasCrown = false,
    this.badgeColor,
    this.bgColor,
    this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? badgeSymbol;
  final bool hasCrown;
  final Color? badgeColor;
  final Color? bgColor;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 38,
                  decoration: BoxDecoration(
                    color: bgColor ?? AppColors.kpiRoseBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor ?? AppColors.ink,
                  ),
                ),
                if (hasCrown)
                  Positioned(
                    top: -6,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.kpiViolet,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.star_rounded, size: 9, color: Colors.white),
                    ),
                  ),
                if (badgeSymbol != null)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        badgeSymbol!,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 4: Store Alerts (Always shows all real-time alerts)
// ---------------------------------------------------------------------------
class StoreAlertsCard extends StatelessWidget {
  const StoreAlertsCard({
    super.key,
    required this.outOfStockCount,
    required this.lowStockCount,
    required this.pendingCreditCount,
    required this.outOfStockItems,
    required this.lowStockItems,
    this.onStockAlertTap,
    this.onDebtAlertTap,
  });

  final int outOfStockCount;
  final int lowStockCount;
  final int pendingCreditCount;
  final List<dynamic> outOfStockItems;
  final List<dynamic> lowStockItems;
  final VoidCallback? onStockAlertTap;
  final VoidCallback? onDebtAlertTap;

  @override
  Widget build(BuildContext context) {
    final totalAlerts = outOfStockCount + lowStockCount + pendingCreditCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('Store Alerts'),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: totalAlerts > 0 ? AppColors.kpiDangerBg : AppColors.kpiSuccessBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  totalAlerts > 0 ? context.tr('{p0} Active', args: {'p0': totalAlerts}) : context.tr('All Clear'),
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: totalAlerts > 0 ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Alert 1: Out of Stock
          if (outOfStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AlertRow(
                icon: Icons.cancel_rounded,
                color: AppColors.danger,
                bgColor: AppColors.kpiDangerBg,
                title: context.tr('{p0} items are completely Out of Stock',
                    args: {'p0': outOfStockCount}),
                subtitle: outOfStockItems.take(2).map((p) => p.name).join(', '),
                onTap: onStockAlertTap,
              ),
            ),

          // Alert 2: Low Stock Warning
          if (lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AlertRow(
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                bgColor: AppColors.kpiAmberBg,
                title: context.tr('{p0} items are Low on Stock',
                    args: {'p0': lowStockCount}),
                subtitle: lowStockItems
                    .take(2)
                    .map((p) =>
                        '${p.name} (${formatStockWithUnit(p.stockCount, p.unit)} left)')
                    .join(', '),
                onTap: onStockAlertTap,
              ),
            ),

          // Alert 3: Pending Customer Credit
          if (pendingCreditCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AlertRow(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.kpiSky,
                bgColor: AppColors.kpiSkyBg,
                title: context.tr('{p0} customers have outstanding debt',
                    args: {'p0': pendingCreditCount}),
                subtitle: context.tr(
                    'Tap to review debtor ledger and collect payments'),
                onTap: onDebtAlertTap,
              ),
            ),

          // When all clear
          if (totalAlerts == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: AlertRow(
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                bgColor: AppColors.kpiSuccessBg,
                title: context.tr('All store inventory levels and ledgers healthy'),
                subtitle: context.tr('No low stock warnings or urgent pending actions.'),
              ),
            ),
        ],
      ),
    );
  }
}

class AlertRow extends StatelessWidget {
  const AlertRow({
    super.key,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sharp),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}
