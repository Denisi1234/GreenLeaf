// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_edit_store_page.dart';
import 'store_location_details_page.dart';

class MultiStoreManagementPage extends StatefulWidget {
  const MultiStoreManagementPage({super.key});

  @override
  State<MultiStoreManagementPage> createState() =>
      _MultiStoreManagementPageState();
}

class _MultiStoreManagementPageState extends State<MultiStoreManagementPage> {
  _StoreFilter _filter = _StoreFilter.all;
  _StoreSort _sort = _StoreSort.recent;
  String _selectedRange = 'Today';

  Future<void> _openAddStore(BuildContext context) async {
    final result = await Navigator.of(context).push<StoreFormResult?>(
      MaterialPageRoute<StoreFormResult?>(
        builder: (context) => const AddEditStorePage(),
      ),
    );
    if (!mounted || result == null) return;

    final store = context.read<PosLocalStore>();
    final storeId =
        'store-${DateTime.now().microsecondsSinceEpoch}-${store.storeLocations.length}';
    final created = await store.addStoreLocation(
      StoreLocationData(
        id: storeId,
        name: result.name,
        category: result.category,
        address: result.address,
        contactNumber: result.contactNumber,
        taxId: '',
        statusKey: 'operational',
        accentColorValue: _accentColorForIndex(store.storeLocations.length),
        tintColorValue: _tintColorForIndex(store.storeLocations.length),
        createdAt: DateTime.now().toIso8601String(),
        logoPath: result.logoPath,
        isActive: false,
      ),
      makeActive: false,
    );

    if (!mounted) return;
    showMarketNotice(
      context,
      title: 'Store Added',
      message: '${created.name} is now saved in your store list.',
    );
  }

  Future<void> _switchStore(
    BuildContext context,
    StoreLocationData storeLocation,
  ) async {
    final store = context.read<PosLocalStore>();
    await store.setActiveStoreLocation(storeLocation.id);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: 'Store Switched',
      message: '${storeLocation.name} is now the active store.',
    );
  }

  Future<void> _viewDetails(
    BuildContext context,
    StoreLocationData storeLocation,
  ) async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => StoreLocationDetailsPage(
          storeLocationId: storeLocation.id,
        ),
      ),
    );
  }

  Future<void> _showStoreActions(
    BuildContext context,
    StoreLocationData storeLocation,
  ) async {
    final store = context.read<PosLocalStore>();
    final isCurrent = storeLocation.isActive;
    final canDelete = storeLocation.id != 'store-current';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A1B3B6B),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                _StoreSheetHeader(storeLocation: storeLocation),
                const SizedBox(height: 14),
                if (!isCurrent)
                  _SheetActionTile(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Switch Store',
                    subtitle: 'Move the app to this store.',
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _switchStore(context, storeLocation);
                    },
                  ),
                _SheetActionTile(
                  icon: Icons.visibility_outlined,
                  title: 'View Details',
                  subtitle: 'Open the store profile screen.',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _viewDetails(context, storeLocation);
                  },
                ),
                if (canDelete)
                  _SheetActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Store',
                    subtitle: 'Remove this store from the list.',
                    destructive: true,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete store?'),
                          content: Text(
                            'Delete ${storeLocation.name}? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await store.deleteStoreLocation(storeLocation.id);
                        if (!mounted) return;
                        showMarketNotice(
                          context,
                          title: 'Store Deleted',
                          message:
                              '${storeLocation.name} was removed from the list.',
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<StoreLocationData> _applyFilter(List<StoreLocationData> locations) {
    Iterable<StoreLocationData> filtered = locations;
    switch (_filter) {
      case _StoreFilter.all:
        break;
      case _StoreFilter.operational:
        filtered = filtered.where((l) => l.statusKey == 'operational');
        break;
      case _StoreFilter.limited:
        filtered = filtered.where((l) => l.statusKey == 'limited');
        break;
      case _StoreFilter.closed:
        filtered = filtered.where((l) => l.statusKey == 'closed');
        break;
    }

    final list = filtered.toList();
    switch (_sort) {
      case _StoreSort.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _StoreSort.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _StoreSort.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final theme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.manropeTextTheme(Theme.of(context).textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(Theme.of(context).primaryTextTheme),
    );

    final locations = _applyFilter(store.storeLocations);
    final visibleLocations = locations;
    final summary = _StoreHubSummary.from(store.storeLocations);

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFF),
        body: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            children: [
              _StoreHubTopBar(
                title: strings.storeHub,
                onMenuTap: () {
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold?.hasDrawer ?? false) {
                    scaffold!.openDrawer();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                onNotificationTap: () {
                  showMarketNotice(
                    context,
                    title: strings.notifications,
                    message: strings.noNotifications,
                  );
                },
              ),
              const SizedBox(height: 18),
              _SummaryPanel(
                strings: strings,
                summary: summary,
                selectedRange: _selectedRange,
                onRangeChanged: (value) {
                  setState(() => _selectedRange = value);
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _PillControl(
                    label: strings.filters,
                    icon: Icons.tune_rounded,
                    onTap: () => _showFilterMenu(context, strings),
                  ),
                  _PillControl(
                    label: strings.sortBy,
                    icon: Icons.swap_vert_rounded,
                    onTap: () => _showSortMenu(context, strings),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _openAddStore(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6CEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: Text(
                        strings.addNewStore,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...visibleLocations.map(
                (location) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StoreHubCard(
                    storeLocation: location,
                    isCurrent: location.isActive,
                    strings: strings,
                    onTap: () => _showStoreActions(context, location),
                    onDetailsTap: () => _viewDetails(context, location),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (visibleLocations.isNotEmpty)
                Center(
                  child: Text(
                    '${strings.showingStores} 1-${visibleLocations.length} of ${store.storeLocations.length}',
                    style: const TextStyle(
                      color: Color(0xFF7D8697),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context, AppStrings strings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(strings.filters),
                subtitle: const Text('Choose which stores are shown.'),
              ),
              const Divider(height: 1),
              for (final option in _StoreFilter.values)
                ListTile(
                  title: Text(_filterLabel(option)),
                  trailing: option == _filter
                      ? const Icon(Icons.check_rounded, color: Color(0xFF2D6CEA))
                      : null,
                  onTap: () {
                    setState(() => _filter = option);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSortMenu(BuildContext context, AppStrings strings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(strings.sortBy),
                subtitle: const Text('Choose how stores are ordered.'),
              ),
              const Divider(height: 1),
              for (final option in _StoreSort.values)
                ListTile(
                  title: Text(_sortLabel(option)),
                  trailing: option == _sort
                      ? const Icon(Icons.check_rounded, color: Color(0xFF2D6CEA))
                      : null,
                  onTap: () {
                    setState(() => _sort = option);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StoreHubTopBar extends StatelessWidget {
  const _StoreHubTopBar({
    required this.title,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.menu_rounded,
          onTap: onMenuTap,
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF10203D),
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ),
        ),
        _NotificationButton(onTap: onNotificationTap),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF10203D),
                  size: 31,
                ),
              ),
              Positioned(
                right: 8,
                top: 6,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D6CEA),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: const Color(0xFF10203D),
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.strings,
    required this.summary,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final AppStrings strings;
  final _StoreHubSummary summary;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1F6FF),
            Color(0xFFE8F0FF),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2EAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.overallPerformanceSummary,
                      style: const TextStyle(
                        color: Color(0xFF10203D),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.acrossAllStores,
                      style: const TextStyle(
                        color: Color(0xFF7E889A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RangeChip(
                label: selectedRange,
                onTap: () async {
                  final value = await showMenu<String>(
                    context: context,
                    position: const RelativeRect.fromLTRB(999, 180, 16, 0),
                    items: const [
                      PopupMenuItem(value: 'Today', child: Text('Today')),
                      PopupMenuItem(value: 'This Week', child: Text('This Week')),
                      PopupMenuItem(value: 'This Month', child: Text('This Month')),
                      PopupMenuItem(value: 'All Time', child: Text('All Time')),
                    ],
                  );
                  if (value != null) {
                    onRangeChanged(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7EDF6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0B1A355F),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryMetricTile(
                    icon: Icons.storefront_outlined,
                    iconBackground: const Color(0xFFEAF2FF),
                    iconColor: const Color(0xFF2D6CEA),
                    label: strings.totalStores,
                    value: summary.totalStores.toString(),
                    footer: 'All locations',
                  ),
                ),
                Expanded(
                  child: _SummaryMetricTile(
                    icon: Icons.check_circle_outline_rounded,
                    iconBackground: const Color(0xFFEAF8F1),
                    iconColor: const Color(0xFF2F8C68),
                    label: strings.operational,
                    value: summary.operationalStores.toString(),
                    footer: 'Ready now',
                  ),
                ),
                Expanded(
                  child: _SummaryMetricTile(
                    icon: Icons.bar_chart_rounded,
                    iconBackground: const Color(0xFFF0ECFF),
                    iconColor: const Color(0xFF7351D6),
                    label: strings.limitedOperations,
                    value: summary.limitedStores.toString(),
                    footer: 'Needs attention',
                  ),
                ),
                Expanded(
                  child: _SummaryMetricTile(
                    icon: Icons.storefront_outlined,
                    iconBackground: const Color(0xFFFDEDED),
                    iconColor: const Color(0xFFC84545),
                    label: strings.closed,
                    value: summary.closedStores.toString(),
                    footer: 'Paused',
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

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EAF3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF10203D),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF10203D),
                size: 22,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 1,
                height: 24,
                color: const Color(0xFFE2E8F0),
              ),
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF2D6CEA),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.footer,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String value;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5C667A),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF10203D),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            footer,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8A94A6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillControl extends StatelessWidget {
  const _PillControl({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF334155)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF10203D),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Color(0xFF334155)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreHubCard extends StatelessWidget {
  const _StoreHubCard({
    required this.storeLocation,
    required this.isCurrent,
    required this.strings,
    required this.onTap,
    required this.onDetailsTap,
  });

  final StoreLocationData storeLocation;
  final bool isCurrent;
  final AppStrings strings;
  final VoidCallback onTap;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusVisual(storeLocation.statusKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isCurrent ? const Color(0xFFCDE0FF) : const Color(0xFFE7EDF6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x091B3B6B),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StoreIconTile(
                    accentColor: storeLocation.accentColor,
                    tintColor: storeLocation.tintColor,
                    logoPath: storeLocation.logoPath,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeLocation.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF10203D),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _StatusChip(
                          label: _statusLabel(strings, status.key),
                          background: status.background,
                          foreground: status.foreground,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          storeLocation.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7C8799),
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _StoreStat(
                    label: strings.categoryLabel,
                    value: storeLocation.category,
                  ),
                  _StoreStat(
                    label: strings.contactLabel,
                    value: storeLocation.contactNumber,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: _DetailsButton(
                  label: strings.viewDetails,
                  onTap: onDetailsTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreIconTile extends StatelessWidget {
  const _StoreIconTile({
    required this.accentColor,
    required this.tintColor,
    required this.logoPath,
  });

  final Color accentColor;
  final Color tintColor;
  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    final path = logoPath?.trim();
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: path == null || path.isEmpty || !File(path).existsSync()
          ? Center(
              child: Icon(
                Icons.storefront_outlined,
                color: accentColor,
                size: 34,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.storefront_outlined,
                      color: accentColor,
                      size: 34,
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _StoreStat extends StatelessWidget {
  const _StoreStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7A8495),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF10203D),
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ],
      ),
    );
  }
}

class _DetailsButton extends StatelessWidget {
  const _DetailsButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF2D6CEA),
                size: 34,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2D6CEA),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSheetHeader extends StatelessWidget {
  const _StoreSheetHeader({
    required this.storeLocation,
  });

  final StoreLocationData storeLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StoreIconTile(
          accentColor: storeLocation.accentColor,
          tintColor: storeLocation.tintColor,
          logoPath: storeLocation.logoPath,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeLocation.name,
                style: const TextStyle(
                  color: Color(0xFF10203D),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                storeLocation.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7C8799),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFC84545) : const Color(0xFF10203D);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: destructive ? const Color(0xFFFDEDED) : const Color(0xFFEAF2FF),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _StoreHubSummary {
  const _StoreHubSummary({
    required this.totalStores,
    required this.operationalStores,
    required this.limitedStores,
    required this.closedStores,
  });

  final int totalStores;
  final int operationalStores;
  final int limitedStores;
  final int closedStores;

  factory _StoreHubSummary.from(List<StoreLocationData> locations) {
    final operational = locations.where((l) => l.statusKey == 'operational').length;
    final limited = locations.where((l) => l.statusKey == 'limited').length;
    final closed = locations.where((l) => l.statusKey == 'closed').length;
    return _StoreHubSummary(
      totalStores: locations.length,
      operationalStores: operational,
      limitedStores: limited,
      closedStores: closed,
    );
  }
}

enum _StoreFilter { all, operational, limited, closed }
enum _StoreSort { recent, nameAsc, nameDesc }

String _filterLabel(_StoreFilter filter) {
  switch (filter) {
    case _StoreFilter.all:
      return 'All Stores';
    case _StoreFilter.operational:
      return 'Operational';
    case _StoreFilter.limited:
      return 'Limited Operations';
    case _StoreFilter.closed:
      return 'Closed';
  }
}

String _sortLabel(_StoreSort sort) {
  switch (sort) {
    case _StoreSort.recent:
      return 'Recently Added';
    case _StoreSort.nameAsc:
      return 'Name: A to Z';
    case _StoreSort.nameDesc:
      return 'Name: Z to A';
  }
}

_StatusVisual _statusVisual(String statusKey) {
  switch (statusKey.toLowerCase()) {
    case 'limited':
      return const _StatusVisual(
        key: 'limited',
        background: Color(0xFFFFF5DA),
        foreground: Color(0xFFCA8A04),
      );
    case 'closed':
      return const _StatusVisual(
        key: 'closed',
        background: Color(0xFFFDEDED),
        foreground: Color(0xFFC84545),
      );
    default:
      return const _StatusVisual(
        key: 'operational',
        background: Color(0xFFEAF8F1),
        foreground: Color(0xFF2F8C68),
      );
  }
}

String _statusLabel(AppStrings strings, String key) {
  switch (key) {
    case 'limited':
      return strings.limitedOperations;
    case 'closed':
      return strings.closed;
    default:
      return strings.operational;
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.key,
    required this.background,
    required this.foreground,
  });

  final String key;
  final Color background;
  final Color foreground;
}

int _accentColorForIndex(int index) {
  const colors = <int>[
    0xFF2F74E8,
    0xFF2D9A52,
    0xFF6C4AE2,
    0xFFC84545,
  ];
  return colors[index % colors.length];
}

int _tintColorForIndex(int index) {
  const colors = <int>[
    0xFFEAF2FF,
    0xFFE8F7EC,
    0xFFF0ECFF,
    0xFFFDEDED,
  ];
  return colors[index % colors.length];
}
