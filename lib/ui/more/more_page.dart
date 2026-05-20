import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'about_app_page.dart';
import 'help_support_page.dart';
import 'multi_store_management_page.dart';
import 'store_profile_page.dart';
import 'staff_management_page.dart';
import 'subscription_plan_page.dart';
import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _MoreMenuItem('Store Profile', Icons.storefront_outlined),
      _MoreMenuItem('Staff Management', Icons.groups_2_outlined),
      _MoreMenuItem(
          'Multi-Store Management', Icons.store_mall_directory_outlined),
      _MoreMenuItem('Tax & Discounts', Icons.sell_outlined),
      _MoreMenuItem('Subscription Plan', Icons.description_outlined),
      _MoreMenuItem('Help & Support', Icons.support_agent_outlined),
      _MoreMenuItem('About App', Icons.info_outline_rounded),
    ];
    final store = context.watch<PosLocalStore>();
    final profile = store.profile;
    final totalSales = store.orders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final totalSalesLabel = totalSales <= 0
        ? 'No sales yet'
        : 'TSH ${totalSales.toStringAsFixed(0)}';
    final memberSince =
        profile.memberSince.isEmpty ? 'Not set' : profile.memberSince;

    return Scaffold(
      drawer: const MarketAppDrawer(selectedItem: ''),
      body: SafeArea(
        child: Column(
          children: [
            const Material(
              color: Color(0xFFFFFEFC),
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
                  child: Row(
                    children: [
                      DrawerMenuButton(
                        iconColor: Color(0xFF5C677D),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'More',
                            style: TextStyle(
                              color: Color(0xFF162445),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE7EAF0),
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: BackdropGlow()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                    child: Column(
                      children: [
                        _ProfileSummaryCard(
                          ownerName: profile.ownerName,
                          roleTitle: profile.roleTitle,
                          storeName: profile.storeName,
                          logoPath: profile.logoPath,
                          totalSales: totalSalesLabel,
                          memberSince: memberSince,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0E000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ...items.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final isLowerSection =
                                        index >= items.length - 2;
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: isLowerSection ? 10 : 0,
                                            bottom: isLowerSection ? 10 : 0,
                                          ),
                                          child: _MoreListTile(item: item),
                                        ),
                                        if (index != items.length - 1)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 68),
                                            child: Divider(
                                              height: 1,
                                              color: Color(0xFFE8EBF0),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 48, 14, 14),
                                  child: GestureDetector(
                                    onTap: () {
                                      showMarketNotice(
                                        context,
                                        title: 'Logged Out',
                                        message:
                                            'You can connect the real auth flow next',
                                      );
                                    },
                                    child: Container(
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFFE65B5B),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.logout_rounded,
                                            color: Color(0xFFE65B5B),
                                            size: 22,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Log Out',
                                            style: TextStyle(
                                              color: Color(0xFFE65B5B),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.ownerName,
    required this.roleTitle,
    required this.storeName,
    required this.logoPath,
    required this.totalSales,
    required this.memberSince,
  });

  final String ownerName;
  final String roleTitle;
  final String storeName;
  final String? logoPath;
  final String totalSales;
  final String memberSince;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (isNarrow)
                Column(
                  children: [
                    _ProfileAvatar(logoPath: logoPath),
                    const SizedBox(height: 10),
                    _ProfileDetails(
                      centered: true,
                      ownerName: ownerName,
                      roleTitle: roleTitle,
                      storeName: storeName,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    _ProfileAvatar(logoPath: logoPath),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfileDetails(
                        ownerName: ownerName,
                        roleTitle: roleTitle,
                        storeName: storeName,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF202938),
                      size: 30,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE8EBF0)),
              const SizedBox(height: 10),
              if (isNarrow)
                Column(
                  children: [
                    _StatBlock(
                      icon: Icons.receipt_long_outlined,
                      label: 'Total Sales',
                      value: totalSales,
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFE8EBF0)),
                    const SizedBox(height: 10),
                    _StatBlock(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value: memberSince,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.receipt_long_outlined,
                        label: 'Total Sales',
                        value: totalSales,
                      ),
                    ),
                    const SizedBox(
                      height: 52,
                      child: VerticalDivider(
                        color: Color(0xFFE2E6EE),
                        thickness: 1,
                      ),
                    ),
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member Since',
                        value: memberSince,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.logoPath});

  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(42),
      ),
      child: logoPath == null
          ? const Icon(
              Icons.person,
              color: Color(0xFF1562E8),
              size: 54,
            )
          : ClipOval(
              child: Image.file(
                File(logoPath!),
                width: 84,
                height: 84,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({
    this.centered = false,
    required this.ownerName,
    required this.roleTitle,
    required this.storeName,
  });

  final bool centered;
  final String ownerName;
  final String roleTitle;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          ownerName.isEmpty ? 'Store profile not set' : ownerName,
          style: const TextStyle(
            color: Color(0xFF202938),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          roleTitle.isEmpty ? 'Business Owner' : roleTitle,
          style: const TextStyle(
            color: Color(0xFF7A8393),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: Color(0xFF1562E8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                storeName.isEmpty ? 'Set up store profile' : storeName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF202938),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1562E8), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6F7887),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1562E8),
                    fontSize: 13.4,
                    fontWeight: FontWeight.w800,
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

class _MoreListTile extends StatelessWidget {
  const _MoreListTile({required this.item});

  final _MoreMenuItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.label == 'Store Profile') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const StoreProfilePage(),
            ),
          );
          return;
        }

        if (item.label == 'Staff Management') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const StaffManagementPage(),
            ),
          );
          return;
        }

        if (item.label == 'Multi-Store Management') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const MultiStoreManagementPage(),
            ),
          );
          return;
        }

        if (item.label == 'Help & Support') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const HelpSupportPage(),
            ),
          );
          return;
        }

        if (item.label == 'Subscription Plan') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const SubscriptionPlanPage(),
            ),
          );
          return;
        }

        if (item.label == 'About App') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const AboutAppPage(),
            ),
          );
          return;
        }

        showMarketNotice(
          context,
          title: item.label,
          message: '${item.label} module is ready for the next step',
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF1562E8),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF202938),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF6F7887),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem {
  const _MoreMenuItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
