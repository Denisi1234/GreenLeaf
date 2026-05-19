import 'package:flutter/material.dart';

import 'about_app_page.dart';
import 'help_support_page.dart';
import 'multi_store_management_page.dart';
import 'staff_management_page.dart';
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

    return Scaffold(
      drawer: const MarketAppDrawer(selectedItem: 'Settings'),
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: const Color(0xFFFFFEFC),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Row(
                  children: [
                    const DrawerMenuButton(
                      iconColor: Color(0xFF5C677D),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'More',
                          style: TextStyle(
                            color: Color(0xFF162445),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
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
                        const _ProfileSummaryCard(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0E000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 4),
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
                                        borderRadius: BorderRadius.circular(16),
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
  const _ProfileSummaryCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              if (isNarrow)
                const Column(
                  children: [
                    _ProfileAvatar(),
                    SizedBox(height: 10),
                    _ProfileDetails(centered: true),
                  ],
                )
              else
                const Row(
                  children: [
                    _ProfileAvatar(),
                    SizedBox(width: 12),
                    Expanded(child: _ProfileDetails()),
                    Icon(
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
                const Column(
                  children: [
                    _StatBlock(
                      icon: Icons.receipt_long_outlined,
                      label: 'Total Sales',
                      value: 'TSH 61,401,250',
                    ),
                    SizedBox(height: 10),
                    Divider(height: 1, color: Color(0xFFE8EBF0)),
                    SizedBox(height: 10),
                    _StatBlock(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value: 'May 12, 2023',
                    ),
                  ],
                )
              else
                const Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.receipt_long_outlined,
                        label: 'Total Sales',
                        value: 'TSH 61,401,250',
                      ),
                    ),
                    SizedBox(
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
                        value: 'May 12, 2023',
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
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(42),
      ),
      child: const Icon(
        Icons.person,
        color: Color(0xFF1562E8),
        size: 54,
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const Text(
          'John Smith',
          style: TextStyle(
            color: Color(0xFF202938),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Store Owner',
          style: TextStyle(
            color: Color(0xFF7A8393),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          children: const [
            Icon(
              Icons.storefront_outlined,
              color: Color(0xFF1562E8),
              size: 20,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Downtown Outlet',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FF),
                borderRadius: BorderRadius.circular(13),
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
