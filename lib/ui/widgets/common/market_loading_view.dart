import 'package:flutter/material.dart';
import '../app_design.dart';

/// Quiet progress feedback shared by full pages, sections and overlays.
class MarketLoadingView extends StatelessWidget {
  const MarketLoadingView({
    super.key,
    this.message,
    this.subMessage,
    this.size = 48,
    this.showBadge = true,
    this.color,
  });

  final String? message;
  final String? subMessage;
  final double size;
  final bool showBadge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final indicator = SizedBox(
      width: size,
      height: size,
      child: reduceMotion
          ? Icon(Icons.hourglass_empty_rounded,
              size: size * 0.75, color: effectiveColor)
          : CircularProgressIndicator(
              strokeWidth: 3,
              color: effectiveColor,
              backgroundColor: AppColors.borderLight,
            ),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBadge)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppCorners.control,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: indicator,
                  )
                else
                  indicator,
                if (message != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMain
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
                if (subMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated shimmer table placeholder skeleton for reports and data grids.
class MarketTableSkeleton extends StatefulWidget {
  const MarketTableSkeleton({
    super.key,
    this.rows = 8,
    this.columns = 5,
  });

  final int rows;
  final int columns;

  @override
  State<MarketTableSkeleton> createState() => _MarketTableSkeletonState();
}

class _MarketTableSkeletonState extends State<MarketTableSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = 0.35 + (_controller.value * 0.45);
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: AppColors.surfaceSecondary,
                child: Row(
                  children: List.generate(
                    widget.columns,
                    (index) => Expanded(
                      child: Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: pulse),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.border),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.rows,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, rowIndex) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      color: rowIndex.isEven
                          ? AppColors.surface
                          : AppColors.surfaceSecondary.withValues(alpha: 0.3),
                      child: Row(
                        children: List.generate(
                          widget.columns,
                          (colIndex) => Expanded(
                            child: Container(
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: AppColors.border
                                    .withValues(alpha: pulse * 0.8),
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
      },
    );
  }
}
