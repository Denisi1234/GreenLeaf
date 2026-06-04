import 'package:flutter/material.dart';

class ReportHubPage extends StatelessWidget {
  const ReportHubPage({super.key});

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5EAF1);
  static const Color _green = Color(0xFF1F9D55);
  static const Color _blue = Color(0xFF255DCC);

  static const List<_HubCardData> _cards = [
    _HubCardData(
      title: 'Sales',
      subtitle: 'Track performance, analyze trends, and grow revenue.',
      icon: Icons.show_chart_rounded,
      iconColor: _green,
      tint: Color(0xFFF2FBF5),
      arrowColor: _green,
    ),
    _HubCardData(
      title: 'Inventory',
      subtitle: 'Monitor stock levels, turnover, and product performance.',
      icon: Icons.inventory_2_rounded,
      iconColor: _blue,
      tint: Color(0xFFF3F7FF),
      arrowColor: _blue,
    ),
    _HubCardData(
      title: 'Team',
      subtitle: 'Evaluate team performance and track key metrics.',
      icon: Icons.groups_rounded,
      iconColor: _green,
      tint: Color(0xFFF0FBF4),
      arrowColor: _green,
    ),
    _HubCardData(
      title: 'Forecasting',
      subtitle: 'Plan ahead with predictive insights and scenarios.',
      icon: Icons.auto_graph_rounded,
      iconColor: _blue,
      tint: Color(0xFFF4F7FF),
      arrowColor: _blue,
    ),
  ];

  static const List<_RecentItemData> _recentItems = [
    _RecentItemData(
      title: 'Sales Summary',
      subtitle: 'Last viewed today, 9:30 AM',
      icon: Icons.show_chart_rounded,
      iconTint: Color(0xFFEAF8EE),
      iconColor: Color(0xFF1F9D55),
    ),
    _RecentItemData(
      title: 'Inventory Overview',
      subtitle: 'Last viewed yesterday, 4:15 PM',
      icon: Icons.inventory_2_rounded,
      iconTint: Color(0xFFEAF1FF),
      iconColor: Color(0xFF255DCC),
    ),
    _RecentItemData(
      title: 'Team Performance',
      subtitle: 'Last viewed May 20, 2:45 PM',
      icon: Icons.groups_rounded,
      iconTint: Color(0xFFEAF8EE),
      iconColor: Color(0xFF1F9D55),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 760 ? 760.0 : constraints.maxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Report Hub',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.3,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Explore insights and make data-driven decisions.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, innerConstraints) {
                          const gap = 12.0;
                          final cardWidth =
                              (innerConstraints.maxWidth - gap) / 2;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: _cards
                                .map((card) => SizedBox(
                                      width: cardWidth,
                                      child: _HubCard(data: card),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _RecentViewedCard(items: _recentItems),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.data});

  final _HubCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      decoration: BoxDecoration(
        color: const Color(0xFFFEFFFF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: ReportHubPage._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 170,
                height: 140,
                decoration: BoxDecoration(
                  color: data.tint,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: data.iconColor.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 2,
                      left: 22,
                      child: Icon(
                        data.icon,
                        size: 92,
                        color: data.iconColor.withValues(alpha: 0.24),
                      ),
                    ),
                    Icon(
                      data.icon,
                      size: 86,
                      color: data.iconColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(
              color: ReportHubPage._ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.55,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            style: const TextStyle(
              color: ReportHubPage._muted,
              fontSize: 11.1,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.arrowColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentViewedCard extends StatelessWidget {
  const _RecentViewedCard({required this.items});

  final List<_RecentItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ReportHubPage._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recently Viewed',
                  style: TextStyle(
                    color: ReportHubPage._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: ReportHubPage._green,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                _RecentViewedTile(item: item),
                if (index != items.length - 1)
                  const Divider(height: 1, color: Color(0xFFE7EBF2)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _RecentViewedTile extends StatelessWidget {
  const _RecentViewedTile({required this.item});

  final _RecentItemData item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconTint,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: ReportHubPage._ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: ReportHubPage._muted,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF8D96A8),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _HubCardData {
  const _HubCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.arrowColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final Color arrowColor;
}

class _RecentItemData {
  const _RecentItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconTint,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconTint;
  final Color iconColor;
}
