import 'package:flutter/material.dart';
import '../../widgets/app_design.dart';

class OverviewCardData {
  const OverviewCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.footer,
    this.delta,
    this.deltaIsPositive,
    this.highlightValue = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final String footer;
  final String? delta;
  final bool? deltaIsPositive;
  final bool highlightValue;
}

class OverviewDetailPage extends StatelessWidget {
  const OverviewDetailPage({super.key, required this.card});

  final OverviewCardData card;

  String get _insight {
    switch (card.title) {
      case 'Sales today':
        return 'This shows how much came in today compared with yesterday. It is a quick read on how the day is going.';
      case 'Orders today':
        return 'This is the number of orders completed today. It helps you see if foot traffic is picking up.';
      case 'Average order':
        return 'A higher average order usually means people are adding more items or choosing higher-value products.';
      case 'Best seller':
        return 'This is the item moving fastest today. It is a good one to keep stocked and visible.';
      default:
        return 'This metric is ready if you want a closer look.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFEFC),
        elevation: 0,
        foregroundColor: AppColors.reportsInk,
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
                border: Border.all(color: AppColors.reportsBorder),
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
                            color: AppColors.reportsInk,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.footer,
                          style: const TextStyle(
                            color: AppColors.reportsMuted,
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
              'What this means',
              style: TextStyle(
                color: AppColors.reportsInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _insight,
              style: const TextStyle(
                color: AppColors.reportsMuted,
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
                    Icon(
                      Icons.trending_up_rounded,
                      color: card.deltaIsPositive == false
                          ? const Color(0xFFC65B4A)
                          : AppColors.reportsGreen,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      card.deltaIsPositive == false
                          ? '${card.delta} down from yesterday'
                          : '${card.delta} up from yesterday',
                      style: TextStyle(
                        color: card.deltaIsPositive == false
                            ? const Color(0xFFC65B4A)
                            : AppColors.reportsGreen,
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
