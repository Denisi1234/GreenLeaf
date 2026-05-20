import 'package:flutter/material.dart';

import '../widgets/market_shared_widgets.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _AboutItem('Terms of Service', Icons.description_outlined),
      _AboutItem('Privacy Policy', Icons.shield_outlined),
      _AboutItem('Licenses', Icons.info_outline_rounded),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1562E8), Color(0xFF0C56D7)],
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
                      'About App',
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    const _PayPointLogo(),
                    const SizedBox(height: 18),
                    const Text(
                      'PayPoint',
                      style: TextStyle(
                        color: Color(0xFF1554C8),
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const Text(
                      'POS',
                      style: TextStyle(
                        color: Color(0xFF1554C8),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1554C8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Version 2.4.1',
                      style: TextStyle(
                        color: Color(0xFF3D4B67),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'PayPoint POS empowers businesses to accept payments, manage sales, and grow with confidence anytime, anywhere.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF3D4B67),
                          fontSize: 16,
                          height: 1.9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE4E8EF)),
                      ),
                      child: Column(
                        children: [
                          ...items.asMap().entries.map(
                            (entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Column(
                                children: [
                                  _AboutTile(item: item),
                                  if (index != items.length - 1)
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFE7EBF0),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '© 2024 PayPoint. All rights reserved.',
                      style: TextStyle(
                        color: Color(0xFF6F7887),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
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

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.item});

  final _AboutItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showMarketNotice(
          context,
          title: item.label,
          message: '${item.label} can be connected to the full document next',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                color: const Color(0xFF1554C8),
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF1B2A4A),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF1554C8),
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayPointLogo extends StatelessWidget {
  const _PayPointLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 18,
            top: 24,
            child: Transform.rotate(
              angle: 0.08,
              child: Container(
                width: 70,
                height: 118,
                decoration: BoxDecoration(
                  color: const Color(0xFF1554C8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 12,
            child: Transform.rotate(
              angle: 0.04,
              child: Container(
                width: 74,
                height: 126,
                decoration: BoxDecoration(
                  color: const Color(0xFF1554C8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Positioned(
            left: 26,
            top: 6,
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                width: 84,
                height: 136,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1554C8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF1554C8),
                          width: 2.4,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_tethering_rounded,
                        color: Color(0xFF1554C8),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutItem {
  const _AboutItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
