import 'package:flutter/material.dart';

import 'add_edit_store_page.dart';
import '../widgets/market_shared_widgets.dart';

class MultiStoreManagementPage extends StatefulWidget {
  const MultiStoreManagementPage({super.key});

  @override
  State<MultiStoreManagementPage> createState() =>
      _MultiStoreManagementPageState();
}

class _MultiStoreManagementPageState extends State<MultiStoreManagementPage> {
  static const _branches = <_BranchItem>[
    _BranchItem(
      name: 'Main Branch',
      address: '123 Business Rd, Colombo 03, Sri Lanka',
      code: 'CCB001',
      phone: '+94 11 234 5678',
      email: 'mainbranch@pos.com',
      manager: 'Nimal Perera',
      openingHours: 'Mon - Sun: 9:00 AM - 9:00 PM',
      timezone: 'Asia/Colombo (GMT +5:30)',
      statusLabel: 'Active',
      statusBackground: Color(0xFFE9F8E8),
      statusTextColor: Color(0xFF23863F),
      icon: Icons.apartment_outlined,
      iconBackground: Color(0xFFE8F0FF),
      iconColor: Color(0xFF2B5FCE),
    ),
    _BranchItem(
      name: 'City Center Branch',
      address: '45 Park Street, Colombo 02, Sri Lanka',
      code: 'CCB001',
      phone: '+94 11 234 5678',
      email: 'citycenter@pos.com',
      manager: 'Nimal Perera',
      openingHours: 'Mon - Sun: 9:00 AM - 9:00 PM',
      timezone: 'Asia/Colombo (GMT +5:30)',
      statusLabel: 'Active',
      statusBackground: Color(0xFFE9F8E8),
      statusTextColor: Color(0xFF23863F),
      icon: Icons.storefront_outlined,
      iconBackground: Color(0xFFE7F7EA),
      iconColor: Color(0xFF26A34A),
      isExpanded: true,
    ),
    _BranchItem(
      name: 'Kandy Branch',
      address: 'No. 12, Peradeniya Road, Kandy, Sri Lanka',
      code: 'KDB014',
      phone: '+94 81 222 4455',
      email: 'kandy@pos.com',
      manager: 'Sanjeewa Kumara',
      openingHours: 'Mon - Sun: 9:00 AM - 8:00 PM',
      timezone: 'Asia/Colombo (GMT +5:30)',
      statusLabel: 'Inactive',
      statusBackground: Color(0xFFFFF1DB),
      statusTextColor: Color(0xFFD68A00),
      icon: Icons.store_outlined,
      iconBackground: Color(0xFFFDF0D7),
      iconColor: Color(0xFFD39A08),
    ),
    _BranchItem(
      name: 'Negombo Branch',
      address: '78 Lewis Place, Negombo, Sri Lanka',
      code: 'NGB022',
      phone: '+94 31 222 8899',
      email: 'negombo@pos.com',
      manager: 'Tharindu Silva',
      openingHours: 'Mon - Sun: 9:00 AM - 9:00 PM',
      timezone: 'Asia/Colombo (GMT +5:30)',
      statusLabel: 'Active',
      statusBackground: Color(0xFFE9F8E8),
      statusTextColor: Color(0xFF23863F),
      icon: Icons.store_outlined,
      iconBackground: Color(0xFFF1ECFF),
      iconColor: Color(0xFF7D5CE0),
    ),
  ];

  int _expandedIndex = 1;

  Future<void> _openAddBranch() async {
    final created = await Navigator.of(context).push<StoreFormResult>(
      MaterialPageRoute<StoreFormResult>(
        builder: (context) => const AddEditStorePage(),
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    showMarketNotice(
      context,
      title: 'Branch Added',
      message: '${created.name} is now part of branch management',
    );
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? -1 : index;
    });
  }

  void _showFilterNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Branches'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Active Only'),
              trailing: Icon(Icons.check_circle_outline),
            ),
            ListTile(
              title: Text('Main Branches'),
            ),
            ListTile(
              title: Text('Recent Activity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSwitchNotice(String branchName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Branch?'),
        content: Text(
            'Are you sure you want to switch to $branchName? You will be logged into this branch\'s management system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showMarketNotice(
                context,
                title: 'Branch Switched',
                message: 'Now managing $branchName',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B5FCE),
            ),
            child: const Text('Switch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                const MarketPageHeader(title: 'Branch Management'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDDE2EA)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: Color(0xFF7A8393),
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Search branches...',
                                  style: TextStyle(
                                    color: Color(0xFFABB2BF),
                                    fontSize: 15.2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showFilterNotice,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDDE2EA)),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF1E273A),
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                    itemCount: _branches.length,
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
                      final isExpanded = _expandedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BranchCard(
                          branch: branch,
                          isExpanded: isExpanded,
                          onToggle: () => _toggleExpanded(index),
                          onSwitch: () => _showSwitchNotice(branch.name),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 84,
              child: GestureDetector(
                onTap: _openAddBranch,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2B5FCE),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add New Branch',
                      style: TextStyle(
                        color: Color(0xFF2B5FCE),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.isExpanded,
    required this.onToggle,
    required this.onSwitch,
  });

  final _BranchItem branch;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      borderColor: const Color(0xFFE1E5EC),
      radius: 8,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: branch.iconBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      branch.icon,
                      color: branch.iconColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style: const TextStyle(
                            color: Color(0xFF1E273A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF7A8393),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                branch.address,
                                style: const TextStyle(
                                  color: Color(0xFF7A8393),
                                  fontSize: 13.7,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: branch.statusBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          branch.statusLabel,
                          style: TextStyle(
                            color: branch.statusTextColor,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF667085),
                        size: 30,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _BranchDetails(
              branch: branch,
              onSwitch: onSwitch,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _BranchDetails extends StatelessWidget {
  const _BranchDetails({
    required this.branch,
    required this.onSwitch,
  });

  final _BranchItem branch;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E8EF)),
        ),
        child: Column(
          children: [
            _BranchDetailRow(
              icon: Icons.apartment_outlined,
              label: 'Branch Code',
              value: branch.code,
            ),
            _BranchDetailRow(
              icon: Icons.call_outlined,
              label: 'Phone',
              value: branch.phone,
            ),
            _BranchDetailRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: branch.email,
            ),
            _BranchDetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Manager',
              value: branch.manager,
            ),
            _BranchHoursPanel(openingHours: branch.openingHours),
            _BranchDetailRow(
              icon: Icons.access_time_outlined,
              label: 'Timezone',
              value: branch.timezone,
              isLast: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GestureDetector(
                onTap: onSwitch,
                child: const MarketSurfaceCard(
                  backgroundColor: Color(0xFF2B5FCE),
                  borderColor: Color(0xFF2B5FCE),
                  radius: 8,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Switch Branch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
    );
  }
}

class _BranchHoursPanel extends StatelessWidget {
  const _BranchHoursPanel({required this.openingHours});

  final String openingHours;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7EAF0)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E8EF)),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF6F7887),
                size: 18,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6ECF5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Store Hours',
                      style: TextStyle(
                        color: Color(0xFF7A8393),
                        fontSize: 13.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      openingHours,
                      style: const TextStyle(
                        color: Color(0xFF1E273A),
                        fontSize: 14.4,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Standard weekly schedule',
                      style: TextStyle(
                        color: Color(0xFF9AA3B2),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchDetailRow extends StatelessWidget {
  const _BranchDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE7EAF0)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E8EF)),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6F7887),
                size: 18,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A8393),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E273A),
                  fontSize: 14.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchItem {
  const _BranchItem({
    required this.name,
    required this.address,
    required this.code,
    required this.phone,
    required this.email,
    required this.manager,
    required this.openingHours,
    required this.timezone,
    required this.statusLabel,
    required this.statusBackground,
    required this.statusTextColor,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.isExpanded = false,
  });

  final String name;
  final String address;
  final String code;
  final String phone;
  final String email;
  final String manager;
  final String openingHours;
  final String timezone;
  final String statusLabel;
  final Color statusBackground;
  final Color statusTextColor;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool isExpanded;
}
