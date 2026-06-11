import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class StoreLocationDetailsPage extends StatefulWidget {
  const StoreLocationDetailsPage({
    super.key,
    required this.storeLocationId,
  });

  final String storeLocationId;

  @override
  State<StoreLocationDetailsPage> createState() =>
      _StoreLocationDetailsPageState();
}

class _StoreLocationDetailsPageState extends State<StoreLocationDetailsPage> {
  StoreLocationData? _resolveLocation(PosLocalStore store) {
    for (final location in store.storeLocations) {
      if (location.id == widget.storeLocationId) {
        return location;
      }
    }
    if (widget.storeLocationId == 'store-current') {
      final profile = store.profile;
      return StoreLocationData(
        id: 'store-current',
        name:
            profile.storeName.isNotEmpty ? profile.storeName : 'Current Store',
        category: profile.businessCategory,
        address: profile.physicalAddress,
        contactNumber: profile.contactNumber,
        taxId: profile.taxId,
        statusKey: 'operational',
        accentColorValue: 0xFF2F74E8,
        tintColorValue: 0xFFEAF2FF,
        createdAt: profile.memberSince.isNotEmpty
            ? profile.memberSince
            : DateTime.now().toIso8601String(),
        logoPath: profile.logoPath,
        isActive: true,
      );
    }
    return null;
  }

  Future<void> _switchStore(StoreLocationData location) async {
    final store = context.read<PosLocalStore>();
    await store.setActiveStoreLocation(location.id);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: 'Store Switched',
      message: '${location.name} is now the active store.',
    );
  }

  Future<void> _deleteStore(StoreLocationData location) async {
    final store = context.read<PosLocalStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete store?'),
          content: Text(
            'This will remove ${location.name} from your store list. '
            'You can add it again later if needed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC83D3D),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await store.deleteStoreLocation(location.id);
    if (!mounted) return;

    showMarketNotice(
      context,
      title: 'Store Deleted',
      message: '${location.name} was removed from your store list.',
      type: MarketNoticeType.warning,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final location = _resolveLocation(store);

    final baseTheme = Theme.of(context);
    final themed = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    if (location == null) {
      return Theme(
        data: themed,
        child: const Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This store is no longer available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Theme(
      data: themed,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: MarketPageHeader(
                  title: 'Store Details',
                  showBackButton: true,
                  centerTitle: true,
                  titleSize: 19,
                  titleWeight: FontWeight.w600,
                  transparent: false,
                  showBorder: true,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: _SummaryCard(location: location),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SectionCard(
                    title: 'Store information',
                    children: [
                      _DetailRow(
                        icon: Icons.badge_outlined,
                        label: 'Category',
                        value: location.category,
                      ),
                      const _SectionDivider(),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: location.address,
                      ),
                      const _SectionDivider(),
                      _DetailRow(
                        icon: Icons.call_outlined,
                        label: 'Contact',
                        value: location.contactNumber,
                      ),
                      const _SectionDivider(),
                      _DetailRow(
                        icon: Icons.info_outline_rounded,
                        label: 'Status',
                        value: _statusLabel(location.statusKey),
                      ),
                      const _SectionDivider(),
                      _DetailRow(
                        icon: Icons.schedule_outlined,
                        label: 'Added',
                        value: _formatDate(location.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: _SectionCard(
                    title: 'Actions',
                    children: [
                      if (!location.isActive) ...[
                        _ActionButton(
                          label: 'Switch Store',
                          icon: Icons.swap_horiz_rounded,
                          isPrimary: true,
                          onTap: () => _switchStore(location),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (location.id != 'store-current')
                        _ActionButton(
                          label: 'Delete Store',
                          icon: Icons.delete_outline_rounded,
                          isPrimary: false,
                          isDanger: true,
                          onTap: () => _deleteStore(location),
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.location,
  });

  final StoreLocationData location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B3B6B),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _LogoTile(location: location),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    color: Color(0xFF11203D),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  location.isActive ? 'Current active store' : 'Store location',
                  style: const TextStyle(
                    color: Color(0xFF708096),
                    fontSize: 13.5,
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

class _LogoTile extends StatelessWidget {
  const _LogoTile({
    required this.location,
  });

  final StoreLocationData location;

  @override
  Widget build(BuildContext context) {
    final logoPath = location.logoPath;
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: location.tintColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: logoPath == null || !File(logoPath).existsSync()
          ? Icon(
              Icons.storefront_outlined,
              color: location.accentColor,
              size: 34,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(logoPath),
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7A8598),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2A6CE3),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A8598),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF11203D),
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
    this.isDanger = false,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDanger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isDanger
        ? const Color(0xFFC83D3D)
        : isPrimary
            ? Colors.white
            : const Color(0xFF2A6CE3);
    final background = isDanger
        ? const Color(0xFFFDECEC)
        : isPrimary
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3578F0), Color(0xFF1358D5)],
              )
            : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: background is LinearGradient ? background : null,
            color: background is Color
                ? background
                : isPrimary
                    ? null
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDanger
                  ? const Color(0xFFF1B9B9)
                  : isPrimary
                      ? Colors.transparent
                      : const Color(0xFFD8DFEA),
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E63E0).withValues(alpha: 0.18),
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Color(0xFFE8EDF4)),
    );
  }
}

String _statusLabel(String statusKey) {
  switch (statusKey.toLowerCase()) {
    case 'limited':
    case 'limited_operations':
      return 'Limited Operations';
    case 'closed':
      return 'Closed';
    default:
      return 'Operational';
  }
}

String _formatDate(String isoValue) {
  final parsed = DateTime.tryParse(isoValue);
  if (parsed == null) return isoValue;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}
