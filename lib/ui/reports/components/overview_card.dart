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

class OverviewCard extends StatelessWidget {
  const OverviewCard({super.key, required this.card, required this.onTap});

  final OverviewCardData card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.reportsBorder),
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
                          color: AppColors.reportsMuted,
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
                    color: AppColors.reportsInk,
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
                      Icon(
                        card.deltaIsPositive == false
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: card.deltaIsPositive == false
                            ? const Color(0xFFC65B4A)
                            : AppColors.reportsGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        card.delta!,
                        style: TextStyle(
                          color: card.deltaIsPositive == false
                              ? const Color(0xFFC65B4A)
                              : AppColors.reportsGreen,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          card.footer,
                          style: const TextStyle(
                            color: AppColors.reportsMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    card.footer,
                    style: const TextStyle(
                      color: AppColors.reportsMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
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
