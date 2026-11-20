import 'package:flutter/material.dart';

import '../widgets/app_design.dart';

/// Shared building blocks for the Settings area, styled after the OSPOS
/// configuration screens (grouped cards, label/field rows, sticky save bar).

// Legacy palette aliases (kept for screens that still import them).
const settingsInk = AppColors.ink;
const settingsBorder = AppColors.border;
const settingsMuted = AppColors.textMuted;

/// Settings screens now inherit the global OSPOS theme. Kept for callers that
/// still wrap their pages with `Theme(data: settingsTheme(...))`.
ThemeData settingsTheme(ThemeData base) => base;

/// Small bilingual helper for settings copy (English / Kiswahili).
String settingsText(String languageCode, String en, String sw) =>
    languageCode == 'sw' ? sw : en;

/// A titled flat card grouping related settings (OSPOS `fieldset`).
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.trailing,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.showDivider = true,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  SettingsIconBox(icon: icon!),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.sectionHeader),
                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(description!, style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            if (showDivider) const Divider(height: 1),
            if (showDivider) const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// `.menu-icon-box` – tinted rounded square holding an icon.
class SettingsIconBox extends StatelessWidget {
  const SettingsIconBox({
    super.key,
    required this.icon,
    this.color = AppColors.textBody,
    this.background = AppColors.surfaceSecondary,
    this.size = 38,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.zero,
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Label + control row. Stacks vertically on narrow widths
/// (OSPOS `.form-horizontal .control-label` behaviour).
class SettingsField extends StatelessWidget {
  const SettingsField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
            ],
          ),
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!, style: AppTypography.helperText),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heading, const SizedBox(height: 8), child],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 190,
                child: Padding(
                  padding: const EdgeInsets.only(top: 11, right: 16),
                  child: heading,
                ),
              ),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

/// Switch row with title + description.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.border),
          ),
          title: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: AppTypography.caption),
        ),
      ),
    );
  }
}

/// Read-only key/value row (system info).
class SettingsInfoRow extends StatelessWidget {
  const SettingsInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.selectable = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMedium.copyWith(
      fontWeight: FontWeight.w700,
      color: valueColor ?? AppColors.textMain,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: selectable
                ? SelectableText(value, textAlign: TextAlign.end, style: style)
                : Text(value, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

/// Small status pill (connected / offline etc.).
class SettingsStatusPill extends StatelessWidget {
  const SettingsStatusPill({
    super.key,
    required this.label,
    required this.positive,
  });

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final fg = positive ? AppColors.successDeep : AppColors.textSecondary;
    final bg = positive ? AppColors.successLight : AppColors.surfaceHover;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: positive ? AppColors.successBright : AppColors.textLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.label.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Right-aligned primary save button.
class SettingsSaveButton extends StatelessWidget {
  const SettingsSaveButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        icon: const Icon(Icons.check_rounded, size: 18),
        label: Text(label),
      ),
    );
  }
}

/// Sticky footer shown when a form has unsaved changes.
class SettingsSaveBar extends StatelessWidget {
  const SettingsSaveBar({
    super.key,
    required this.visible,
    required this.message,
    required this.saveLabel,
    required this.discardLabel,
    required this.onSave,
    required this.onDiscard,
    this.busy = false,
  });

  final bool visible;
  final String message;
  final String saveLabel;
  final String discardLabel;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: child,
      ),
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Container(
              key: const ValueKey('save-bar'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded,
                        color: AppColors.warning, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: busy ? null : onDiscard,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.dangerDeep),
                      child: Text(discardLabel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: busy ? null : onSave,
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(saveLabel),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

void showSettingsResult(BuildContext context, String message,
    {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.danger : AppColors.ink,
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
