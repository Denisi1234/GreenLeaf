import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_strings.dart';
import '../widgets/app_design.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.strings,
    required this.child,
    this.onBack,
    this.showMobileBrand = true,
  });

  final AppStrings strings;
  final Widget child;
  final VoidCallback? onBack;
  final bool showMobileBrand;

  static const double wideBreakpoint = 900;
  static const String logoAsset = 'assets/images/ospos_logo.png';
  static const String markAsset = 'assets/images/ospos_mark.svg';
  static const String markWhiteAsset = 'assets/images/ospos_mark_white.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= wideBreakpoint) {
            final brandWidth =
                (constraints.maxWidth * 0.46).clamp(420.0, 620.0).toDouble();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BrandPanel(strings: strings, width: brandWidth),
                Expanded(
                  child: _FormPanel(
                    backLabel: strings.back,
                    onBack: onBack,
                    child: child,
                  ),
                ),
              ],
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showMobileBrand) const _MobileBrandRow(),
                      if (onBack != null) ...[
                        const SizedBox(height: 14),
                        AuthBackButton(label: strings.back, onPressed: onBack!),
                      ],
                      const SizedBox(height: 30),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.backLabel,
    required this.child,
    this.onBack,
  });

  final String backLabel;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pageBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 44),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onBack != null) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AuthBackButton(label: backLabel, onPressed: onBack!),
                  ),
                  const SizedBox(height: 22),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.strings,
    required this.width,
  });

  final AppStrings strings;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111111), Color(0xFF111111)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned(
            top: -150,
            right: -130,
            child: _Glow(color: Color(0x3DD32222), size: 440),
          ),
          const Positioned(
            bottom: -170,
            left: -120,
            child: _Glow(color: Color(0x2E111111), size: 400),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 660;
              final content = Padding(
                padding: const EdgeInsets.fromLTRB(52, 48, 52, 44),
                child: Column(
                  mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandLockup(light: true),
                    if (compact) const SizedBox(height: 40) else const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Text(
                        strings.authHeroTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text(
                        strings.authHeroSubtitle,
                        style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _BrandFeature(
                      asset: 'assets/images/menubar/sales.svg',
                      text: strings.authFeatureSell,
                    ),
                    const SizedBox(height: 18),
                    _BrandFeature(
                      asset: 'assets/images/menubar/items.svg',
                      text: strings.authFeatureStock,
                    ),
                    const SizedBox(height: 18),
                    _BrandFeature(
                      asset: 'assets/images/menubar/migrate.svg',
                      text: strings.authFeatureSync,
                    ),
                    if (compact) const SizedBox(height: 32) else const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: AppColors.primarySoft,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.authSecureSync,
                            style: const TextStyle(
                              color: AppColors.primarySoft,
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              if (!compact) return content;
              return SingleChildScrollView(child: content);
            },
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.light});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OsposMark(size: 42, light: light),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TrackMauzo',
              style: TextStyle(
                color: light ? Colors.white : AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'POINT OF SALE',
              style: TextStyle(
                color: light ? AppColors.primarySoft : AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class OsposLogo extends StatelessWidget {
  const OsposLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AuthShell.logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

class OsposMark extends StatelessWidget {
  const OsposMark({
    super.key,
    this.size = 40,
    this.light = false,
  });

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      light ? AuthShell.markWhiteAsset : AuthShell.markAsset,
      width: size,
      height: size,
    );
  }
}

class _MobileBrandRow extends StatelessWidget {
  const _MobileBrandRow();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: AlignmentDirectional.centerStart,
      child: _BrandLockup(light: false),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({required this.asset, required this.text});

  final String asset;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: SvgPicture.asset(asset, width: 24, height: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFF0FDF4),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: const Icon(Icons.chevron_left_rounded, size: 20),
      label: Text(label),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class AuthSectionLabel extends StatelessWidget {
  const AuthSectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.dangerDeep,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF191C1F),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF191C1F).withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onAction,
    this.enabled = true,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: enabled ? onAction : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
