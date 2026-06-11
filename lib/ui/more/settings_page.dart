// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

enum _ThemeChoice { light, dark }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _ThemeChoice _themeChoice = _ThemeChoice.dark;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            _Header(store: store),
            const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.language_rounded,
                title: strings.language,
                subtitle: strings.preferredLanguage,
                child: _DropdownButton(
                  value: store.languageCode == 'en'
                      ? strings.english
                      : strings.swahili,
                  items: [strings.english, strings.swahili],
                  onChanged: (value) {
                    if (value == null) return;
                    unawaited(store.setLanguageCode(
                        value == strings.english ? 'en' : 'sw'));
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.brightness_6_rounded,
                title: strings.appearance,
                subtitle: strings.preferredTheme,
                child: _ThemeChooser(
                  selected: _themeChoice,
                  onChanged: (choice) {
                    setState(() {
                      _themeChoice = choice;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              _ListCard(
                items: [
                  _SettingsItem(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF6E4AE2),
                    backgroundColor: const Color(0xFFF0EBFF),
                    title: strings.security,
                    subtitle: strings.languageCode == 'en'
                        ? 'PIN, passcode and security options'
                        : 'PIN, nambari ya siri na chaguo za usalama',
                    onTap: () => _showSoon(context, strings.security, strings.comingSoon),
                  ),
                  _SettingsItem(
                    icon: Icons.cloud_upload_outlined,
                    iconColor: const Color(0xFF2A6CE3),
                    backgroundColor: const Color(0xFFEAF2FF),
                    title: strings.backupRestore,
                    subtitle: strings.languageCode == 'en'
                        ? 'Backup your data and restore'
                        : 'Hifadhi nakala ya data yako na urejeshe',
                    onTap: () => _showSoon(context, strings.backupRestore, strings.comingSoon),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _VersionCard(
                version: 'v1.0.0',
                storeName: store.profile.storeName,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSoon(BuildContext context, String title, String message) {
    showMarketNotice(
      context,
      title: title,
      message: message,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.store,
  });

  final PosLocalStore store;

  @override
  Widget build(BuildContext context) {
    final profile = store.profile;
    final strings = AppStrings.of(store.languageCode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFF), Color(0xFFF1F5FF)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -22,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE8FF).withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -22,
            top: 8,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE7FF).withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.ink,
                        size: 30,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40, height: 40),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                strings.settings,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.customizePosExperience,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              _StoreStrip(
                storeName: profile.storeName.isEmpty
                    ? strings.currentStore
                    : profile.storeName,
                businessCategory: profile.businessCategory,
                logoPath: profile.logoPath,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreStrip extends StatelessWidget {
  const _StoreStrip({
    required this.storeName,
    required this.businessCategory,
    required this.logoPath,
  });

  final String storeName;
  final String businessCategory;
  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFE7EAF0),
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: logoPath == null
                ? const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFF2A6CE3),
                    size: 30,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(logoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.storefront_outlined,
                        color: Color(0xFF2A6CE3),
                        size: 30,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  businessCategory.isEmpty
                      ? 'Business store'
                      : businessCategory,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      borderColor: const Color(0xFFE7EAF0),
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _tintForIcon(icon),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: _colorForIcon(icon),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DropdownButton extends StatelessWidget {
  const _DropdownButton({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8EF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7B8598),
          ),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ThemeChooser extends StatelessWidget {
  const _ThemeChooser({
    required this.selected,
    required this.onChanged,
  });

  final _ThemeChoice selected;
  final ValueChanged<_ThemeChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final lightSelected = selected == _ThemeChoice.light;
        final darkSelected = selected == _ThemeChoice.dark;

        final cards = [
          _ThemeOptionCard(
            title: 'Light Mode',
            icon: Icons.wb_sunny_outlined,
            selected: lightSelected,
            onTap: () => onChanged(_ThemeChoice.light),
          ),
          _ThemeOptionCard(
            title: 'Dark Mode',
            icon: Icons.nightlight_round,
            selected: darkSelected,
            onTap: () => onChanged(_ThemeChoice.dark),
            dark: true,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              cards.first,
              const SizedBox(height: 12),
              cards.last,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: 12),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF202C4B), Color(0xFF111828)],
          )
        : null;
    final foreground = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.mutedText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          gradient: background,
          color: background == null ? Colors.white : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? (dark ? Colors.white : const Color(0xFF2A6CE3))
                : const Color(0xFFE4E8EF),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (dark ? Colors.black : const Color(0xFF2A6CE3))
                        .withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (selected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF202938),
                    size: 18,
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foreground, size: 34),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dark ? 'Dark UI' : 'Bright UI',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.items,
  });

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      borderColor: const Color(0xFFE7EAF0),
      radius: 18,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _SettingsListTile(item: items[index]),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 72),
                child: Divider(height: 1, color: Color(0xFFE7EAF0)),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  const _SettingsListTile({
    required this.item,
  });

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7B8598),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.storeName,
  });

  final String version;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final store = context.read<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    return MarketSurfaceCard(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      borderColor: const Color(0xFFE7EAF0),
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            color: Color(0xFF2A6CE3),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName.isEmpty ? strings.currentStore : storeName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${strings.appVersion} $version',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

Color _colorForIcon(IconData icon) {
  if (icon == Icons.language_rounded) return const Color(0xFF6D4AE4);
  if (icon == Icons.brightness_6_rounded) return const Color(0xFF2A6CE3);
  if (icon == Icons.receipt_long_outlined) return const Color(0xFF1FA97A);
  if (icon == Icons.calculate_outlined) return const Color(0xFFF5A623);
  if (icon == Icons.shield_outlined) return const Color(0xFF6E4AE2);
  if (icon == Icons.cloud_upload_outlined) return const Color(0xFF2A6CE3);
  if (icon == Icons.info_outline_rounded) return const Color(0xFFE36A46);
  return const Color(0xFF2A6CE3);
}

Color _tintForIcon(IconData icon) {
  if (icon == Icons.language_rounded) return const Color(0xFFF1ECFF);
  if (icon == Icons.brightness_6_rounded) return const Color(0xFFEAF2FF);
  if (icon == Icons.receipt_long_outlined) return const Color(0xFFE5FBF4);
  if (icon == Icons.calculate_outlined) return const Color(0xFFFFF3DB);
  if (icon == Icons.shield_outlined) return const Color(0xFFF0EBFF);
  if (icon == Icons.cloud_upload_outlined) return const Color(0xFFEAF2FF);
  if (icon == Icons.info_outline_rounded) return const Color(0xFFFEECE7);
  return const Color(0xFFEAF2FF);
}
