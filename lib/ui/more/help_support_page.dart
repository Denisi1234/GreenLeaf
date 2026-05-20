import 'package:flutter/material.dart';

import '../widgets/market_shared_widgets.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    const supportItems = [
      _SupportItem(
        title: 'Chat with Us',
        subtitle: 'Get real-time help from our support team',
        icon: Icons.chat_bubble_rounded,
      ),
      _SupportItem(
        title: 'Email Support',
        subtitle: 'Send us an email and we will get back to you',
        icon: Icons.email_rounded,
      ),
      _SupportItem(
        title: 'Call Help Center',
        subtitle: 'Speak with our support team',
        icon: Icons.call_rounded,
      ),
      _SupportItem(
        title: 'User Guide',
        subtitle: 'Step-by-step guides and resources',
        icon: Icons.menu_book_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1562E8), Color(0xFF0F56D9)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Help & Support',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                children: [
                  const Text(
                    'Find answers fast',
                    style: TextStyle(
                      color: Color(0xFF20345F),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 74,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE1E6EF)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Color(0xFF253A68),
                          size: 34,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Search FAQs',
                            style: TextStyle(
                              color: Color(0xFFA3ACBB),
                              fontSize: 16.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE7EBF0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ...supportItems.asMap().entries.map(
                          (entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Column(
                              children: [
                                _SupportTile(item: item),
                                if (index != supportItems.length - 1)
                                  const Divider(height: 1, color: Color(0xFFE9EDF3)),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE7EBF0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        _ShieldSupportIcon(),
                        SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'We are here to help',
                                style: TextStyle(
                                  color: Color(0xFF1D376C),
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Your satisfaction is our priority.',
                                style: TextStyle(
                                  color: Color(0xFF7B8494),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
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
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _HelpBottomNavItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                  ),
                  _HelpBottomNavItem(
                    icon: Icons.sync_alt_rounded,
                    label: 'Transactions',
                  ),
                  _HelpCenterNavItem(),
                  _HelpBottomNavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                  ),
                  _HelpBottomNavItem(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                    active: true,
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

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.item});

  final _SupportItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showMarketNotice(
          context,
          title: item.title,
          message: '${item.title} can be connected to the live support flow next',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FF),
                borderRadius: BorderRadius.circular(37),
              ),
              child: Icon(item.icon, color: const Color(0xFF1562E8), size: 40),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFF132F66),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF7B8494),
                      fontSize: 14.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF132F66),
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShieldSupportIcon extends StatelessWidget {
  const _ShieldSupportIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.shield_outlined,
        color: Color(0xFF1562E8),
        size: 34,
      ),
    );
  }
}

class _HelpBottomNavItem extends StatelessWidget {
  const _HelpBottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF1562E8) : const Color(0xFF6F7887);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 31),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HelpCenterNavItem extends StatelessWidget {
  const _HelpCenterNavItem();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1562E8), Color(0xFF0F56D9)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x331562E8),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.point_of_sale_outlined,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sale',
          style: TextStyle(
            color: Color(0xFF4C5A75),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SupportItem {
  const _SupportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
