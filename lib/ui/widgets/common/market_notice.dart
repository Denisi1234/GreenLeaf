import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../app_design.dart';

enum MarketNoticeType {
  info,
  success,
  warning,
  error,
}

OverlayEntry? _activeMarketNoticeEntry;
int _marketNoticeTicket = 0;

/// Shorthand helpers for showing normal, professional bottom toasts
/// consistently across the entire app.
abstract final class AppToast {
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    showMarketNotice(
      context,
      title: title ?? '',
      message: message,
      type: MarketNoticeType.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3400),
  }) {
    showMarketNotice(
      context,
      title: title ?? '',
      message: message,
      type: MarketNoticeType.error,
      duration: duration,
    );
  }

  static void failed(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3400),
  }) =>
      error(context, message, title: title, duration: duration);

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    showMarketNotice(
      context,
      title: title ?? '',
      message: message,
      type: MarketNoticeType.warning,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    showMarketNotice(
      context,
      title: title ?? '',
      message: message,
      type: MarketNoticeType.info,
      duration: duration,
    );
  }
}

void showMarketNotice(
  BuildContext context, {
  required String title,
  required String message,
  MarketNoticeType type = MarketNoticeType.success,
  Duration? duration,
}) {
  final overlay =
      Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
  if (overlay == null) return;

  try {
    _activeMarketNoticeEntry?.remove();
  } catch (_) {}
  _activeMarketNoticeEntry = null;

  final ticket = ++_marketNoticeTicket;
  final effectiveDuration = duration ??
      (type == MarketNoticeType.error
          ? const Duration(milliseconds: 3400)
          : const Duration(milliseconds: 2600));

  final backgroundColor = switch (type) {
    MarketNoticeType.success => AppColors.successDeep,
    MarketNoticeType.warning => AppColors.kpiAmber,
    MarketNoticeType.info => AppColors.primary,
    MarketNoticeType.error => AppColors.dangerDeep,
  };

  final icon = switch (type) {
    MarketNoticeType.success => Icons.check_circle_rounded,
    MarketNoticeType.warning => Icons.warning_amber_rounded,
    MarketNoticeType.info => Icons.info_rounded,
    MarketNoticeType.error => Icons.error_rounded,
  };

  late final OverlayEntry entry;

  void removeEntry() {
    if (_marketNoticeTicket == ticket && _activeMarketNoticeEntry == entry) {
      try {
        entry.remove();
      } catch (_) {}
      _activeMarketNoticeEntry = null;
    }
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      final bottomPadding = MediaQuery.of(ctx).padding.bottom;
      final localizedTitle =
          title.trim().isEmpty ? '' : ctx.strings.message(title.trim());
      final localizedMessage =
          message.trim().isEmpty ? '' : ctx.strings.message(message.trim());

      return Positioned(
        left: 16,
        right: 16,
        bottom: (bottomInset > 0 ? bottomInset + 14 : bottomPadding + 74),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _AnimatedMarketToast(
                title: localizedTitle,
                message: localizedMessage,
                backgroundColor: backgroundColor,
                icon: icon,
                duration: effectiveDuration,
                onDismissed: removeEntry,
              ),
            ),
          ),
        ),
      );
    },
  );

  _activeMarketNoticeEntry = entry;
  overlay.insert(entry);
}

class _AnimatedMarketToast extends StatefulWidget {
  const _AnimatedMarketToast({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  final String title;
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_AnimatedMarketToast> createState() => _AnimatedMarketToastState();
}

class _AnimatedMarketToastState extends State<_AnimatedMarketToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _controller.forward();
    Future<void>.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    try {
      await _controller.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTitle = widget.title.isNotEmpty;
    final hasMessage =
        widget.message.isNotEmpty && widget.message != widget.title;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Semantics(
          liveRegion: true,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 80) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.modal),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasTitle)
                            Text(
                              widget.title,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          if (hasMessage) ...[
                            if (hasTitle) const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: AppTypography.helperText.copyWith(
                                color: hasTitle
                                    ? Colors.white.withValues(alpha: 0.82)
                                    : Colors.white,
                                fontSize: hasTitle ? 12 : 13,
                                fontWeight: hasTitle
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: context.tr('Close'),
                      onPressed: _dismiss,
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
