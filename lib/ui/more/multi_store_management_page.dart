// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, prefer_const_literals_to_create_immutables, unnecessary_const

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final theme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.manropeTextTheme(Theme.of(context).textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(Theme.of(context).primaryTextTheme),
    );
    final locations = store.storeLocations;
    final currentStore =
        store.activeStoreLocation ?? store.currentStoreLocation;
    final extraLocations = currentStore == null
        ? locations
        : locations
            .where((location) => location.id != currentStore.id)
            .toList();

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FF),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(store: store),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    children: [
                      const _SectionTitle(title: 'CURRENT STORE'),
                      const SizedBox(height: 14),
                      if (currentStore != null)
                        _StoreCard(
                          storeLocation: currentStore,
                          isActive: true,
                          onSwitchTap: () =>
                              _viewDetails(context, currentStore),
                          onDetailsTap: () =>
                              _viewDetails(context, currentStore),
                        ),
                      if (extraLocations.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'ADDITIONAL STORES'),
                        const SizedBox(height: 14),
                      ],
                      _AddStoreCard(
                        onTap: () => _openAddStore(context),
                      ),
                      const SizedBox(height: 18),
                      if (extraLocations.isEmpty) const SizedBox(height: 4),
                      for (var index = 0;
                          index < extraLocations.length;
                          index++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == extraLocations.length - 1 ? 0 : 16,
                          ),
                          child: _StoreCard(
                            storeLocation: extraLocations[index],
                            isActive: extraLocations[index].isActive,
                            onSwitchTap: () =>
                                _switchStore(context, extraLocations[index]),
                            onDetailsTap: () =>
                                _viewDetails(context, extraLocations[index]),
                          ),
                        ),
                      const SizedBox(height: 6),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({
    required this.store,
  });

  final PosLocalStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F9FF),
            Color(0xFFEAF2FF),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF5A6478),
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Multi-Store Management',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F1D3A),
                        fontSize: 31,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Manage and monitor all your store locations',
                      style: const TextStyle(
                        color: Color(0xFF7E889A),
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddStoreCard extends StatelessWidget {
  const _AddStoreCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3578F0), Color(0xFF1358D5)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E63E0).withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AddStoreIcon(),
              SizedBox(width: 18),
              Text(
                'Add New Store',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddStoreIcon extends StatelessWidget {
  const _AddStoreIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.add_rounded,
        color: Color(0xFF2A69E2),
        size: 28,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF7C8799),
        fontSize: 16.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.storeLocation,
    required this.isActive,
    required this.onSwitchTap,
    required this.onDetailsTap,
  });

  final StoreLocationData storeLocation;
  final bool isActive;
  final VoidCallback onSwitchTap;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? const Color(0xFFCAD8F5) : const Color(0xFFE8EDF4),
          width: isActive ? 1.1 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x091B3B6B),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final infoColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeLocation.name,
                style: const TextStyle(
                  color: Color(0xFF12213F),
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                storeLocation.address,
                style: const TextStyle(
                  color: Color(0xFF7B8496),
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                storeLocation.category,
                style: const TextStyle(
                  color: Color(0xFF2A6CE3),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

          final actions = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isActive) ...[
                _StoreActionButton(
                  label: 'Switch Store',
                  icon: Icons.swap_horiz_rounded,
                  filled: true,
                  onTap: onSwitchTap,
                ),
                const SizedBox(height: 10),
              ],
              _StoreActionButton(
                label: 'View Details',
                icon: Icons.visibility_outlined,
                filled: false,
                onTap: onDetailsTap,
              ),
            ],
          );

          if (compact) {
            return Column(
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
                    const SizedBox(width: 16),
                    Expanded(child: infoColumn),
                  ],
                ),
                const SizedBox(height: 18),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StoreIconTile(
                accentColor: storeLocation.accentColor,
                tintColor: storeLocation.tintColor,
                logoPath: storeLocation.logoPath,
              ),
              const SizedBox(width: 16),
              Expanded(child: infoColumn),
              const SizedBox(width: 14),
              SizedBox(width: 252, child: actions),
            ],
          );
        },
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
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: logoPath == null || !File(logoPath!).existsSync()
          ? Center(
              child: Icon(
                Icons.storefront_outlined,
                color: accentColor,
                size: 38,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(logoPath!),
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _StoreActionButton extends StatelessWidget {
  const _StoreActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : const Color(0xFF2A6CE3);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3A7EF0), Color(0xFF2366E3)],
                  )
                : null,
            color: filled ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? Colors.transparent : const Color(0xFFD6DCE8),
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: const Color(0xFF2366E3).withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
