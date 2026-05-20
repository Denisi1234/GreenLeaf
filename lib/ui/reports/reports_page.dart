import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../widgets/market_shared_widgets.dart';
import 'reports_catalog_page.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const Color _ink = Color(0xFF162445);
  static const Color _muted = Color(0xFF7A859C);
  static const Color _border = Color(0xFFE8EBF1);
  static const Color _blue = Color(0xFF2B6FE8);
  static const Color _green = Color(0xFF30B05C);

  static const List<_OverviewCardData> _overviewCards = [
    _OverviewCardData(
      icon: Icons.shopping_bag_outlined,
      iconColor: Color(0xFF26A042),
      iconBackground: Color(0xFFEAF8EE),
      title: 'Total Sales Today',
      value: '\$2,845.50',
      delta: '12.5%',
      footer: 'vs Yesterday',
    ),
    _OverviewCardData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF2E6EE8),
      iconBackground: Color(0xFFECF3FF),
      title: 'Transactions',
      value: '38',
      delta: '8.6%',
      footer: 'vs Yesterday',
    ),
    _OverviewCardData(
      icon: Icons.sell_outlined,
      iconColor: Color(0xFF9747FF),
      iconBackground: Color(0xFFF3EAFE),
      title: 'Avg. Transaction Value',
      value: '\$74.88',
      delta: '3.4%',
      footer: 'vs Yesterday',
    ),
    _OverviewCardData(
      icon: Icons.inventory_2_outlined,
      iconColor: Color(0xFFC38A13),
      iconBackground: Color(0xFFFEF5E3),
      title: 'Top Selling Product',
      value: 'Classic Denim Jacket',
      footer: '12 sold',
      badge: 'Best Seller',
      highlightValue: true,
    ),
  ];

  static const List<_QuickActionData> _quickActions = [
    _QuickActionData(
      icon: Icons.shopping_bag_outlined,
      label: 'New Sale',
      iconColor: _blue,
      background: LinearGradient(
        colors: [Color(0xFF2F6FDF), Color(0xFF265ECB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      foreground: Colors.white,
      emphasized: true,
    ),
    _QuickActionData(
      icon: Icons.point_of_sale_outlined,
      label: 'Open Cash Drawer',
      iconColor: Color(0xFF2AA24F),
      iconBackground: Color(0xFFE9F8ED),
    ),
    _QuickActionData(
      icon: Icons.insert_chart_outlined_rounded,
      label: 'View Reports',
      iconColor: _blue,
      iconBackground: Color(0xFFECF2FF),
    ),
  ];

  static const List<_ActivityItemData> _activityItems = [
    _ActivityItemData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF2AA24F),
      iconBackground: Color(0xFFEAF8EE),
      title: 'Sale #1038',
      subtitle: '2 items • Card Payment',
      amount: '\$129.50',
      time: '10:24 AM',
    ),
    _ActivityItemData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF2E6EE8),
      iconBackground: Color(0xFFECF3FF),
      title: 'Sale #1037',
      subtitle: '1 item • Cash Payment',
      amount: '\$45.00',
      time: '10:12 AM',
    ),
    _ActivityItemData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF9747FF),
      iconBackground: Color(0xFFF3EAFE),
      title: 'Sale #1036',
      subtitle: '3 items • Card Payment',
      amount: '\$199.99',
      time: '9:58 AM',
    ),
    _ActivityItemData(
      icon: Icons.point_of_sale_outlined,
      iconColor: Color(0xFFC38A13),
      iconBackground: Color(0xFFFEF5E3),
      title: 'Cash Drawer Opened',
      subtitle: 'By Sarah Johnson',
      time: '9:45 AM',
    ),
    _ActivityItemData(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFF2AA24F),
      iconBackground: Color(0xFFEAF8EE),
      title: 'Sale #1035',
      subtitle: '1 item • Cash Payment',
      amount: '\$28.00',
      time: '9:33 AM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFEFC),
      drawer: MarketAppDrawer(selectedItem: 'Reports'),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: BackdropGlow()),
            Column(
              children: [
                _ReportsHeader(),
                Expanded(
                  child: CustomScrollView(
                    physics: BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            SizedBox(height: 1),
                            _OverviewGrid(cards: _overviewCards),
                            SizedBox(height: 14),
                            _SectionTitle('Quick Actions'),
                            SizedBox(height: 8),
                            _QuickActionsRow(actions: _quickActions),
                            SizedBox(height: 14),
                            _RecentHeader(),
                            SizedBox(height: 6),
                            _RecentActivityCard(items: _activityItems),
                            SizedBox(height: 16),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Color(0xFFFFFEFC),
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 12, 14, 9),
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DrawerMenuButton(
                          iconColor: Color(0xFF5C677D),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              'Store Overview',
                              style: TextStyle(
                                color: ReportsPage._ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _DateRow(),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE7EAF0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_month_outlined,
          size: 16,
          color: Color(0xFF8A93A7),
        ),
        SizedBox(width: 6),
        Text(
          'May 18, 2025 (Sun)',
          style: TextStyle(
            color: Color(0xFF7B859A),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: ReportsPage._ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.cards});

  final List<_OverviewCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth > 560 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(
                    width: itemWidth,
                    child: _OverviewCard(card: card),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.card});

  final _OverviewCardData card;

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _OverviewDetailPage(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _openDetails(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ReportsPage._border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C0E1726),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: card.iconBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(card.icon, color: card.iconColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.title,
                        style: const TextStyle(
                          color: ReportsPage._muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.value,
                  maxLines: card.highlightValue ? 2 : 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: ReportsPage._ink,
                    fontSize: card.highlightValue ? 13 : 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                if (card.delta != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        color: ReportsPage._green,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        card.delta!,
                        style: const TextStyle(
                          color: ReportsPage._green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          card.footer,
                          style: const TextStyle(
                            color: ReportsPage._muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Text(
                        card.footer,
                        style: const TextStyle(
                          color: ReportsPage._muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (card.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5E6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: Color(0xFFF2B437),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                card.badge!,
                                style: const TextStyle(
                                  color: Color(0xFFC78C17),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final isCompact = constraints.maxWidth < 360;
        final itemWidth = isCompact
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (actions.length - 1))) /
                actions.length;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => SizedBox(
                  width: itemWidth,
                  child: _QuickActionCard(action: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickActionData action;

  void _handleTap(BuildContext context) {
    switch (action.label) {
      case 'New Sale':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const MarketHomePage(),
          ),
        );
        break;
      case 'Open Cash Drawer':
        showMarketNotice(
          context,
          title: 'Cash Drawer',
          message: 'Cash drawer opened successfully.',
        );
        break;
      case 'View Reports':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const ReportsCatalogPage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconBackground =
        action.emphasized ? Colors.white : action.iconBackground!;
    final labelColor = action.foreground ?? ReportsPage._ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _handleTap(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 108),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: action.background,
            color: action.background == null ? Colors.white : null,
            borderRadius: BorderRadius.circular(4),
            border: action.background == null
                ? Border.all(color: ReportsPage._border)
                : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x140E1726),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(action.icon, color: action.iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader();

  void _openAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _RecentActivityPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const _SectionTitle('Recent Activity'),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _openAll(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: ReportsPage._blue,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: ReportsPage._blue,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<_ActivityItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ReportsPage._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100E1726),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              _ActivityTile(item: item),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE9ECF2),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final _ActivityItemData item;

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ActivityDetailPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 9, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: ReportsPage._ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: ReportsPage._muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.amount != null)
                    Text(
                      item.amount!,
                      style: const TextStyle(
                        color: ReportsPage._ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (item.amount != null) const SizedBox(height: 2),
                  Text(
                    item.time,
                    style: const TextStyle(
                      color: ReportsPage._muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7F889D),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewDetailPage extends StatelessWidget {
  const _OverviewDetailPage({required this.card});

  final _OverviewCardData card;

  String get _insight {
    switch (card.title) {
      case 'Total Sales Today':
        return 'Sales are trending upward compared with yesterday, which suggests stronger conversion and basket size today.';
      case 'Transactions':
        return 'Transaction count is healthy and moving in the right direction for the current trading window.';
      case 'Avg. Transaction Value':
        return 'Average basket value is improving, which usually means customers are buying more items per visit.';
      case 'Top Selling Product':
        return 'This product is leading today and is a strong candidate for reorder checks and featured placement.';
      default:
        return 'This metric is available and ready for deeper reporting.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: ReportsPage._ink,
        title: Text(card.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: ReportsPage._border),
                ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: card.iconBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(card.icon, color: card.iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.value,
                          style: const TextStyle(
                            color: ReportsPage._ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.footer,
                          style: const TextStyle(
                            color: ReportsPage._muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Overview',
              style: TextStyle(
                color: ReportsPage._ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _insight,
              style: const TextStyle(
                color: ReportsPage._muted,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (card.delta != null) ...[
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: ReportsPage._green,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${card.delta} improvement ${card.footer.toLowerCase()}',
                      style: const TextStyle(
                        color: ReportsPage._green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentActivityPage extends StatelessWidget {
  const _RecentActivityPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: ReportsPage._ink,
        title: const Text('Recent Activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        children: const [
          _RecentActivityCard(items: ReportsPage._activityItems),
        ],
      ),
    );
  }
}

class _ActivityDetailPage extends StatelessWidget {
  const _ActivityDetailPage({required this.item});

  final _ActivityItemData item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: ReportsPage._ink,
        title: Text(item.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ReportsPage._border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: ReportsPage._muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Time: ${item.time}',
                style: const TextStyle(
                  color: ReportsPage._ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.amount != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Amount: ${item.amount}',
                  style: const TextStyle(
                    color: ReportsPage._ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.footer,
    this.delta,
    this.badge,
    this.highlightValue = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final String footer;
  final String? delta;
  final String? badge;
  final bool highlightValue;
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.background,
    this.foreground,
    this.iconBackground,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Gradient? background;
  final Color? foreground;
  final Color? iconBackground;
  final bool emphasized;
}

class _ActivityItemData {
  const _ActivityItemData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.time,
    this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String time;
  final String? amount;
}
