import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'about_app_page.dart';
import 'help_support_page.dart';
import 'multi_store_management_page.dart';
import 'smartduka_ai_advisor_page.dart';
import 'store_profile_page.dart';
import 'staff_management_page.dart';
import 'subscription_plan_page.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
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
      _MoreMenuItem('MYDUKA AI', Icons.psychology_alt_outlined),
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
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        drawer: const MarketAppDrawer(selectedItem: 'More'),
        body: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            SafeArea(
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE7EAF0)),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) {
                              return IconButton(
                                onPressed: () => Scaffold.of(context).openDrawer(),
                                icon: const Icon(
                                  Icons.menu,
                                  color: AppColors.ink,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'More',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          _HeaderActionCircle(
                            icon: Icons.person_outline_rounded,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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
                        _MoreMenuCard(items: items),
                        const SizedBox(height: 12),
                        _LogoutButton(
                          onTap: () {
                            showMarketNotice(
                              context,
                              title: 'Logged Out',
                              message:
                                  'You can connect the real auth flow next',
                            );
                          },
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

class _HeaderActionCircle extends StatelessWidget {
  const _HeaderActionCircle({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE7EAF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0E1726),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: AppColors.ink,
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
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7EAF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0E1726),
                blurRadius: 7,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileDetails(
                        ownerName: ownerName,
                        roleTitle: roleTitle,
                        storeName: storeName,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF7B8598),
                      size: 28,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE7EAF0)),
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
                    const Divider(height: 1, color: Color(0xFFE7EAF0)),
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
                        color: Color(0xFFE7EAF0),
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

class _MoreMenuCard extends StatelessWidget {
  const _MoreMenuCard({required this.items});

  final List<_MoreMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0E1726),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _MoreListTile(item: items[index]),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 68),
                child: Divider(
                  height: 1,
                  color: Color(0xFFE7EAF0),
                ),
              ),
          ],
        ],
      ),
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

        if (item.label == 'MYDUKA AI') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const MyDukaAiPage(),
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE6E8F0)),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF5B8CFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EAF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0E1726),
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}

class _MoreMenuItem {
  const _MoreMenuItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
