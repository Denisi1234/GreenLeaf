import 'package:flutter/material.dart';
import '../app_design.dart';

/// Professional motion loading indicator with smooth branding pulse and spinner.
/// Can be used as a full view loader, inline section loader, or modal overlay.
class MarketLoadingView extends StatefulWidget {
  const MarketLoadingView({
    super.key,
    this.message,
    this.subMessage,
    this.size = 48,
    this.showBadge = true,
    this.color = AppColors.primary,
  });

  final String? message;
  final String? subMessage;
  final double size;
  final bool showBadge;
  final Color color;

  @override
  State<MarketLoadingView> createState() => _MarketLoadingViewState();
}

class _MarketLoadingViewState extends State<MarketLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: widget.showBadge
                  ? Container(
                      width: widget.size + 24,
                      height: widget.size + 24,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                        border: Border.all(color: AppColors.border, width: 1.2),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: widget.size,
                            height: widget.size,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                              backgroundColor: widget.color.withValues(alpha: 0.15),
                            ),
                          ),
                          Icon(
                            Icons.auto_graph_rounded,
                            size: widget.size * 0.44,
                            color: widget.color,
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                        backgroundColor: widget.color.withValues(alpha: 0.15),
                      ),
                    ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 18),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMain.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  letterSpacing: -0.2,
                ),
              ),
            ],
            if (widget.subMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.subMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer table placeholder skeleton for reports and data grids
class MarketTableSkeleton extends StatelessWidget {
  const MarketTableSkeleton({
    super.key,
    this.rows = 8,
    this.columns = 5,
  });

  final int rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: AppColors.surfaceSecondary,
            child: Row(
              children: List.generate(
                columns,
                (index) => Expanded(
                  child: Container(
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Skeleton body rows
          Expanded(
            child: ListView.separated(
              itemCount: rows,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, rowIndex) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  color: rowIndex.isEven ? AppColors.surface : AppColors.surfaceSecondary.withValues(alpha: 0.3),
                  child: Row(
                    children: List.generate(
                      columns,
                      (colIndex) => Expanded(
                        child: Container(
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
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
